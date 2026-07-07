import Foundation
import Combine
import FamilyControls
import ManagedSettings

@MainActor
final class AppLockService: ObservableObject {
    static let shared = AppLockService()

    @Published var groups: [LockGroup] = []
    @Published var isAuthorized = false
    @Published var isAuthDenied = false
    @Published var debugInfo = "aguardando..."
    @Published var showingUnlockFromShield = false

    private let saveKey = "appvault_lock_groups_v2"
    private let store = ManagedSettingsStore()

    private init() {
        loadGroups()
        let status = AuthorizationCenter.shared.authorizationStatus
        isAuthorized = status == .approved
        debugInfo = "init: \(status)"
    }

    func requestAuthorization() async {
        let currentStatus = AuthorizationCenter.shared.authorizationStatus
        guard currentStatus != .approved else {
            isAuthorized = true
            isAuthDenied = false
            debugInfo = "AUTORIZADO ✓"
            applyShields()
            return
        }

        debugInfo = "status: \(currentStatus) | aguardando..."
        try? await Task.sleep(nanoseconds: 800_000_000)

        for attempt in 1...3 {
            debugInfo = "tentativa \(attempt)/3..."
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                isAuthorized = true
                isAuthDenied = false
                debugInfo = "AUTORIZADO ✓"
                applyShields()
                return
            } catch {
                let nsErr = error as NSError
                if attempt < 3 {
                    debugInfo = "tentativa \(attempt) falhou (\(nsErr.code)) — tentando de novo..."
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                } else {
                    isAuthorized = false
                    isAuthDenied = true
                    debugInfo = "[\(nsErr.domain) \(nsErr.code)] \(nsErr.localizedDescription)"
                }
            }
        }
    }

    func applyShields() {
        let activeGroups = groups.filter { $0.isActive }
        let allTokens = activeGroups.reduce(into: Set<ApplicationToken>()) { result, group in
            result.formUnion(group.selection.applicationTokens)
        }
        store.shield.applications = allTokens.isEmpty ? nil : allTokens
    }

    func addGroup(_ group: LockGroup) {
        groups.append(group)
        saveGroups()
        applyShields()
    }

    func updateGroup(_ group: LockGroup) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[idx] = group
        saveGroups()
        applyShields()
    }

    func deleteGroup(_ group: LockGroup) {
        groups.removeAll { $0.id == group.id }
        KeychainService.shared.deletePin(forGroupId: group.id)
        saveGroups()
        applyShields()
    }

    func toggleGroup(_ group: LockGroup) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[idx].isActive.toggle()
        saveGroups()
        applyShields()
    }

    func temporarilyUnlock(groupId: UUID) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        let duration = groups[idx].unlockDuration
        groups[idx].isActive = false
        saveGroups()
        applyShields()
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self, let idx = self.groups.firstIndex(where: { $0.id == groupId }) else { return }
            self.groups[idx].isActive = true
            self.saveGroups()
            self.applyShields()
        }
    }

    func recordFailedAttempt(groupId: UUID) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[idx].failedAttempts += 1
        if groups[idx].failedAttempts >= groups[idx].maxAttempts {
            groups[idx].lockedUntil = Date().addingTimeInterval(300)
        }
        saveGroups()
    }

    func resetFailedAttempts(groupId: UUID) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[idx].failedAttempts = 0
        groups[idx].lockedUntil = nil
        saveGroups()
    }

    private func saveGroups() {
        guard let data = try? JSONEncoder().encode(groups) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }

    private func loadGroups() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([LockGroup].self, from: data)
        else { return }
        groups = decoded
    }
}
