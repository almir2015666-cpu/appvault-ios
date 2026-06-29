import SwiftUI

struct ContentView: View {
    @EnvironmentObject var lockService: AppLockService
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(lockService)
                .environmentObject(authService)
                .tabItem {
                    Label("Início", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            SettingsView()
                .environmentObject(lockService)
                .environmentObject(authService)
                .tabItem {
                    Label("Configurações", systemImage: selectedTab == 1 ? "gearshape.fill" : "gearshape")
                }
                .tag(1)
        }
        .tint(Color.vaultAccent)
        .preferredColorScheme(.dark)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor(Color.vaultBackground).withAlphaComponent(0.95)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
