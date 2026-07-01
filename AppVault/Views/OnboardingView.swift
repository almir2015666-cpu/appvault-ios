import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var lockService: AppLockService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "shield.fill",
            gradientColors: ["#6C63FF", "#9D4EDD"],
            title: "Bem-vindo ao AppVault",
            subtitle: "Proteja qualquer app com sua própria senha. Você decide quem acessa o quê, quando quiser."
        ),
        OnboardingPage(
            icon: "rectangle.grid.2x2.fill",
            gradientColors: ["#00C9A7", "#6C63FF"],
            title: "Grupos Inteligentes",
            subtitle: "Organize seus apps por categoria com senhas únicas. Redes sociais, jogos, compras — tudo separado."
        ),
        OnboardingPage(
            icon: "faceid",
            gradientColors: ["#FF7849", "#FFB347"],
            title: "Face ID & Touch ID",
            subtitle: "Desbloqueie com biometria de forma instantânea. Segurança sem abrir mão da praticidade."
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
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: currentPage)

                bottomSection
            }
        }
    }

    private var bottomSection: some View {
        VStack(spacing: 18) {
            // Dots
            HStack(spacing: 6) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? Color.vaultAccent : Color.vaultCard)
                        .frame(width: i == currentPage ? 26 : 8, height: 8)
                        .animation(.spring(response: 0.35), value: currentPage)
                }
            }

            if currentPage < pages.count - 1 {
                HStack(spacing: 12) {
                    Button("Pular") { hasCompletedOnboarding = true }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.vaultMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.vaultCard)
                                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.vaultCardBorder, lineWidth: 1))
                        )

                    Button("Próximo") { withAnimation { currentPage += 1 } }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            LinearGradient(
                                colors: [.vaultAccent, .vaultPurple],
                                startPoint: .leading, endPoint: .trailing
                            )
                            .cornerRadius(15)
                        )
                }
            } else {
                Button("Começar Agora") { hasCompletedOnboarding = true }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 19)
                    .background(
                        LinearGradient(colors: [.vaultAccent, .vaultPurple],
                                       startPoint: .leading, endPoint: .trailing)
                        .cornerRadius(17)
                    )
                    .shadow(color: .vaultAccent.opacity(0.4), radius: 24, x: 0, y: 10)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 52)
        .padding(.top, 14)
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let gradientColors: [String]
    let title: String
    let subtitle: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 44) {
            Spacer()

            ZStack {
                // Outer soft ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: page.gradientColors[0]).opacity(0.14), .clear],
                            center: .center, startRadius: 60, endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)

                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradientColors.map { Color(hex: $0).opacity(0.18) },
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 144, height: 144)
                    .overlay(
                        Circle().stroke(
                            LinearGradient(
                                colors: [Color(hex: page.gradientColors[0]).opacity(0.4), .clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                    )

                Image(systemName: page.icon)
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.gradientColors.map { Color(hex: $0) },
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.vaultMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 12)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                LinearGradient(colors: [Color.vaultAccent, Color.vaultPurple],
                               startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(15)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}
