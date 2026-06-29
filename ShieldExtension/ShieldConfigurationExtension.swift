import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private func makeShield() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.97),
            icon: UIImage(systemName: "lock.shield.fill")?
                .withTintColor(UIColor(red: 0.26, green: 0.38, blue: 0.93, alpha: 1), renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(text: "App Bloqueado", color: .white),
            subtitle: ShieldConfiguration.Label(
                text: "Protegido pelo AppVault",
                color: UIColor.white.withAlphaComponent(0.6)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Inserir Senha", color: .white),
            primaryButtonBackgroundColor: UIColor(red: 0.26, green: 0.38, blue: 0.93, alpha: 1),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Cancelar",
                color: UIColor.white.withAlphaComponent(0.5)
            )
        )
    }

    override func configuration(shielding application: ApplicationToken) -> ShieldConfiguration {
        makeShield()
    }

    override func configuration(shielding webDomain: WebDomainToken) -> ShieldConfiguration {
        makeShield()
    }

    override func configuration(shielding category: ActivityCategoryToken) -> ShieldConfiguration {
        makeShield()
    }
}
