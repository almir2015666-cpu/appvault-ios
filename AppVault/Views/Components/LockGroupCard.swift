import SwiftUI

struct LockGroupCard: View {
    let group: LockGroup
    var onToggle: () -> Void
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Colored accent bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: group.colorHex))
                    .frame(width: 4, height: 54)

                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(Color(hex: group.colorHex).opacity(0.13))
                        .frame(width: 50, height: 50)
                    Image(systemName: group.iconName)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(Color(hex: group.colorHex))
                }

                // Text
                VStack(alignment: .leading, spacing: 5) {
                    Text(group.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        Image(systemName: group.isActive ? "lock.fill" : "lock.open")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(group.isActive ? Color(hex: group.colorHex) : .vaultMuted)
                        Text(group.isActive
                             ? "\(group.appCount) app\(group.appCount == 1 ? "" : "s") protegido\(group.appCount == 1 ? "" : "s")"
                             : "Desativado")
                            .font(.system(size: 12))
                            .foregroundColor(group.isActive ? .vaultMuted : Color.vaultMuted.opacity(0.6))
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(get: { group.isActive }, set: { _ in onToggle() }))
                    .tint(Color(hex: group.colorHex))
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.vaultCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                group.isActive
                                    ? Color(hex: group.colorHex).opacity(0.22)
                                    : Color.vaultCardBorder,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
