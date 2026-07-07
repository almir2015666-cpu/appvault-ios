import ManagedSettings
import UIKit

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

    private func handleAction(_ action: ShieldAction, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // Abre AppVault para o usuário inserir a senha e desbloquear o grupo
            if let url = URL(string: "appvault://unlock") {
                UIApplication.shared.open(url, options: [:]) { _ in
                    completionHandler(.defer)
                }
            } else {
                completionHandler(.defer)
            }
        case .secondaryButtonPressed:
            // Cancelar: mantém o bloqueio ativo
            completionHandler(.defer)
        @unknown default:
            completionHandler(.defer)
        }
    }
}
