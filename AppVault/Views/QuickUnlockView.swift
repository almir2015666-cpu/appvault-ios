import SwiftUI

struct QuickUnlockView: View {
    @EnvironmentObject var lockService: AppLockService
    @EnvironmentObject var authService: AuthService

    @State private var selectedGroupId: UUID?
    @State private var showingPinEntry = false

    private var activeGroups: [LockGroup] {
        lockService.groups.filter { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vaultBackground.ignoresSafeArea()
                if activeGroups.isEmpty {
                    emptyState
                } else {
                    groupList
                }
            }
            .navigationTitle("Desbloquear App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") { lockService.showingUnlockFromShield = false }
                        .foregroundColor(.vaultMuted)
                }
            }
        }
        .sheet(isPresented: $showingPinEntry) {
            if let id = selectedGroupId,
               let group = lockService.groups.first(where: { $0.id == id }) {
                PinEntryView(
                    group: group,
                    onSuccess: {
                        lockService.temporarilyUnlock(groupId: id)
                        lockService.showingUnlockFromShield = false
                    },
                    onCancel: {
                        showingPinEntry = false
                        selectedGroupId = nil
                    }
                )
                .environmentObject(lockService)
                .environmentObject(authService)
            }
        }
    }

    private var groupList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Selecione o grupo para desbloquear")
                .font(.system(size: 13))
                .foregroundColor(.vaultMuted)
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(activeGroups) { group in
                        LockGroupCard(
                            group: group,
                            onToggle: {},
                            onTap: {
                                selectedGroupId = group.id
                                showingPinEntry = true
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 52))
                .foregroundColor(.vaultGreen)
            Text("Nenhum grupo ativo")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Não há grupos bloqueando apps no momento.")
                .font(.system(size: 13))
                .foregroundColor(.vaultMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}
