import SwiftUI
import FamilyControls

@main
struct AppVaultApp: App {
    @StateObject private var lockService = AppLockService.shared
    @StateObject private var authService = AuthService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
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
            .task {
                await lockService.requestAuthorization()
            }
        }
    }
}
