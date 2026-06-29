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
        case .pin4, .biometricWithPin: return 4
        case .pin6: return 6
        default: return 4
        }
    }

    var body: some View {
        ZStack {
            Color.vaultBackground.ignoresSafeArea()

            VStack(spacing: 40) {
                headerSection

                if lockType == .biometric {
                    biometricOnlyView
                } else {
                    pinSection
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(isConfirming ? "Confirmar PIN" : "Criar PIN")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(isConfirming ? "Digite o PIN novamente para confirmar" : "Escolha um PIN para \"\(groupName)\"")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }

    private var pinSection: some View {
        VStack(spacing: 32) {
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.vaultRed)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.vaultRed.opacity(0.1))
                    .cornerRadius(10)
                    .offset(x: shake ? -8 : 0)
                    .animation(.spring(response: 0.1).repeatCount(5, autoreverses: true), value: shake)
            }

            PinPadView(
                digitCount: digitCount,
                pin: isConfirming ? $confirmPin : $pin,
                onComplete: handlePinComplete
            )

            if !isConfirming {
                backButton
            }
        }
    }

    private var biometricOnlyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "faceid")
                .font(.system(size: 64))
                .foregroundStyle(LinearGradient(
                    colors: [Color.vaultAccent, Color.vaultPurple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Bloqueio por biometria ativado")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Button("Concluir") { onComplete("") }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)

            backButton
        }
    }

    private var backButton: some View {
        Button(action: {
            if isConfirming {
                isConfirming = false
                confirmPin = ""
                errorMessage = ""
            } else {
                onBack()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Voltar")
            }
            .font(.system(size: 15))
            .foregroundColor(.gray)
        }
    }

    private func handlePinComplete(_ entered: String) {
        if !isConfirming {
            isConfirming = true
        } else {
            if entered == pin {
                onComplete(pin)
            } else {
                errorMessage = "Os PINs não coincidem. Tente novamente."
                shake = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shake = false
                    confirmPin = ""
                    errorMessage = ""
                }
            }
        }
    }
}
