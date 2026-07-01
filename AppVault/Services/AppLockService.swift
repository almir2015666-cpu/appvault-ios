import Foundation
import Combine

@MainActor
final class AppLockService: ObservableObject {
    static let shared = AppLockService()

    @Published var groups: [LockGroup] = []
    @Published var isAuthorized = true

    private let saveKey = "appvault_lock_groups"

    private init() {
        loadGroups()
    }

    func requestAuthorization() async {
        isAuthorized = true
    }

    func addGroup(_ group: LockGroup) {
        groups.append(group)
        saveGroups()
    }

    func updateGroup(_ group: LockGroup) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[idx] = group
        saveGroups()
    }

    func deleteGroup(_ group: LockGroup) {
        groups.removeAll { $0.id == group.id }
        KeychainService.shared.deletePin(forGroupId: group.id)
        saveGroups()
    }

    func toggleGroup(_ group: LockGroup) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[idx].isActive.toggle()
        saveGroups()
    }

    func temporarilyUnlock(groupId: UUID, duration: TimeInterval = 300) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[idx].lockedUntil = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self, let idx = self.groups.firstIndex(where: { $0.id == groupId }) else { return }
            self.groups[idx].lockedUntil = Date()
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
