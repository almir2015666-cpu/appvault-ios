import SwiftUI

struct HomeView: View {
    @EnvironmentObject var lockService: AppLockService
    @State private var showAddGroup = false

    private var activeCount: Int { lockService.groups.filter(\.isActive).count }
    private var totalApps: Int { lockService.groups.filter(\.isActive).reduce(0) { $0 + $1.appCount } }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vaultBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        statsHeader
                        groupsList
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("AppVault")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddGroup = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.vaultAccent, Color.vaultPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .sheet(isPresented: $showAddGroup) {
                AddGroupView()
                    .environmentObject(lockService)
            }
        }
    }

    private var statsHeader: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(activeCount)",
                label: "Grupos Ativos",
                icon: "lock.fill",
                color: .vaultAccent
            )
            StatCard(
                value: "\(totalApps)",
                label: "Apps Bloqueados",
                icon: "shield.fill",
                color: .vaultPurple
            )
        }
    }

    private var groupsList: some View {
        VStack(spacing: 12) {
            if lockService.groups.isEmpty {
                emptyState
            } else {
                ForEach(lockService.groups) { group in
                    LockGroupCard(
                        group: group,
                        onToggle: { lockService.toggleGroup(group) },
                        onTap: {}
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.slash")
                .font(.system(size: 52))
                .foregroundStyle(LinearGradient(
                    colors: [Color.vaultAccent, Color.vaultPurple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .padding(.top, 48)

            Text("Nenhum app bloqueado")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Text("Toque em + para criar seu primeiro grupo de bloqueio")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Criar Primeiro Grupo") {
                showAddGroup = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(16)
        .background(Color.vaultCard)
        .cornerRadius(16)
    }
}
