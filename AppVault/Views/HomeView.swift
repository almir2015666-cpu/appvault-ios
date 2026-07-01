import SwiftUI

struct HomeView: View {
    @EnvironmentObject var lockService: AppLockService
    @State private var showAddGroup = false

    private var activeCount: Int { lockService.groups.filter(\.isActive).count }
    private var totalApps: Int { lockService.groups.filter(\.isActive).reduce(0) { $0 + $1.appCount } }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.vaultBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    statsRow
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    groupsSection
                        .padding(.top, 32)
                }
                .padding(.bottom, 110)
            }

            addFAB
                .padding(.trailing, 24)
                .padding(.bottom, 28)
        }
        .sheet(isPresented: $showAddGroup) {
            AddGroupView()
                .environmentObject(lockService)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("AppVault")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.vaultAccentLight, .vaultPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Proteção inteligente de apps")
                    .font(.system(size: 13))
                    .foregroundColor(.vaultMuted)
            }
            Spacer()
            statusBadge
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(activeCount > 0 ? Color.vaultGreen : Color.vaultMuted)
                .frame(width: 7, height: 7)
            Text(activeCount > 0 ? "Ativo" : "Inativo")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(activeCount > 0 ? .vaultGreen : .vaultMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(activeCount > 0 ? Color.vaultGreen.opacity(0.1) : Color.vaultCard)
                .overlay(Capsule().stroke(
                    activeCount > 0 ? Color.vaultGreen.opacity(0.25) : Color.vaultCardBorder,
                    lineWidth: 1
                ))
        )
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 1) {
            statCell(value: "\(activeCount)", label: "Ativos", icon: "shield.fill", color: .vaultAccent)
            divider
            statCell(value: "\(totalApps)", label: "Apps", icon: "apps.iphone", color: .vaultPurple)
            divider
            statCell(value: "\(lockService.groups.count)", label: "Grupos", icon: "folder.fill", color: .vaultTeal)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.vaultCard)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.vaultCardBorder, lineWidth: 1))
        )
    }

    private func statCell(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.vaultMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.vaultCardBorder)
            .frame(width: 1, height: 64)
    }

    // MARK: - Groups

    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Meus Grupos")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                if !lockService.groups.isEmpty {
                    Text("\(lockService.groups.count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.vaultMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.vaultCard))
                }
            }
            .padding(.horizontal, 20)

            if lockService.groups.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(lockService.groups) { group in
                        LockGroupCard(
                            group: group,
                            onToggle: { lockService.toggleGroup(group) },
                            onTap: {}
                        )
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Color.vaultAccent.opacity(0.06))
                    .frame(width: 150, height: 150)
                Circle()
                    .fill(Color.vaultAccent.opacity(0.04))
                    .frame(width: 100, height: 100)
                Image(systemName: "shield.slash")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [.vaultAccentLight, .vaultPurple],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .padding(.top, 32)

            VStack(spacing: 8) {
                Text("Nenhum grupo ainda")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Crie grupos para organizar e proteger\nseus apps com senha ou Face ID.")
                    .font(.system(size: 14))
                    .foregroundColor(.vaultMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }

            Button { showAddGroup = true } label: {
                Label("Criar Primeiro Grupo", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(colors: [.vaultAccent, .vaultPurple],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(14)
                    .shadow(color: .vaultAccent.opacity(0.3), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }

    private var addFAB: some View {
        Button { showAddGroup = true } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.vaultAccent, .vaultPurple],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 62, height: 62)
                    .shadow(color: .vaultAccent.opacity(0.45), radius: 20, x: 0, y: 10)
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
