import SwiftUI

extension Color {
    static let vaultBackground  = Color(hex: "#070710")
    static let vaultSurface     = Color(hex: "#0D0E20")
    static let vaultCard        = Color(hex: "#10112A")
    static let vaultCardHigh    = Color(hex: "#171934")
    static let vaultCardBorder  = Color(white: 1, opacity: 0.07)
    static let vaultAccent      = Color(hex: "#6C63FF")
    static let vaultAccentLight = Color(hex: "#9D97FF")
    static let vaultPurple      = Color(hex: "#9D4EDD")
    static let vaultTeal        = Color(hex: "#00C9A7")
    static let vaultGreen       = Color(hex: "#00D68F")
    static let vaultRed         = Color(hex: "#FF3A5C")
    static let vaultOrange      = Color(hex: "#FF7849")
    static let vaultGold        = Color(hex: "#FFB347")
    static let vaultMuted       = Color(hex: "#6B6B8D")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 3:  (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6:  (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:  (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
