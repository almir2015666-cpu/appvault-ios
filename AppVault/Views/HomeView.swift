import SwiftUI

struct HomeView: View {
    @EnvironmentObject var lockService: AppLockService
    @State private var showAddGroup = false

    private var active: [LockGroup] { lockService.groups.filter(\.isActive) }
    private var totalApps: Int { active.reduce(0) { $0 + $1.appCount } }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.vaultBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    if !lockService.isAuthorized {
                        authBanner
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    }
                    if !lockService.groups.isEmpty {
                        summaryCard
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                    }
                    groupsList
                        .padding(.top, 28)
                }
                .padding(.bottom, 110)
            }

            addButton
                .padding(.trailing, 22)
                .padding(.bottom, 24)
        }
        .sheet(isPresented: $showAddGroup) {
            AddGroupView().environmentObject(lockService)
        }
        .task {
            if !lockService.isAuthorized {
                await lockService.requestAuthorization()
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("AppVault")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient(
                        colors: [.vaultAccentLight, .vaultPurple],
                        startPoint: .leading, endPoint: .trailing))
                Text(lockService.groups.isEmpty ? "Comece adicionando um grupo" : "Seus apps protegidos")
                    .font(.system(size: 13))
                    .foregroundColor(.vaultMuted)
            }
            Spacer()
            if !lockService.groups.isEmpty { statusPill }
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
    }

    private var authBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.vaultOrange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Permissão necessária")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("O AppVault precisa de acesso ao Tempo de Uso para funcionar.")
                        .font(.system(size: 12))
                        .foregroundColor(.vaultMuted)
                }
            }
            Button {
                Task { await lockService.requestAuthorization() }
            } label: {
                Text("Permitir Acesso")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LinearGradient(colors: [.vaultOrange, .vaultRed], startPoint: .leading, endPoint: .trailing).cornerRadius(12))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vaultOrange.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vaultOrange.opacity(0.3), lineWidth: 1))
        )
    }

    private var statusPill: some View {
        let on = !active.isEmpty
        return HStack(spacing: 6) {
            Circle()
                .fill(on ? Color.vaultGreen : Color.vaultMuted)
                .frame(width: 7, height: 7)
            Text(on ? "Ativo" : "Inativo")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(on ? .vaultGreen : .vaultMuted)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(on ? Color.vaultGreen.opacity(0.1) : Color.vaultCard)
                .overlay(Capsule().stroke(on ? Color.vaultGreen.opacity(0.3) : Color.vaultCardBorder, lineWidth: 1))
        )
    }

    // MARK: Summary card

    private var summaryCard: some View {
        HStack(spacing: 0) {
            stat(value: "\(lockService.groups.count)", label: "Grupos", color: .vaultAccent)
            vDivider
            stat(value: "\(active.count)", label: "Ativos", color: .vaultGreen)
            vDivider
            stat(value: "\(totalApps)", label: "Apps", color: .vaultPurple)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.vaultCard)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.vaultCardBorder, lineWidth: 1))
        )
    }

    private func stat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.vaultMuted)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    private var vDivider: some View {
        Rectangle().fill(Color.vaultCardBorder).frame(width: 1, height: 48)
    }

    // MARK: Groups list

    private var groupsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !lockService.groups.isEmpty {
                HStack {
                    Text("Grupos")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 22)
            }

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

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)

            ZStack {
                ForEach([140, 100, 66].indices, id: \.self) { i in
                    Circle()
                        .fill(Color.vaultAccent.opacity(Double([0.04, 0.07, 0.12][i])))
                        .frame(width: CGFloat([140, 100, 66][i]))
                }
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(LinearGradient(
                        colors: [.vaultAccentLight, .vaultPurple],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
            }

            VStack(spacing: 8) {
                Text("Nenhum grupo criado")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Crie um grupo, escolha os apps\ne defina uma senha.")
                    .font(.system(size: 14))
                    .foregroundColor(.vaultMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }

            Button { showAddGroup = true } label: {
                Label("Criar grupo", systemImage: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.vaultAccent, .vaultPurple],
                                       startPoint: .leading, endPoint: .trailing)
                        .cornerRadius(14)
                    )
                    .shadow(color: .vaultAccent.opacity(0.35), radius: 18, x: 0, y: 8)
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: FAB

    private var addButton: some View {
        Button { showAddGroup = true } label: {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.vaultAccent, .vaultPurple],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 62, height: 62)
                    .shadow(color: .vaultAccent.opacity(0.5), radius: 22, x: 0, y: 10)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
