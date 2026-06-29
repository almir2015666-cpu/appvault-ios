import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var lockService: AppLockService
    @EnvironmentObject var authService: AuthService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("defaultUnlockDuration") private var unlockDuration = 5.0
    @AppStorage("showFailedAttempts") private var showFailedAttempts = true
    @State private var showDeleteAllAlert = false
    @State private var showResetOnboarding = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vaultBackground.ignoresSafeArea()
                List {
                    securitySection
                    behaviourSection
                    aboutSection
                    dangerSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var securitySection: some View {
        Section {
            SettingsRow(icon: "faceid", iconColor: .vaultAccent, title: authService.biometricType.displayName) {
                Toggle("", isOn: .constant(authService.isBiometricAvailable))
                    .disabled(true)
                    .tint(.vaultAccent)
            }

            SettingsRow(icon: "exclamationmark.triangle.fill", iconColor: .vaultPurple, title: "Mostrar Tentativas Incorretas") {
                Toggle("", isOn: $showFailedAttempts)
                    .tint(.vaultPurple)
            }
        } header: {
            sectionHeader("Segurança")
        }
        .listRowBackground(Color.vaultCard)
    }

    private var behaviourSection: some View {
        Section {
            SettingsRow(icon: "timer", iconColor: Color(hex: "#FF6B35"), title: "Duração do Desbloqueio Temporário") {
                Picker("", selection: $unlockDuration) {
                    Text("1 min").tag(1.0)
                    Text("5 min").tag(5.0)
                    Text("15 min").tag(15.0)
                    Text("30 min").tag(30.0)
                }
                .tint(.gray)
            }
        } header: {
            sectionHeader("Comportamento")
        }
        .listRowBackground(Color.vaultCard)
    }

    private var aboutSection: some View {
        Section {
            SettingsRow(icon: "info.circle.fill", iconColor: Color(hex: "#06D6A0"), title: "Versão") {
                Text("1.0.0")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }

            SettingsRow(icon: "lock.shield.fill", iconColor: Color(hex: "#4361EE"), title: "AppVault") {
                Text("by AppVault Inc.")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
        } header: {
            sectionHeader("Sobre")
        }
        .listRowBackground(Color.vaultCard)
    }

    private var dangerSection: some View {
        Section {
            Button {
                showDeleteAllAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(Color.vaultRed)
                        .frame(width: 28)
                    Text("Remover Todos os Grupos")
                        .foregroundColor(Color.vaultRed)
                }
            }

            Button {
                hasCompletedOnboarding = false
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.orange)
                        .frame(width: 28)
                    Text("Ver Tutorial Novamente")
                        .foregroundColor(.orange)
                }
            }
        } header: {
            sectionHeader("Zona de Perigo")
        }
        .listRowBackground(Color.vaultCard)
        .alert("Remover Tudo?", isPresented: $showDeleteAllAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Remover", role: .destructive) {
                lockService.groups.forEach { lockService.deleteGroup($0) }
            }
        } message: {
            Text("Todos os grupos e senhas serão apagados permanentemente.")
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white.opacity(0.4))
            .textCase(.uppercase)
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.white)

            Spacer()

            trailing()
        }
        .padding(.vertical, 2)
    }
}
