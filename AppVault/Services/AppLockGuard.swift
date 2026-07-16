import Foundation
import Combine

// Trava o próprio AppVault com senha/Face ID.
@MainActor
final class AppLockGuard: ObservableObject {
    static let shared = AppLockGuard()

    @Published var isLocked: Bool = false

    private let enabledKey = "appLockEnabled"
    private let lockId = UUID(uuidString: "A0000000-0000-0000-0000-0000000000AA")!

    var isEnabled: Bool { UserDefaults.standard.bool(forKey: enabledKey) }
    var hasPin: Bool { KeychainService.shared.hasPin(forGroupId: lockId) }

    private init() {
        // Já abre travado se a proteção estiver ligada.
        isLocked = UserDefaults.standard.bool(forKey: enabledKey) && KeychainService.shared.hasPin(forGroupId: lockId)
    }

    func enable(pin: String) {
        try? KeychainService.shared.savePin(pin, forGroupId: lockId)
        UserDefaults.standard.set(true, forKey: enabledKey)
    }

    func disable() {
        KeychainService.shared.deletePin(forGroupId: lockId)
        UserDefaults.standard.set(false, forKey: enabledKey)
        isLocked = false
    }

    func verify(_ pin: String) -> Bool {
        KeychainService.shared.verifyPin(pin, forGroupId: lockId)
    }

    /// Chamado quando o app vai para segundo plano.
    func lockIfNeeded() {
        if isEnabled && hasPin { isLocked = true }
    }

    func unlock() { isLocked = false }
}
