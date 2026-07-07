import SwiftUI

struct GroupDetailView: View {
    let groupId: UUID
    @EnvironmentObject var lockService: AppLockService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var pendingAction: GroupAction?
    @State private var showingPinEntry = false
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false

    enum GroupAction { case unlock, edit, delete }

    private var group: LockGroup? {
        lockService.groups.first { $0.id == groupId }
    }

    var body: some View {
        ZStack {
            Color.vaultBackground.ignoresSafeArea()
            if let group {
                mainContent(group)
            }
        }
        .navigationTitle(group?.name ?? "Grupo")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingPinEntry) {
            if let group {
                PinEntryView(
                    group: group,
                    onSuccess: {
                        showingPinEntry = false
                        handleAuthSuccess()
                    },
                    onCancel: {
                        showingPinEntry = false
                        pendingAction = nil
                    }
                )
                .environmentObject(lockService)
                .environmentObject(authService)
            }
        }
        .navigationDestination(isPresented: $showingEdit) {
            if let group {
                EditGroupView(groupId: group.id)
            }
        }
        .alert("Excluir \"\(group?.name ?? "grupo")\"?", isPresented: $showingDeleteAlert) {
            Button("Excluir", role: .destructive) {
                if let group { lockService.deleteGroup(group) }
                dismiss()
            }
            Button("Cancelar", role: .cancel) { pendingAction = nil }
        } message: {
            Text("Todos os apps e a senha do grupo serão removidos permanentemente.")
        }
    }

    private func handleAuthSuccess() {
        switch pendingAction {
        case .unlock:
            lockService.temporarilyUnlock(groupId: groupId)
            dismiss()
        case .edit:
            showingEdit = true
        case .delete:
            showingDeleteAlert = true
        case nil:
            break
        }
        pendingAction = nil
    }

    @ViewBuilder
    private func mainContent(_ group: LockGroup) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                groupHeader(group)
                if group.isActive {
                    unlockSection(group)
                }
                manageSection()
                dangerSection(group)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }

    private func groupHeader(_ group: LockGroup) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: group.colorHex).opacity(0.08))
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(Color(hex: group.colorHex).opacity(0.15))
                    .frame(width: 88, height: 88)
                Image(systemName: group.iconName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(Color(hex: group.colorHex))
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(group.isActive ? Color.vaultGreen : Color.vaultMuted)
                    .frame(width: 7, height: 7)
                Text(group.isActive ? "Ativo" : "Inativo")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(group.isActive ? .vaultGreen : .vaultMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(group.isActive ? Color.vaultGreen.opacity(0.1) : Color.vaultCard)
                    .overlay(Capsule().stroke(
                        group.isActive ? Color.vaultGreen.opacity(0.3) : Color.vaultCardBorder, lineWidth: 1))
            )

            HStack(spacing: 12) {
                statPill(value: "\(group.appCount)", label: "apps protegidos")
                statPill(value: "PIN 4", label: "tipo de senha")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func statPill(value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.vaultMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.vaultCard)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vaultCardBorder, lineWidth: 1))
        )
    }

    private func unlockSection(_ group: LockGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("ACESSO TEMPORÁRIO")
            Button {
                pendingAction = .unlock
                showingPinEntry = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: group.colorHex).opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: group.colorHex))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Desbloquear por 5 min")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Inserir senha para acesso temporário")
                            .font(.system(size: 12))
                            .foregroundColor(.vaultMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.vaultMuted)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.vaultCard)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(
                            Color(hex: group.colorHex).opacity(0.3), lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func manageSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("GERENCIAR")
            Button {
                pendingAction = .edit
                showingPinEntry = true
            } label: {
                actionRow(
                    icon: "pencil", color: .vaultAccent,
                    title: "Editar Grupo",
                    subtitle: "Nome, apps e senha"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func dangerSection(_ group: LockGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("ZONA DE RISCO")
            Button {
                pendingAction = .delete
                showingPinEntry = true
            } label: {
                actionRow(
                    icon: "trash.fill", color: .vaultRed,
                    title: "Excluir Grupo",
                    subtitle: "Remove apps e senha permanentemente",
                    destructive: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func actionRow(icon: String, color: Color, title: String, subtitle: String, destructive: Bool = false) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(destructive ? color : .white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.vaultMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.vaultMuted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vaultCard)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.vaultCardBorder, lineWidth: 1))
        )
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.vaultMuted)
            .tracking(0.8)
            .padding(.leading, 4)
    }
}
