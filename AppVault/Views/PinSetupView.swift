import SwiftUI

struct PinSetupView: View {
    let groupName: String
    let lockType: LockGroup.LockType
    var onComplete: (String) -> Void
    var onBack: () -> Void

    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var isConfirming = false
    @State private var errorMessage = ""
    @State private var shake = false

    private var digitCount: Int {
        switch lockType {
        case .pin6: return 6
        default: return 4
        }
    }

    var body: some View {
        ZStack {
            Color.vaultBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Step indicator
                HStack(spacing: 6) {
                    stepDot(active: true, done: isConfirming)
                    Rectangle().fill(isConfirming ? Color.vaultAccent : Color.vaultCard).frame(height: 2).cornerRadius(1)
                    stepDot(active: isConfirming, done: false)
                }
                .padding(.horizontal, 80)
                .padding(.top, 32)

                VStack(spacing: 8) {
                    Text(isConfirming ? "Confirmar PIN" : "Criar PIN")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(isConfirming
                         ? "Digite o PIN novamente para confirmar"
                         : "Escolha um PIN para \"\(groupName)\"")
                        .font(.system(size: 14))
                        .foregroundColor(.vaultMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 28)
                .padding(.bottom, 36)

                if lockType == .biometric {
                    biometricView
                } else {
                    pinContent
                }

                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }

    private func stepDot(active: Bool, done: Bool) -> some View {
        ZStack {
            Circle()
                .fill(active || done ? Color.vaultAccent : Color.vaultCard)
                .frame(width: 24, height: 24)
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Circle()
                    .fill(active ? .white : Color.vaultMuted)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var pinContent: some View {
        VStack(spacing: 32) {
            if !errorMessage.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.vaultRed)
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.vaultRed)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.vaultRed.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.vaultRed.opacity(0.18), lineWidth: 1))
                )
                .offset(x: shake ? -6 : 0)
                .animation(.spring(response: 0.08).repeatCount(6, autoreverses: true), value: shake)
            }

            PinPadView(
                digitCount: digitCount,
                pin: isConfirming ? $confirmPin : $pin,
                onComplete: handlePinComplete
            )

            Button(action: handleBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text(isConfirming ? "Redefinir PIN" : "Voltar")
                }
                .font(.system(size: 14))
                .foregroundColor(.vaultMuted)
            }
        }
    }

    private var biometricView: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.vaultAccent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "faceid")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(colors: [.vaultAccent, .vaultPurple],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            Text("Bloqueio por biometria")
                .font(.system(size: 16))
                .foregroundColor(.vaultMuted)

            Button("Confirmar") { onComplete("") }
                .buttonStyle(PrimaryButtonStyle())

            Button("Voltar", action: onBack)
                .font(.system(size: 14))
                .foregroundColor(.vaultMuted)
        }
    }

    private func handleBack() {
        if isConfirming {
            isConfirming = false
            confirmPin = ""
            errorMessage = ""
        } else {
            onBack()
        }
    }

    private func handlePinComplete(_ entered: String) {
        if !isConfirming {
            isConfirming = true
        } else if entered == pin {
            onComplete(pin)
        } else {
            errorMessage = "Os PINs não coincidem"
            shake = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                shake = false
                confirmPin = ""
                errorMessage = ""
            }
        }
    }
}
