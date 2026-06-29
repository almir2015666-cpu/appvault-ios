import Foundation
import FamilyControls
import ManagedSettings
import Combine

@MainActor
final class AppLockService: ObservableObject {
    static let shared = AppLockService()

    @Published var groups: [LockGroup] = []
    @Published var isAuthorized = false
    @Published var authorizationError: Error?

    private let store = ManagedSettingsStore()
    private let saveKey = "appvault_lock_groups"

    private init() {
        loadGroups()
        checkAuthorization()
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
            applyAllLocks()
        } catch {
            authorizationError = error
            isAuthorized = false
        }
    }

    private func checkAuthorization() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    // MARK: - Group Management

    func addGroup(_ group: LockGroup) {
        groups.append(group)
        saveGroups()
        if group.isActive { applyLock(for: group) }
    }

    func updateGroup(_ group: LockGroup) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }
        removeLock(for: groups[idx])
        groups[idx] = group
        saveGroups()
        if group.isActive { applyLock(for: group) }
    }

    func deleteGroup(_ group: LockGroup) {
        removeLock(for: group)
        groups.removeAll { $0.id == group.id }
        KeychainService.shared.deletePin(forGroupId: group.id)
        saveGroups()
    }

    func toggleGroup(_ group: LockGroup) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[idx].isActive.toggle()
        if groups[idx].isActive {
            applyLock(for: groups[idx])
        } else {
            removeLock(for: groups[idx])
        }
        saveGroups()
    }

    // MARK: - Lock Application

    func applyAllLocks() {
        var allTokens = Set<ApplicationToken>()
        for group in groups where group.isActive {
            allTokens.formUnion(group.selection.applicationTokens)
        }
        store.application.blockedApplications = allTokens
    }

    private func applyLock(for group: LockGroup) {
        applyAllLocks()
    }

    private func removeLock(for group: LockGroup) {
        applyAllLocks()
    }

    func temporarilyUnlock(groupId: UUID, duration: TimeInterval = 300) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[idx].lockedUntil = nil
        applyAllLocksExcluding(groupId: groupId)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.reapplyLock(groupId: groupId)
        }
    }

    private func applyAllLocksExcluding(groupId: UUID) {
        var allTokens = Set<ApplicationToken>()
        for group in groups where group.isActive && group.id != groupId {
            allTokens.formUnion(group.selection.applicationTokens)
        }
        store.application.blockedApplications = allTokens
    }

    private func reapplyLock(groupId: UUID) {
        applyAllLocks()
    }

    // MARK: - Failed Attempts

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

    // MARK: - Persistence

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
