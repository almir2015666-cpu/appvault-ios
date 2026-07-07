import Foundation
import ManagedSettings
import UserNotifications

final class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    // O iOS não permite que uma extensão de Shield abra o app diretamente.
    // Contorno: dispara uma notificação local; ao tocar nela, o AppVault
    // abre já na tela de senha (ver AppVaultApp / QuickUnlockView).
    private func handleAction(_ action: ShieldAction, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            sendUnlockNotification { completionHandler(.close) }
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    private func sendUnlockNotification(completion: @escaping () -> Void) {
        let content = UNMutableNotificationContent()
        content.title = "AppVault"
        content.body = "Toque para inserir sua senha e desbloquear"
        content.sound = .default
        content.userInfo = ["action": "unlock"]

        let request = UNNotificationRequest(
            identifier: "appvault.unlock.\(UUID().uuidString)",
            content: content,
            trigger: nil // entrega imediata
        )
        UNUserNotificationCenter.current().add(request) { _ in
            completion()
        }
    }
}
