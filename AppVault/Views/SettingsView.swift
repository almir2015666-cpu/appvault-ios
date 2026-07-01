import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var lockService: AppLockService
    @EnvironmentObject var authService: AuthService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("defaultUnlockDuration") private var unlockDuration = 5.0
    @AppStorage("showFailedAttempts") private var showFailedAttempts = true
    @State private var showDeleteAllAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vaultBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        appHeader

                        settingsGroup(title: "SEGURANÇA") {
                            settingsRow(icon: "faceid", iconColor: .vaultAccent, title: authService.biometricType.displayName) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(authService.isBiometricAvailable ? Color.vaultGreen : Color.vaultMuted)
                                        .frame(width: 7, height: 7)
                                    Text(authService.isBiometricAvailable ? "Disponível" : "Indisponível")
                                        .font(.system(size: 12))
                                        .foregroundColor(authService.isBiometricAvailable ? .vaultGreen : .vaultMuted)
                                }
                            }
                            Divider().background(Color.vaultCardBorder).padding(.leading, 56)
                            settingsRow(icon: "exclamationmark.triangle.fill", iconColor: .vaultOrange, title: "Mostrar Tentativas") {
                                Toggle("", isOn: $showFailedAttempts).tint(.vaultAccent).labelsHidden()
                            }
                        }

                        settingsGroup(title: "COMPORTAMENTO") {
                            settingsRow(icon: "timer", iconColor: .vaultTeal, title: "Desbloqueio Temporário") {
                                Picker("", selection: $unlockDuration) {
                                    Text("1 min").tag(1.0)
                                    Text("5 min").tag(5.0)
                                    Text("15 min").tag(15.0)
                                    Text("30 min").tag(30.0)
                                }
                                .tint(.vaultMuted)
                            }
                        }

                        settingsGroup(title: "SOBRE") {
                            settingsRow(icon: "info.circle.fill", iconColor: .vaultAccentLight, title: "Versão") {
                                Text("1.0.0")
                                    .font(.system(size: 13))
                                    .foregroundColor(.vaultMuted)
                            }
                            Divider().background(Color.vaultCardBorder).padding(.leading, 56)
                            settingsRow(icon: "lock.shield.fill", iconColor: .vaultAccent, title: "AppVault") {
                                Text("by AppVault Inc.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.vaultMuted)
                            }
                        }

                        settingsGroup(title: "ZONA DE RISCO") {
                            Button {
                                hasCompletedOnboarding = false
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 9)
                                            .fill(Color.vaultOrange.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.vaultOrange)
                                    }
                                    Text("Ver Tutorial Novamente")
                                        .font(.system(size: 15))
                                        .foregroundColor(.vaultOrange)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)

                            Divider().background(Color.vaultCardBorder).padding(.leading, 56)

                            Button { showDeleteAllAlert = true } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 9)
                                            .fill(Color.vaultRed.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.vaultRed)
                                    }
                                    Text("Remover Todos os Grupos")
                                        .font(.system(size: 15))
                                        .foregroundColor(.vaultRed)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Remover Tudo?", isPresented: $showDeleteAllAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Remover", role: .destructive) {
                lockService.groups.forEach { lockService.deleteGroup($0) }
            }
        } message: {
            Text("Todos os grupos e senhas serão apagados permanentemente.")
        }
    }

    private var appHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                LinearGradient(colors: [.vaultAccent, .vaultPurple],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: 60, height: 60)
                    .cornerRadius(16)
                    .shadow(color: .vaultAccent.opacity(0.35), radius: 12, x: 0, y: 6)
                Image(systemName: "shield.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("AppVault")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text("\(lockService.groups.count) grupo\(lockService.groups.count == 1 ? "" : "s") configurado\(lockService.groups.count == 1 ? "" : "s")")
                    .font(.system(size: 13))
                    .foregroundColor(.vaultMuted)
            }

            Spacer()
        }
        .padding(.top, 8)
    }

    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.vaultMuted)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.vaultCard)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.vaultCardBorder, lineWidth: 1))
            )
        }
    }

    private func settingsRow<Trailing: View>(icon: String, iconColor: Color, title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.white)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
