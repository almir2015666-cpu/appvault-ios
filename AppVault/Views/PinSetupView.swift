import SwiftUI

struct PinSetupView: View {
    let groupName: String
    let lockType: LockGroup.LockType
    var onComplete: (String) -> Void
    var onBack: () -> Void

    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var confirming = false
    @State private var errorMsg = ""
    @State private var shake = false

    var body: some View {
        ZStack {
            Color.vaultBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                // Icon
                ZStack {
                    Circle().fill(Color.vaultAccent.opacity(0.1)).frame(width: 80, height: 80)
                    Image(systemName: confirming ? "lock.rotation" : "lock.open.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(LinearGradient(colors: [.vaultAccentLight, .vaultPurple],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .animation(.spring(response: 0.35), value: confirming)
                .padding(.bottom, 24)

                // Title
                VStack(spacing: 8) {
                    Text(confirming ? "Confirmar senha" : "Criar senha")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(confirming
                         ? "Digite novamente para confirmar"
                         : "Senha para \"\(groupName)\"")
                        .font(.system(size: 14))
                        .foregroundColor(.vaultMuted)
                }
                .padding(.bottom, 36)

                // Error
                if !errorMsg.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.vaultRed)
                        Text(errorMsg).font(.system(size: 13, weight: .medium)).foregroundColor(.vaultRed)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.vaultRed.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.vaultRed.opacity(0.2), lineWidth: 1)))
                    .offset(x: shake ? -6 : 0)
                    .animation(.spring(response: 0.08).repeatCount(6, autoreverses: true), value: shake)
                    .padding(.bottom, 16)
                }

                PinPadView(digitCount: 4, pin: confirming ? $confirmPin : $pin, onComplete: handleComplete)

                Spacer()

                Button(action: handleBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                        Text(confirming ? "Redefinir" : "Voltar")
                    }
                    .font(.system(size: 14)).foregroundColor(.vaultMuted)
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
        }
    }

    private func handleComplete(_ entered: String) {
        if !confirming {
            confirming = true
        } else if entered == pin {
            onComplete(pin)
        } else {
            errorMsg = "Senhas não coincidem"
            shake = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                shake = false; confirmPin = ""; errorMsg = ""
            }
        }
    }

    private func handleBack() {
        if confirming { confirming = false; confirmPin = ""; errorMsg = "" }
        else { onBack() }
    }
}
