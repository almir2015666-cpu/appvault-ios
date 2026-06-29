import ManagedSettings
import UIKit

// Ao tocar em "Inserir Senha", abre o AppVault para autenticação
final class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction, for application: Application, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // Abre o app principal via URL scheme para mostrar tela de PIN
            if let url = URL(string: "appvault://unlock") {
                DispatchQueue.main.async {
                    self.open(url)
                }
            }
            completionHandler(.defer)

        case .secondaryButtonPressed:
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    private func open(_ url: URL) {
        var responder: UIResponder? = UIApplication.shared
        while let current = responder {
            if let application = current as? UIApplication {
                application.open(url)
                return
            }
            responder = current.next
        }
    }
}
