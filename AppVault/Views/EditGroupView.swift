import SwiftUI
import FamilyControls

struct EditGroupView: View {
    let groupId: UUID
    @EnvironmentObject var lockService: AppLockService
    @Environment(\.dismiss) var dismiss
    @FocusState private var nameFocused: Bool

    @State private var groupName = ""
    @State private var selection = FamilyActivitySelection()
    @State private var showAppPicker = false
    @State private var showChangePinSheet = false
    @State private var initialized = false

    private var currentGroup: LockGroup? {
        lockService.groups.first { $0.id == groupId }
    }

    private var canSave: Bool {
        !groupName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            Color.vaultBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        nameField
                        appPickerButton
                        changePinButton
                    }
                    .padding(24)
                }
                saveBar
            }
        }
        .navigationTitle("Editar Grupo")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancelar") { dismiss() }
                    .foregroundColor(.vaultMuted)
            }
        }
        .familyActivityPicker(isPresented: $showAppPicker, selection: $selection)
        .sheet(isPresented: $showChangePinSheet) {
            if let group = currentGroup {
                NavigationStack {
                    PinSetupView(
                        groupName: group.name,
                        lockType: group.lockType,
                        onComplete: { newPin in
                            guard !newPin.isEmpty else { return }
                            try? KeychainService.shared.savePin(newPin, forGroupId: group.id)
                            var updated = group
                            updated.pinHash = "set"
                            lockService.updateGroup(updated)
                            showChangePinSheet = false
                        },
                        onBack: { showChangePinSheet = false }
                    )
                    .navigationTitle("Alterar Senha")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cancelar") { showChangePinSheet = false }
                                .foregroundColor(.vaultMuted)
                        }
                    }
                }
            }
        }
        .onAppear {
            guard !initialized, let group = currentGroup else { return }
            groupName = group.name
            selection = group.selection
            initialized = true
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Nome do grupo")
            TextField("Ex: Redes Sociais", text: $groupName)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.vaultCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(nameFocused
                                        ? Color.vaultAccent.opacity(0.6)
                                        : Color.vaultCardBorder, lineWidth: 1.5)
                        )
                )
                .focused($nameFocused)
        }
    }

    private var appPickerButton: some View {
        let count = selection.applicationTokens.count
        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Aplicativos")
            Button {
                nameFocused = false
                showAppPicker = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.vaultAccent.opacity(count == 0 ? 0.1 : 0.15))
                            .frame(width: 46, height: 46)
                        Image(systemName: count == 0 ? "plus.app.fill" : "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.vaultAccent)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(count == 0
                             ? "Selecionar aplicativos"
                             : "\(count) app\(count == 1 ? "" : "s") selecionado\(count == 1 ? "" : "s")")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text(count == 0 ? "Toque para escolher" : "Toque para editar a seleção")
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(count > 0
                                        ? Color.vaultAccent.opacity(0.35)
                                        : Color.vaultCardBorder, lineWidth: 1.5)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var changePinButton: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Segurança")
            Button { showChangePinSheet = true } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.vaultPurple.opacity(0.15))
                            .frame(width: 46, height: 46)
                        Image(systemName: "key.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.vaultPurple)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alterar Senha")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Definir um novo PIN para este grupo")
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.vaultCardBorder, lineWidth: 1.5)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.vaultCardBorder).frame(height: 1)
            Button("Salvar Alterações") {
                guard canSave, var group = currentGroup else { return }
                group.name = groupName.trimmingCharacters(in: .whitespaces)
                group.selection = selection
                lockService.updateGroup(group)
                dismiss()
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(canSave ? .white : .vaultMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if canSave {
                        LinearGradient(
                            colors: [.vaultAccent, .vaultPurple],
                            startPoint: .leading, endPoint: .trailing)
                        .cornerRadius(16)
                    } else {
                        Color.vaultCard.cornerRadius(16)
                    }
                }
            )
            .padding(20)
            .disabled(!canSave)
        }
        .background(Color.vaultBackground)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.vaultMuted)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}
