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

    private var digitCount: Int { group.lockType == .pin6 ? 6 : 4 }

    var body: some View {
        ZStack {
            Color.vaultBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: group.colorHex).opacity(0.12))
                            .frame(width: 88, height: 88)
                        Circle()
                            .fill(Color(hex: group.colorHex).opacity(0.06))
                            .frame(width: 120, height: 120)
                        Image(systemName: group.iconName)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(Color(hex: group.colorHex))
                    }
                    VStack(spacing: 6) {
                        Text(group.name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Digite o PIN para desbloquear")
                            .font(.system(size: 14))
                            .foregroundColor(.vaultMuted)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 40)

                if group.isLocked {
                    lockedView
                } else {
                    unlockSection
                }

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .task {
            if group.isBiometricEnabled && authService.isBiometricAvailable {
                await tryBiometric()
            }
        }
    }

    private var unlockSection: some View {
        VStack(spacing: 32) {
            if !errorMessage.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.vaultRed)
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.vaultRed)
                    if group.failedAttempts > 0 {
                        Text("· \(group.maxAttempts - group.failedAttempts) restante\(group.maxAttempts - group.failedAttempts == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundColor(.vaultMuted)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.vaultRed.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vaultRed.opacity(0.2), lineWidth: 1))
                )
                .offset(x: shake ? -6 : 0)
                .animation(.spring(response: 0.08).repeatCount(6, autoreverses: true), value: shake)
            }

            if group.lockType == .biometric {
                biometricButton
            } else {
                PinPadView(digitCount: digitCount, pin: $pin, onComplete: verifyPin)
                if group.isBiometricEnabled { biometricButton }
            }

            Button("Cancelar", action: onCancel)
                .font(.system(size: 15))
                .foregroundColor(.vaultMuted)
        }
    }

    private var biometricButton: some View {
        Button { Task { await tryBiometric() } } label: {
            HStack(spacing: 10) {
                Image(systemName: authService.biometricType.icon)
                    .font(.system(size: 18))
                Text("Usar \(authService.biometricType.displayName)")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.vaultCard)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vaultAccent.opacity(0.3), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    private var lockedView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(Color.vaultRed.opacity(0.1)).frame(width: 80, height: 80)
                Image(systemName: "lock.trianglebadge.exclamationmark.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.vaultRed)
            }
            Text("Muitas tentativas incorretas")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            if let until = group.lockedUntil {
                CountdownView(until: until) {
                    lockService.resetFailedAttempts(groupId: group.id)
                }
            }

            Button("Cancelar", action: onCancel)
                .font(.system(size: 15))
                .foregroundColor(.vaultMuted)
                .padding(.top, 8)
        }
    }

    private func verifyPin(_ entered: String) {
        if KeychainService.shared.verifyPin(entered, forGroupId: group.id) {
            lockService.resetFailedAttempts(groupId: group.id)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSuccess()
        } else {
            lockService.recordFailedAttempt(groupId: group.id)
            errorMessage = "PIN incorreto"
            shake = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                shake = false; pin = ""
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
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.system(size: 13))
                .foregroundColor(.vaultMuted)
            Text("Tente novamente em \(Int(remaining))s")
                .font(.system(size: 14))
                .foregroundColor(.vaultMuted)
        }
        .onReceive(timer) { _ in
            remaining = max(0, until.timeIntervalSinceNow)
            if remaining == 0 { onExpire() }
        }
        .onAppear { remaining = max(0, until.timeIntervalSinceNow) }
    }
}
