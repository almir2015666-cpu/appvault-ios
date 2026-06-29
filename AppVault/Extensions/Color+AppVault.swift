import SwiftUI

extension Color {
    static let vaultBackground = Color(hex: "#0D0D1A")
    static let vaultCard = Color(hex: "#1A1B3A")
    static let vaultAccent = Color(hex: "#4361EE")
    static let vaultPurple = Color(hex: "#7B2FBE")
    static let vaultGreen = Color(hex: "#06D6A0")
    static let vaultRed = Color(hex: "#EF233C")
    static let vaultOrange = Color(hex: "#FF6B35")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 3:
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
