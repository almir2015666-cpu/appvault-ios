import SwiftUI
import FamilyControls

struct AddGroupView: View {
    @EnvironmentObject var lockService: AppLockService
    @Environment(\.dismiss) var dismiss

    @State private var groupName = ""
    @State private var selectedColorHex = "#4361EE"
    @State private var selectedIcon = "lock.shield.fill"
    @State private var selectedPreset: Int? = nil
    @State private var selection = FamilyActivitySelection()
    @State private var showAppPicker = false
    @State private var lockType = LockGroup.LockType.pin4
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var pinError = ""
    @State private var step = 0
    @State private var isBiometricEnabled = false

    @EnvironmentObject var authService: AuthService

    private let colors = ["#4361EE", "#7B2FBE", "#E91E8C", "#FF6B35", "#06D6A0", "#FF6B6B", "#FFD700", "#00B4D8"]
    private let icons = ["lock.shield.fill", "lock.fill", "key.fill", "shield.fill",
                         "eye.slash.fill", "hand.raised.fill", "exclamationmark.shield.fill", "checkmark.shield.fill"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vaultBackground.ignoresSafeArea()
                content
            }
            .navigationTitle(step == 0 ? "Novo Grupo" : "Definir PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if step == 0 {
            groupSetupStep
        } else {
            PinSetupView(
                groupName: groupName,
                lockType: lockType,
                onComplete: { newPin in
                    saveGroup(pin: newPin)
                },
                onBack: { step = 0 }
            )
        }
    }

    private var groupSetupStep: some View {
        ScrollView {
            VStack(spacing: 28) {
                previewCard
                nameField
                presetSection
                colorSection
                iconSection
                appsSection
                lockTypeSection
                continueButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }

    private var previewCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: selectedColorHex).opacity(0.18))
                    .frame(width: 60, height: 60)
                Image(systemName: selectedIcon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(Color(hex: selectedColorHex))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(groupName.isEmpty ? "Nome do Grupo" : groupName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(groupName.isEmpty ? .gray : .white)
                Text("\(selection.applicationTokens.count) app\(selection.applicationTokens.count == 1 ? "" : "s") selecionado\(selection.applicationTokens.count == 1 ? "" : "s")")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(20)
        .background(Color.vaultCard)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: selectedColorHex).opacity(0.3), lineWidth: 1.5))
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Nome do Grupo", systemImage: "textformat")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            TextField("Ex: Redes Sociais", text: $groupName)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(14)
                .background(Color.vaultCard)
                .cornerRadius(12)
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Presets", systemImage: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(LockGroup.presets.enumerated()), id: \.offset) { index, preset in
                        Button {
                            selectedPreset = index
                            groupName = preset.name
                            selectedColorHex = preset.color
                            selectedIcon = preset.icon
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: preset.icon)
                                    .font(.system(size: 13))
                                Text(preset.name)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(selectedPreset == index ? .white : .white.opacity(0.6))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedPreset == index ? Color(hex: preset.color) : Color.vaultCard)
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Cor", systemImage: "paintpalette")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            HStack(spacing: 10) {
                ForEach(colors, id: \.self) { hex in
                    Button {
                        selectedColorHex = hex
                        selectedPreset = nil
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: selectedColorHex == hex ? 3 : 0)
                                    .padding(3)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ícone", systemImage: "square.grid.2x2")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedIcon == icon ? Color(hex: selectedColorHex).opacity(0.2) : Color.vaultCard)
                                .frame(width: 40, height: 40)
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundColor(selectedIcon == icon ? Color(hex: selectedColorHex) : .white.opacity(0.5))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Aplicativos", systemImage: "apps.iphone")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            Button {
                showAppPicker = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(hex: selectedColorHex))
                    Text(selection.applicationTokens.isEmpty ? "Selecionar Aplicativos" : "Alterar Seleção (\(selection.applicationTokens.count) apps)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                .padding(16)
                .background(Color.vaultCard)
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
            .familyActivityPicker(isPresented: $showAppPicker, selection: $selection)
        }
    }

    private var lockTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tipo de Bloqueio", systemImage: "lock.rotation")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            VStack(spacing: 8) {
                ForEach(LockGroup.LockType.allCases) { type in
                    Button {
                        lockType = type
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: type.icon)
                                .font(.system(size: 18))
                                .foregroundColor(lockType == type ? Color(hex: selectedColorHex) : .gray)
                                .frame(width: 24)
                            Text(type.rawValue)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                            Spacer()
                            if lockType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: selectedColorHex))
                            }
                        }
                        .padding(14)
                        .background(lockType == type ? Color(hex: selectedColorHex).opacity(0.1) : Color.vaultCard)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(lockType == type ? Color(hex: selectedColorHex).opacity(0.4) : Color.clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var continueButton: some View {
        Button("Continuar") {
            step = 1
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(groupName.isEmpty || selection.applicationTokens.isEmpty)
        .opacity(groupName.isEmpty || selection.applicationTokens.isEmpty ? 0.5 : 1)
    }

    private func saveGroup(pin: String) {
        var group = LockGroup(name: groupName, colorHex: selectedColorHex, iconName: selectedIcon)
        group.selection = selection
        group.lockType = lockType
        group.isBiometricEnabled = lockType == .biometric || lockType == .biometricWithPin

        if !pin.isEmpty {
            try? KeychainService.shared.savePin(pin, forGroupId: group.id)
            group.pinHash = "set"
        }

        lockService.addGroup(group)
        dismiss()
    }
}
