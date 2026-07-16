import SwiftUI

struct AppLockScreen: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject private var gate = AppLockGuard.shared

    @State private var pin = ""
    @State private var showError = false
    @State private var shake = false

    var body: some View {
        ZStack {
            Color.vaultBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    Circle().fill(Color.vaultAccent.opacity(0.1)).frame(width: 90, height: 90)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.vaultAccent)
                }
                .padding(.bottom, 20)

                Text("AppVault bloqueado")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Digite sua senha para entrar")
                    .font(.system(size: 14))
                    .foregroundColor(.vaultMuted)
                    .padding(.bottom, 32)

                if showError {
                    Text("Senha incorreta")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.vaultRed)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.vaultRed.opacity(0.08)))
                        .offset(x: shake ? -6 : 0)
                        .animation(.spring(response: 0.08).repeatCount(6, autoreverses: true), value: shake)
                        .padding(.bottom, 16)
                }

                PinPadView(digitCount: 4, pin: $pin, onComplete: verify)

                if authService.isBiometricAvailable {
                    Button { Task { await tryBio() } } label: {
                        HStack(spacing: 8) {
                            Image(systemName: authService.biometricType.icon).font(.system(size: 18))
                            Text(authService.biometricType.displayName).font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.vaultAccentLight)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 24)
                }

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .task {
            if authService.isBiometricAvailable { await tryBio() }
        }
    }

    private func verify(_ entered: String) {
        if gate.verify(entered) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            gate.unlock()
        } else {
            showError = true
            shake = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = false; pin = "" }
        }
    }

    private func tryBio() async {
        if await authService.authenticate(reason: "Desbloquear o AppVault") {
            gate.unlock()
        }
    }
}
