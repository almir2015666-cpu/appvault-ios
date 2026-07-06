import SwiftUI
import FamilyControls

struct AddGroupView: View {
    @EnvironmentObject var lockService: AppLockService
    @Environment(\.dismiss) var dismiss
    @FocusState private var nameFocused: Bool

    @State private var groupName = ""
    @State private var selection = FamilyActivitySelection()
    @State private var step = 0
    @State private var navigateToPicker = false
    @State private var showAuthAlert = false
    @State private var requestingAuth = false

    private let palette = ["#6C63FF","#FF6B6B","#00C9A7","#FF9F43","#48DBFB","#FF6B9D","#54A0FF","#5F27CD"]
    private var autoColor: String { palette[lockService.groups.count % palette.count] }
    private var appCount: Int { selection.applicationTokens.count }
    private var canContinue: Bool { !groupName.trimmingCharacters(in: .whitespaces).isEmpty && appCount > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vaultBackground.ignoresSafeArea()
                if step == 0 { setupStep } else { pinStep }
            }
            .navigationTitle(step == 0 ? "Novo Grupo" : "Criar Senha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }.foregroundColor(.vaultMuted)
                }
            }
            .navigationDestination(isPresented: $navigateToPicker) {
                FamilyActivityPicker(selection: $selection)
                    .navigationTitle("Escolher Apps")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { nameFocused = true } }
        .alert("Permissão necessária", isPresented: $showAuthAlert) {
            Button("Abrir Ajustes") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Ative o Tempo de Uso para o AppVault em:\nAjustes → Tempo de Uso")
        }
    }

    // MARK: - Step 1: Nome + Apps

    private var setupStep: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    nameField
                    appPickerButton
                }
                .padding(24)
            }
            bottomBar
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Nome do grupo")
            TextField("Ex: Redes Sociais", text: $groupName)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.vaultCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(nameFocused ? Color.vaultAccent.opacity(0.6) : Color.vaultCardBorder, lineWidth: 1.5)
                        )
                )
                .focused($nameFocused)
        }
    }

    private var appPickerButton: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Aplicativos")
            Button {
                nameFocused = false
                openPicker()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(appCount == 0 ? Color.vaultAccent.opacity(0.1) : Color.vaultAccent.opacity(0.15))
                            .frame(width: 46, height: 46)
                        Image(systemName: appCount == 0 ? "plus.app.fill" : "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.vaultAccent)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appCount == 0
                             ? "Selecionar aplicativos"
                             : "\(appCount) app\(appCount == 1 ? "" : "s") selecionado\(appCount == 1 ? "" : "s")")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text(appCount == 0 ? "Toque para escolher" : "Toque para editar a seleção")
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
                                .stroke(appCount > 0 ? Color.vaultAccent.opacity(0.35) : Color.vaultCardBorder, lineWidth: 1.5)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func openPicker() {
        if lockService.isAuthorized {
            navigateToPicker = true
            return
        }
        requestingAuth = true
        Task {
            await lockService.requestAuthorization()
            requestingAuth = false
            if lockService.isAuthorized {
                navigateToPicker = true
            } else {
                showAuthAlert = true
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.vaultCardBorder).frame(height: 1)
            Button("Definir Senha") { step = 1 }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(canContinue ? .white : .vaultMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Group {
                        if canContinue {
                            LinearGradient(colors: [.vaultAccent, .vaultPurple], startPoint: .leading, endPoint: .trailing)
                                .cornerRadius(16)
                        } else {
                            Color.vaultCard.cornerRadius(16)
                        }
                    }
                )
                .padding(20)
                .animation(.easeInOut(duration: 0.2), value: canContinue)
                .disabled(!canContinue)
        }
        .background(Color.vaultBackground)
    }

    // MARK: - Step 2: PIN

    private var pinStep: some View {
        PinSetupView(
            groupName: groupName,
            lockType: .pin4,
            onComplete: { pin in saveGroup(pin: pin) },
            onBack: { step = 0 }
        )
    }

    private func saveGroup(pin: String) {
        var group = LockGroup(
            name: groupName.trimmingCharacters(in: .whitespaces),
            colorHex: autoColor,
            iconName: "lock.fill"
        )
        group.selection = selection
        group.lockType = .pin4
        if !pin.isEmpty {
            try? KeychainService.shared.savePin(pin, forGroupId: group.id)
            group.pinHash = "set"
        }
        lockService.addGroup(group)
        dismiss()
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.vaultMuted)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}
