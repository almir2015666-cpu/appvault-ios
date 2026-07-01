import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var done = false
    @State private var page = 0

    private let pages: [(icon: String, colors: [String], title: String, sub: String)] = [
        ("lock.shield.fill",         ["#6C63FF","#9D4EDD"],
         "Bem-vindo ao AppVault",
         "Proteja qualquer app com uma senha pessoal. Simples, rápido e seguro."),
        ("rectangle.grid.2x2.fill",  ["#00C9A7","#54A0FF"],
         "Grupos por categoria",
         "Crie grupos de apps — redes sociais, jogos, trabalho — cada um com sua senha."),
        ("faceid",                   ["#FF9F43","#FF6B6B"],
         "Face ID incluso",
         "Desbloqueie com Face ID ou Touch ID. Segurança sem complicação."),
    ]

    var body: some View {
        ZStack {
            Color.vaultBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageView(pages[i]).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                bottom
            }
        }
    }

    private func pageView(_ p: (icon: String, colors: [String], title: String, sub: String)) -> some View {
        VStack(spacing: 40) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(hex: p.colors[0]).opacity(0.18), .clear],
                        center: .center, startRadius: 50, endRadius: 140))
                    .frame(width: 280, height: 280)
                Circle()
                    .fill(LinearGradient(
                        colors: p.colors.map { Color(hex: $0).opacity(0.2) },
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 140, height: 140)
                Image(systemName: p.icon)
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(LinearGradient(
                        colors: p.colors.map { Color(hex: $0) },
                        startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            VStack(spacing: 14) {
                Text(p.title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white).multilineTextAlignment(.center)
                Text(p.sub)
                    .font(.system(size: 15)).foregroundColor(.vaultMuted)
                    .multilineTextAlignment(.center).lineSpacing(6)
                    .padding(.horizontal, 8)
            }
            Spacer(); Spacer()
        }
        .padding(.horizontal, 36)
    }

    private var bottom: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Color.vaultAccent : Color.vaultCard)
                        .frame(width: i == page ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: page)
                }
            }
            if page < pages.count - 1 {
                HStack(spacing: 12) {
                    Button("Pular") { done = true }
                        .font(.system(size: 15, weight: .medium)).foregroundColor(.vaultMuted)
                        .frame(maxWidth: .infinity).padding(.vertical, 17)
                        .background(RoundedRectangle(cornerRadius: 15).fill(Color.vaultCard)
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.vaultCardBorder, lineWidth: 1)))
                    Button("Próximo") { withAnimation(.spring(response: 0.4)) { page += 1 } }
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 17)
                        .background(LinearGradient(colors: [.vaultAccent,.vaultPurple], startPoint: .leading, endPoint: .trailing).cornerRadius(15))
                }
            } else {
                Button("Começar") { done = true }
                    .font(.system(size: 17, weight: .black)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 19)
                    .background(LinearGradient(colors: [.vaultAccent,.vaultPurple], startPoint: .leading, endPoint: .trailing).cornerRadius(17))
                    .shadow(color: .vaultAccent.opacity(0.45), radius: 24, x: 0, y: 10)
            }
        }
        .padding(.horizontal, 24).padding(.bottom, 52).padding(.top, 14)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
            .frame(maxWidth: .infinity).padding(.vertical, 17)
            .background(LinearGradient(colors: [Color.vaultAccent, Color.vaultPurple], startPoint: .leading, endPoint: .trailing))
            .cornerRadius(15)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}
