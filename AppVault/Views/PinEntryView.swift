import SwiftUI

struct PinEntryView: View {
    let group: LockGroup
    var onSuccess: () -> Void
    var onCancel: () -> Void

    @EnvironmentObject var lockService: AppLockService
    @EnvironmentObject var authService: AuthService
    @State private var pin = ""
    @State private var errorMsg = ""
    @State private var shake = false

    var body: some View {
        ZStack {
            Color.vaultBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                // Group icon
                ZStack {
                    Circle()
                        .fill(Color(hex: group.colorHex).opacity(0.12))
                        .frame(width: 90, height: 90)
                    Circle()
                        .fill(Color(hex: group.colorHex).opacity(0.06))
                        .frame(width: 120, height: 120)
                    Image(systemName: group.iconName)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(Color(hex: group.colorHex))
                }
                .padding(.bottom, 20)

                Text(group.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Digite a senha para desbloquear")
                    .font(.system(size: 14))
                    .foregroundColor(.vaultMuted)
                    .padding(.bottom, 32)

                if group.isLocked {
                    lockedView
                } else {
                    unlockContent
                }

                Spacer()

                Button("Cancelar", action: onCancel)
                    .font(.system(size: 14))
                    .foregroundColor(.vaultMuted)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 32)
        }
        .task {
            if group.isBiometricEnabled && authService.isBiometricAvailable { await tryBio() }
        }
    }

    private var unlockContent: some View {
        VStack(spacing: 28) {
            if !errorMsg.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill").foregroundColor(.vaultRed)
                    Text(errorMsg).font(.system(size: 13, weight: .medium)).foregroundColor(.vaultRed)
                    if group.failedAttempts > 0 {
                        Text("· \(group.maxAttempts - group.failedAttempts) restante\(group.maxAttempts - group.failedAttempts == 1 ? "" : "s")")
                            .font(.system(size: 12)).foregroundColor(.vaultMuted)
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.vaultRed.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.vaultRed.opacity(0.2), lineWidth: 1)))
                .offset(x: shake ? -6 : 0)
                .animation(.spring(response: 0.08).repeatCount(6, autoreverses: true), value: shake)
            }

            PinPadView(digitCount: 4, pin: $pin, onComplete: verify)

            if group.isBiometricEnabled && authService.isBiometricAvailable {
                Button { Task { await tryBio() } } label: {
                    HStack(spacing: 8) {
                        Image(systemName: authService.biometricType.icon).font(.system(size: 18))
                        Text(authService.biometricType.displayName).font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.vaultAccentLight)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var lockedView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.vaultRed.opacity(0.1)).frame(width: 72, height: 72)
                Image(systemName: "lock.trianglebadge.exclamationmark.fill")
                    .font(.system(size: 32)).foregroundColor(.vaultRed)
            }
            Text("Muitas tentativas").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            if let until = group.lockedUntil {
                CountdownView(until: until) { lockService.resetFailedAttempts(groupId: group.id) }
            }
        }
    }

    private func verify(_ entered: String) {
        if KeychainService.shared.verifyPin(entered, forGroupId: group.id) {
            lockService.resetFailedAttempts(groupId: group.id)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSuccess()
        } else {
            lockService.recordFailedAttempt(groupId: group.id)
            errorMsg = "Senha incorreta"
            shake = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = false; pin = "" }
        }
    }

    private func tryBio() async {
        if await authService.authenticate(reason: "Desbloquear \(group.name)") {
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
        HStack(spacing: 5) {
            Image(systemName: "clock").font(.system(size: 12)).foregroundColor(.vaultMuted)
            Text("Tente novamente em \(Int(remaining))s").font(.system(size: 13)).foregroundColor(.vaultMuted)
        }
        .onReceive(timer) { _ in remaining = max(0, until.timeIntervalSinceNow); if remaining == 0 { onExpire() } }
        .onAppear { remaining = max(0, until.timeIntervalSinceNow) }
    }
}
