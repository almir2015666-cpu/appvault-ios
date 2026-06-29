import SwiftUI

struct LockGroupCard: View {
    let group: LockGroup
    var onToggle: () -> Void
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                iconView
                infoView
                Spacer()
                Toggle("", isOn: Binding(
                    get: { group.isActive },
                    set: { _ in onToggle() }
                ))
                .tint(Color(hex: group.colorHex))
                .labelsHidden()
            }
            .padding(16)
            .background(Color.vaultCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(group.isActive ? Color(hex: group.colorHex).opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(Color(hex: group.colorHex).opacity(0.18))
                .frame(width: 52, height: 52)
            Image(systemName: group.iconName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(hex: group.colorHex))
        }
    }

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(group.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            HStack(spacing: 6) {
                Image(systemName: group.isActive ? "lock.fill" : "lock.open")
                    .font(.system(size: 11))
                    .foregroundColor(group.isActive ? Color(hex: group.colorHex) : .gray)
                Text(group.isActive ? "\(group.appCount) app\(group.appCount == 1 ? "" : "s") bloqueado\(group.appCount == 1 ? "" : "s")" : "Desativado")
                    .font(.system(size: 13))
                    .foregroundColor(group.isActive ? .white.opacity(0.7) : .gray)
            }
        }
    }
}
