import SwiftUI
import UIKit
import FamilyControls
import UserNotifications

// Trata o toque na notificação disparada pela Shield Action:
// abre o app e sinaliza para mostrar a tela de senha.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Mostra a notificação mesmo com o app em primeiro plano.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Toque na notificação -> abre a tela de desbloqueio.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.content.userInfo["action"] as? String == "unlock" {
            Task { @MainActor in
                AppLockService.shared.showingUnlockFromShield = true
            }
        }
        completionHandler()
    }
}

@main
struct AppVaultApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
            .onOpenURL { url in
                guard url.scheme == "appvault" else { return }
                if url.host == "unlock" {
                    lockService.showingUnlockFromShield = true
                }
            }
            .task {
                await lockService.requestAuthorization()
                await requestNotificationPermission()
            }
        }
    }

    private func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }
}
