import SwiftUI

@main
struct AppVaultApp: App {
    @StateObject private var lockService = AppLockService.shared
    @StateObject private var authService = AuthService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(lockService)
                    .environmentObject(authService)
            } else {
                OnboardingView()
                    .environmentObject(lockService)
                    .environmentObject(authService)
            }
        }
    }
}
