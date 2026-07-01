import SwiftUI

struct LockGroupCard: View {
    let group: LockGroup
    var onToggle: () -> Void
    var onTap: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Color bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: group.colorHex))
                .frame(width: 4, height: 52)

            // Color dot + lock icon
            ZStack {
                Circle()
                    .fill(Color(hex: group.colorHex).opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: group.isActive ? "lock.fill" : "lock.open")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: group.colorHex))
            }

            // Name + count
            VStack(alignment: .leading, spacing: 5) {
                Text(group.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(group.isActive
                     ? "\(group.appCount) app\(group.appCount == 1 ? "" : "s") protegido\(group.appCount == 1 ? "" : "s")"
                     : "Desativado")
                    .font(.system(size: 12))
                    .foregroundColor(group.isActive ? Color(hex: group.colorHex).opacity(0.85) : .vaultMuted)
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
                        .stroke(group.isActive
                                ? Color(hex: group.colorHex).opacity(0.25)
                                : Color.vaultCardBorder, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}
