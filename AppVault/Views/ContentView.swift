import SwiftUI

struct ContentView: View {
    @EnvironmentObject var lockService: AppLockService
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
                    .environmentObject(lockService)
                    .environmentObject(authService)
            }
            .tabItem {
                Image(systemName: selectedTab == 0 ? "shield.fill" : "shield")
                Text("Início")
            }
            .tag(0)

            NavigationStack {
                SettingsView()
                    .environmentObject(lockService)
                    .environmentObject(authService)
            }
            .tabItem {
                Image(systemName: selectedTab == 1 ? "gearshape.fill" : "gearshape")
                Text("Config.")
            }
            .tag(1)
        }
        .tint(Color.vaultAccent)
        .preferredColorScheme(.dark)
        .onAppear { configureTabBar() }
        .sheet(isPresented: $lockService.showingUnlockFromShield) {
            QuickUnlockView()
                .environmentObject(lockService)
                .environmentObject(authService)
        }
    }

    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.vaultSurface)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.06)

        let normalAttr: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor(Color.vaultMuted)]
        let selectedAttr: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor(Color.vaultAccent)]

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttr
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttr
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.vaultMuted)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.vaultAccent)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
