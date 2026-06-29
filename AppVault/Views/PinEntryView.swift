import SwiftUI

struct PinEntryView: View {
    let group: LockGroup
    var onSuccess: () -> Void
    var onCancel: () -> Void

    @EnvironmentObject var lockService: AppLockService
    @EnvironmentObject var authService: AuthService
    @State private var pin = ""
    @State private var errorMessage = ""
    @State private var shake = false
    @State private var isLocked = false

    private var digitCount: Int {
        switch group.lockType {
        case .pin6: return 6
        default: return 4
        }
    }

    var body: some View {
        ZStack {
            Color.vaultBackground.ignoresSafeArea()

            VStack(spacing: 40) {
                header
                if group.isLocked {
                    lockedView
                } else {
                    unlockSection
                }
            }
            .padding(.horizontal, 32)
        }
        .task {
            if group.isBiometricEnabled && authService.isBiometricAvailable {
                await tryBiometric()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(group.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: group.iconName)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(group.color)
            }

            VStack(spacing: 6) {
                Text(group.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("Digite o PIN para desbloquear")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.top, 48)
    }

    private var unlockSection: some View {
        VStack(spacing: 28) {
            if !errorMessage.isEmpty {
                errorView
            }

            if group.lockType == .biometric {
                biometricButton
            } else {
                PinPadView(digitCount: digitCount, pin: $pin, onComplete: verifyPin)

                if group.isBiometricEnabled {
                    biometricButton
                }
            }

            Button("Cancelar", action: onCancel)
                .font(.system(size: 15))
                .foregroundColor(.gray)
        }
    }

    private var errorView: some View {
        VStack(spacing: 4) {
            Text(errorMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.vaultRed)

            if group.failedAttempts > 0 {
                Text("\(group.maxAttempts - group.failedAttempts) tentativa\(group.maxAttempts - group.failedAttempts == 1 ? "" : "s") restante\(group.maxAttempts - group.failedAttempts == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.vaultRed.opacity(0.1))
        .cornerRadius(10)
        .offset(x: shake ? -8 : 0)
        .animation(.spring(response: 0.1).repeatCount(5, autoreverses: true), value: shake)
    }

    private var biometricButton: some View {
        Button {
            Task { await tryBiometric() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: authService.biometricType.icon)
                    .font(.system(size: 20))
                Text("Usar \(authService.biometricType.displayName)")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.vaultCard)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private var lockedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.trianglebadge.exclamationmark.fill")
                .font(.system(size: 48))
                .foregroundColor(Color.vaultRed)

            Text("Muitas tentativas incorretas")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            if let until = group.lockedUntil {
                CountdownView(until: until) {
                    lockService.resetFailedAttempts(groupId: group.id)
                }
            }

            Button("Cancelar", action: onCancel)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
    }

    private func verifyPin(_ entered: String) {
        if KeychainService.shared.verifyPin(entered, forGroupId: group.id) {
            lockService.resetFailedAttempts(groupId: group.id)
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
            onSuccess()
        } else {
            lockService.recordFailedAttempt(groupId: group.id)
            errorMessage = "PIN incorreto"
            shake = true
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                shake = false
                pin = ""
            }
        }
    }

    private func tryBiometric() async {
        let success = await authService.authenticate(reason: "Desbloquear \(group.name)")
        if success {
            lockService.resetFailedAttempts(groupId: group.id)
            onSuccess()
        }
    }
}

struct CountdownView: View {
    let until: Date
    let onExpire: () -> Void
    @State private var remaining: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text("Tente novamente em \(Int(remaining))s")
            .font(.system(size: 15))
            .foregroundColor(.gray)
            .onReceive(timer) { _ in
                remaining = max(0, until.timeIntervalSinceNow)
                if remaining == 0 { onExpire() }
            }
            .onAppear { remaining = max(0, until.timeIntervalSinceNow) }
    }
}
