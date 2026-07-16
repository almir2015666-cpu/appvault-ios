import Foundation
import Combine
import FamilyControls
import ManagedSettings
import DeviceActivity
import UserNotifications

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
    private let activityCenter = DeviceActivityCenter()

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
        let now = Date()
        // Bloqueia grupos ativos que não estejam em janela de liberação temporária.
        let shieldingGroups = groups.filter { group in
            group.isActive && (group.unlockedUntil == nil || group.unlockedUntil! <= now)
        }
        let allTokens = shieldingGroups.reduce(into: Set<ApplicationToken>()) { result, group in
            result.formUnion(group.selection.applicationTokens)
        }
        store.shield.applications = allTokens.isEmpty ? nil : allTokens
    }

    /// Re-bloqueia grupos cuja liberação temporária já expirou. Chamado quando
    /// o app volta ao primeiro plano.
    func reapplyExpiredShields() {
        let now = Date()
        var changed = false
        for i in groups.indices where groups[i].unlockedUntil != nil {
            if groups[i].unlockedUntil! <= now {
                groups[i].unlockedUntil = nil
                changed = true
            }
        }
        if changed { saveGroups() }
        applyShields()
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
        let until = Date().addingTimeInterval(groups[idx].unlockDuration)
        groups[idx].unlockedUntil = until
        let name = groups[idx].name
        saveGroups()
        applyShields()
        // Guarda os tokens pro monitor re-aplicar em background e agenda o fim.
        SharedShieldStore.saveTokens(groups[idx].selection.applicationTokens, groupId: groupId.uuidString)
        scheduleBackgroundRelock(groupId: groupId, until: until)
        scheduleRelockNotification(groupId: groupId, name: name, at: until)
        // Enquanto o app seguir vivo, re-bloqueia no horário exato.
        DispatchQueue.main.asyncAfter(deadline: .now() + groups[idx].unlockDuration + 1) { [weak self] in
            self?.reapplyExpiredShields()
        }
    }

    // Re-bloqueio automático em background via DeviceActivityMonitor.
    // O iOS exige janela de no mínimo 15 min; abaixo disso, o re-bloqueio
    // fica por conta do primeiro plano + notificação.
    private func scheduleBackgroundRelock(groupId: UUID, until: Date) {
        guard until.timeIntervalSinceNow >= 15 * 60 else { return }
        let cal = Calendar.current
        let start = cal.dateComponents([.hour, .minute, .second], from: Date())
        let end = cal.dateComponents([.hour, .minute, .second], from: until)
        let schedule = DeviceActivitySchedule(intervalStart: start, intervalEnd: end, repeats: false)
        try? activityCenter.startMonitoring(DeviceActivityName(groupId.uuidString), during: schedule)
    }

    private func scheduleRelockNotification(groupId: UUID, name: String, at date: Date) {
        let center = UNUserNotificationCenter.current()
        let id = "relock.\(groupId.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "AppVault"
        content.body = "Tempo esgotado — \(name) bloqueado novamente."
        content.sound = .default

        let interval = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    // Duração do bloqueio de tentativas após esgotar os erros (configurável).
    var lockoutDuration: TimeInterval {
        let mins = UserDefaults.standard.integer(forKey: "lockoutMinutes")
        return TimeInterval((mins == 0 ? 15 : mins) * 60)
    }

    func recordFailedAttempt(groupId: UUID) {
        guard let idx = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[idx].failedAttempts += 1
        if groups[idx].failedAttempts >= groups[idx].maxAttempts {
            groups[idx].lockedUntil = Date().addingTimeInterval(lockoutDuration)
        }
        // Errou a senha -> re-bloqueia tudo na hora.
        relockAllGroups()
        saveGroups()
    }

    /// Cancela todas as liberações temporárias e re-aplica o bloqueio de tudo.
    func relockAllGroups() {
        for i in groups.indices { groups[i].unlockedUntil = nil }
        activityCenter.stopMonitoring()
        saveGroups()
        applyShields()
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
