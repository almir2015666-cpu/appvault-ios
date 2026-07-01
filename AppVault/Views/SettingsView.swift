import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var lockService: AppLockService
    @EnvironmentObject var authService: AuthService
    @AppStorage("hasCompletedOnboarding") private var done = true
    @AppStorage("defaultUnlockDuration") private var duration = 5.0
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vaultBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        appCard
                        group("SEGURANÇA") {
                            row(icon: "faceid", color: .vaultAccent, title: authService.biometricType.displayName) {
                                HStack(spacing: 6) {
                                    Circle().fill(authService.isBiometricAvailable ? Color.vaultGreen : Color.vaultMuted).frame(width: 6, height: 6)
                                    Text(authService.isBiometricAvailable ? "Disponível" : "Indisponível")
                                        .font(.system(size: 12)).foregroundColor(authService.isBiometricAvailable ? .vaultGreen : .vaultMuted)
                                }
                            }
                        }
                        group("COMPORTAMENTO") {
                            row(icon: "timer", color: .vaultTeal, title: "Desbloqueio temporário") {
                                Picker("", selection: $duration) {
                                    Text("1 min").tag(1.0)
                                    Text("5 min").tag(5.0)
                                    Text("15 min").tag(15.0)
                                    Text("30 min").tag(30.0)
                                }.tint(.vaultMuted)
                            }
                        }
                        group("SOBRE") {
                            row(icon: "info.circle.fill", color: .vaultAccentLight, title: "Versão") {
                                Text("1.0.0").font(.system(size: 13)).foregroundColor(.vaultMuted)
                            }
                        }
                        group("ZONA DE RISCO") {
                            Button { done = false } label: {
                                dangerRow(icon: "arrow.counterclockwise", color: .vaultOrange, title: "Ver tutorial novamente")
                            }.buttonStyle(.plain)
                            separator
                            Button { confirmDelete = true } label: {
                                dangerRow(icon: "trash.fill", color: .vaultRed, title: "Apagar todos os grupos")
                            }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 40)
                }
            }
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Apagar tudo?", isPresented: $confirmDelete) {
            Button("Cancelar", role: .cancel) {}
            Button("Apagar", role: .destructive) { lockService.groups.forEach { lockService.deleteGroup($0) } }
        } message: {
            Text("Todos os grupos e senhas serão removidos permanentemente.")
        }
    }

    private var appCard: some View {
        HStack(spacing: 16) {
            ZStack {
                LinearGradient(colors: [.vaultAccent,.vaultPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: 58, height: 58).cornerRadius(15)
                    .shadow(color: .vaultAccent.opacity(0.35), radius: 10, x: 0, y: 5)
                Image(systemName: "lock.shield.fill").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("AppVault").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                Text("\(lockService.groups.count) grupo\(lockService.groups.count == 1 ? "" : "s") configurado\(lockService.groups.count == 1 ? "" : "s")")
                    .font(.system(size: 12)).foregroundColor(.vaultMuted)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 11, weight: .bold)).foregroundColor(.vaultMuted).tracking(0.8)
                .padding(.leading, 4)
            VStack(spacing: 0) { content() }
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.vaultCard)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.vaultCardBorder, lineWidth: 1)))
        }
    }

    private func row<T: View>(icon: String, color: Color, title: String, @ViewBuilder trailing: () -> T) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundColor(color)
            }
            Text(title).font(.system(size: 15)).foregroundColor(.white)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private func dangerRow(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.1)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundColor(color)
            }
            Text(title).font(.system(size: 15)).foregroundColor(color)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private var separator: some View {
        Rectangle().fill(Color.vaultCardBorder).frame(height: 1).padding(.leading, 56)
    }
}
