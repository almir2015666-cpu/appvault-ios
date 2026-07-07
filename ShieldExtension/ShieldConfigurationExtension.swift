import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private func makeShield() -> ShieldConfiguration {
        let accent = UIColor(red: 0.26, green: 0.38, blue: 0.93, alpha: 1)
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: nil,
            icon: UIImage(systemName: "lock.fill")?
                .withTintColor(accent, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(text: "App Bloqueado", color: .label),
            subtitle: ShieldConfiguration.Label(
                text: "Abra o AppVault para desbloquear",
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Fechar", color: .white),
            primaryButtonBackgroundColor: accent
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeShield()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeShield()
    }
}
