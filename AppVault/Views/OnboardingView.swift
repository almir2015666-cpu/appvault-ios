import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var lockService: AppLockService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "lock.shield.fill",
            iconColor: "#4361EE",
            title: "Bem-vindo ao AppVault",
            subtitle: "Bloqueie qualquer app com a sua própria senha. Você decide quem acessa o quê.",
            gradient: ["#0D0D1A", "#1A1B4B"]
        ),
        OnboardingPage(
            icon: "person.2.fill",
            iconColor: "#7B2FBE",
            title: "Senhas Diferentes para Cada App",
            subtitle: "Crie grupos de apps com senhas únicas. Redes sociais, jogos, compras — tudo separado.",
            gradient: ["#0D0D1A", "#2D0B5E"]
        ),
        OnboardingPage(
            icon: "faceid",
            iconColor: "#06D6A0",
            title: "Face ID & Touch ID",
            subtitle: "Desbloqueie com biometria para ainda mais comodidade e segurança.",
            gradient: ["#0D0D1A", "#0A3D30"]
        ),
    ]

    var body: some View {
        ZStack {
            Color.vaultBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomSection
            }
        }
    }

    private var bottomSection: some View {
        VStack(spacing: 20) {
            pageIndicator

            if currentPage < pages.count - 1 {
                Button("Próximo") {
                    withAnimation { currentPage += 1 }
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button("Permitir Acesso") {
                    Task { await lockService.requestAuthorization() }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Pular por agora") {
                    hasCompletedOnboarding = true
                }
                .font(.system(size: 15))
                .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 48)
        .padding(.top, 16)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? Color.vaultAccent : Color.vaultCard)
                    .frame(width: i == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: String
    let title: String
    let subtitle: String
    let gradient: [String]
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: page.iconColor).opacity(0.12))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(Color(hex: page.iconColor).opacity(0.06))
                    .frame(width: 200, height: 200)
                Image(systemName: page.icon)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: page.iconColor), Color(hex: page.iconColor).opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.vaultAccent, Color.vaultPurple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}
