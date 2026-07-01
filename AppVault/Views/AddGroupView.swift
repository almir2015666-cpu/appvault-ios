import SwiftUI

struct AddGroupView: View {
    @EnvironmentObject var lockService: AppLockService
    @Environment(\.dismiss) var dismiss
    @FocusState private var nameFocused: Bool

    @State private var groupName = ""
    @State private var selection = AppSelection()
    @State private var showAppPicker = false
    @State private var step = 0

    private let palette = ["#6C63FF","#FF6B6B","#00C9A7","#FF9F43","#48DBFB","#FF6B9D","#54A0FF","#5F27CD"]
    private var autoColor: String { palette[lockService.groups.count % palette.count] }
    private var canContinue: Bool { !groupName.trimmingCharacters(in: .whitespaces).isEmpty && !selection.appNames.isEmpty }

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
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { nameFocused = true } }
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
                showAppPicker = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selection.appNames.isEmpty ? Color.vaultAccent.opacity(0.1) : Color.vaultAccent.opacity(0.15))
                            .frame(width: 46, height: 46)
                        Image(systemName: selection.appNames.isEmpty ? "plus.app.fill" : "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.vaultAccent)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selection.appNames.isEmpty
                             ? "Selecionar aplicativos"
                             : "\(selection.count) app\(selection.count == 1 ? "" : "s") selecionado\(selection.count == 1 ? "" : "s")")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        if !selection.appNames.isEmpty {
                            Text(selection.appNames.prefix(3).joined(separator: " · ") + (selection.count > 3 ? " ···" : ""))
                                .font(.system(size: 12))
                                .foregroundColor(.vaultMuted)
                                .lineLimit(1)
                        } else {
                            Text("Toque para escolher")
                                .font(.system(size: 12))
                                .foregroundColor(.vaultMuted)
                        }
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
                                .stroke(!selection.appNames.isEmpty ? Color.vaultAccent.opacity(0.35) : Color.vaultCardBorder, lineWidth: 1.5)
                        )
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showAppPicker) {
                AppPickerSheet(selection: $selection)
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

// MARK: - App Picker

private struct AppEntry {
    let name: String
    let icon: String
    let cat: String
    let scheme: String
}

struct AppPickerSheet: View {
    @Binding var selection: AppSelection
    @Environment(\.dismiss) var dismiss
    @State private var search = ""
    @State private var installedNames: Set<String> = []
    @State private var showAll = false
    @State private var didScan = false

    private let allApps: [AppEntry] = [
        AppEntry(name: "Instagram",     icon: "camera.fill",                     cat: "Social",          scheme: "instagram"),
        AppEntry(name: "TikTok",        icon: "play.circle.fill",                cat: "Social",          scheme: "tiktok"),
        AppEntry(name: "Twitter/X",     icon: "at",                              cat: "Social",          scheme: "twitter"),
        AppEntry(name: "Facebook",      icon: "person.2.fill",                   cat: "Social",          scheme: "fb"),
        AppEntry(name: "Snapchat",      icon: "camera.aperture",                 cat: "Social",          scheme: "snapchat"),
        AppEntry(name: "BeReal",        icon: "circle.inset.filled",             cat: "Social",          scheme: "bereal"),
        AppEntry(name: "Threads",       icon: "bubble.left.and.bubble.right.fill",cat: "Social",         scheme: "threads"),
        AppEntry(name: "Pinterest",     icon: "photo.on.rectangle.angled",       cat: "Social",          scheme: "pinterest"),
        AppEntry(name: "Kwai",          icon: "video.badge.plus",                cat: "Social",          scheme: "kwai"),
        AppEntry(name: "WhatsApp",      icon: "message.fill",                    cat: "Mensagens",       scheme: "whatsapp"),
        AppEntry(name: "Telegram",      icon: "paperplane.fill",                 cat: "Mensagens",       scheme: "tg"),
        AppEntry(name: "Discord",       icon: "headphones",                      cat: "Mensagens",       scheme: "discord"),
        AppEntry(name: "Messenger",     icon: "ellipsis.bubble.fill",            cat: "Mensagens",       scheme: "fb-messenger"),
        AppEntry(name: "Signal",        icon: "lock.fill",                       cat: "Mensagens",       scheme: "signal"),
        AppEntry(name: "YouTube",       icon: "play.rectangle.fill",             cat: "Entretenimento",  scheme: "youtube"),
        AppEntry(name: "Netflix",       icon: "film.fill",                       cat: "Entretenimento",  scheme: "nflx"),
        AppEntry(name: "Spotify",       icon: "music.note",                      cat: "Entretenimento",  scheme: "spotify"),
        AppEntry(name: "Twitch",        icon: "video.fill",                      cat: "Entretenimento",  scheme: "twitch"),
        AppEntry(name: "Disney+",       icon: "sparkles.tv.fill",                cat: "Entretenimento",  scheme: "disneyplus"),
        AppEntry(name: "Prime Video",   icon: "tv.fill",                         cat: "Entretenimento",  scheme: "prime-video"),
        AppEntry(name: "Deezer",        icon: "waveform",                        cat: "Entretenimento",  scheme: "deezer"),
        AppEntry(name: "Roblox",        icon: "cube.fill",                       cat: "Jogos",           scheme: "roblox"),
        AppEntry(name: "Minecraft",     icon: "square.grid.2x2.fill",            cat: "Jogos",           scheme: "minecraft"),
        AppEntry(name: "Shopee",        icon: "cart.fill",                       cat: "Compras",         scheme: "shopee"),
        AppEntry(name: "iFood",         icon: "fork.knife",                      cat: "Compras",         scheme: "ifood"),
        AppEntry(name: "Mercado Livre", icon: "tag.fill",                        cat: "Compras",         scheme: "mercadolibre"),
        AppEntry(name: "Amazon",        icon: "bag.fill",                        cat: "Compras",         scheme: "amazon-mobile-shopping"),
        AppEntry(name: "LinkedIn",      icon: "briefcase.fill",                  cat: "Trabalho",        scheme: "linkedin"),
        AppEntry(name: "Outlook",       icon: "envelope.fill",                   cat: "Trabalho",        scheme: "ms-outlook"),
        AppEntry(name: "Gmail",         icon: "tray.fill",                       cat: "Trabalho",        scheme: "googlegmail"),
        AppEntry(name: "Reddit",        icon: "bubble.left.and.text.bubble.right.fill", cat: "Outros",   scheme: "reddit"),
        AppEntry(name: "Uber",          icon: "car.fill",                        cat: "Outros",          scheme: "uber"),
        AppEntry(name: "Google Maps",   icon: "map.fill",                        cat: "Outros",          scheme: "comgooglemaps"),
    ]

    private var visibleApps: [AppEntry] {
        let base = (showAll || installedNames.isEmpty) ? allApps : allApps.filter { installedNames.contains($0.name) }
        return search.isEmpty ? base : base.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    private var categories: [String] {
        var seen = Set<String>()
        return visibleApps.compactMap { seen.insert($0.cat).inserted ? $0.cat : nil }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vaultBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    searchBar
                    if didScan && !installedNames.isEmpty {
                        installedBanner
                    }
                    appGrid
                }
            }
            .navigationTitle(selection.count == 0 ? "Escolher Apps" : "\(selection.count) selecionado\(selection.count == 1 ? "" : "s")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !selection.appNames.isEmpty {
                        Button("Limpar") { selection.appNames.removeAll() }
                            .foregroundColor(.vaultMuted)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Pronto") { dismiss() }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.vaultAccent)
                }
            }
        }
        .onAppear { scanInstalledApps() }
    }

    private var installedBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: showAll ? "iphone.slash" : "iphone.badge.play")
                .font(.system(size: 12))
                .foregroundColor(.vaultTeal)
            Text(showAll
                 ? "Mostrando todos os apps"
                 : "\(installedNames.count) app\(installedNames.count == 1 ? "" : "s") detectado\(installedNames.count == 1 ? "" : "s") no seu celular")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.vaultTeal)
            Spacer()
            Button(showAll ? "Só instalados" : "Ver todos") {
                withAnimation(.easeInOut(duration: 0.2)) { showAll.toggle() }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.vaultAccent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.vaultTeal.opacity(0.08))
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.vaultMuted)
                .font(.system(size: 15))
            TextField("Buscar app...", text: $search)
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.vaultCard).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vaultCardBorder, lineWidth: 1)))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var appGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(categories, id: \.self) { cat in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(cat)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.vaultMuted)
                            .tracking(0.8)
                            .textCase(.uppercase)
                            .padding(.leading, 4)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                            ForEach(visibleApps.filter { $0.cat == cat }, id: \.name) { app in
                                appTile(app.name, icon: app.icon)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    private func appTile(_ name: String, icon: String) -> some View {
        let on = selection.appNames.contains(name)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if on { selection.appNames.removeAll { $0 == name } }
            else { selection.appNames.append(name) }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(on ? Color.vaultAccent.opacity(0.18) : Color.vaultCard)
                        .frame(height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(on ? Color.vaultAccent.opacity(0.7) : Color.vaultCardBorder, lineWidth: on ? 2 : 1)
                        )
                    Image(systemName: icon)
                        .font(.system(size: 26))
                        .foregroundColor(on ? .vaultAccent : Color(white: 0.4))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    if on {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.vaultAccent)
                            .background(Circle().fill(Color.vaultBackground).padding(2))
                            .offset(x: 5, y: -5)
                    }
                }
                Text(name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(on ? .white : .vaultMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func scanInstalledApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            var found = Set<String>()
            for app in allApps {
                if let url = URL(string: "\(app.scheme)://"),
                   UIApplication.shared.canOpenURL(url) {
                    found.insert(app.name)
                }
            }
            DispatchQueue.main.async {
                installedNames = found
                didScan = true
            }
        }
    }
}
