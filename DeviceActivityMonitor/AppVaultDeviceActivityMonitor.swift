import DeviceActivity
import ManagedSettings
import FamilyControls

// Roda em background quando a janela de liberação temporária termina,
// re-aplicando o bloqueio sem o app precisar estar aberto.
final class AppVaultDeviceActivityMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // O nome da atividade é o id do grupo que foi liberado.
        let tokens = SharedShieldStore.loadTokens(groupId: activity.rawValue)
        guard !tokens.isEmpty else { return }
        var current = store.shield.applications ?? Set<ApplicationToken>()
        current.formUnion(tokens)
        store.shield.applications = current
        SharedShieldStore.clearTokens(groupId: activity.rawValue)
    }
}
