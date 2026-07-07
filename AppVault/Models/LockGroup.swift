import Foundation
import SwiftUI
import FamilyControls

struct LockGroup: Identifiable, Codable {
    var id = UUID()
    var name: String
    var colorHex: String
    var iconName: String
    var selection: FamilyActivitySelection
    var lockType: LockType
    var pinHash: String?
    var isBiometricEnabled: Bool
    var isActive: Bool
    var createdAt: Date
    var failedAttempts: Int
    var lockedUntil: Date?
    var maxAttempts: Int
    // Minutos até pedir a senha novamente após desbloquear. nil = 5 (padrão).
    var unlockMinutes: Int?
    // Enquanto no futuro, o grupo está temporariamente liberado.
    var unlockedUntil: Date?

    enum LockType: String, Codable, CaseIterable, Identifiable {
        case pin4 = "PIN de 4 Dígitos"
        case pin6 = "PIN de 6 Dígitos"
        case biometric = "Face ID / Touch ID"
        case biometricWithPin = "Face ID + PIN (backup)"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .pin4, .pin6: return "circle.grid.2x2"
            case .biometric: return "faceid"
            case .biometricWithPin: return "lock.shield"
            }
        }
    }

    init(name: String, colorHex: String = "#4361EE", iconName: String = "lock.shield.fill") {
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.selection = FamilyActivitySelection()
        self.lockType = .pin4
        self.isBiometricEnabled = false
        self.isActive = true
        self.createdAt = Date()
        self.failedAttempts = 0
        self.maxAttempts = 5
    }

    var color: Color { Color(hex: colorHex) }
    var appCount: Int { selection.applicationTokens.count }

    var isLocked: Bool {
        guard let until = lockedUntil else { return false }
        return Date() < until
    }

    var unlockDuration: TimeInterval { TimeInterval((unlockMinutes ?? 5) * 60) }

    static let unlockOptions: [Int] = [1, 5, 15, 30, 60]

    static func unlockLabel(_ minutes: Int) -> String {
        minutes < 60 ? "\(minutes) min" : "\(minutes / 60) h"
    }
}

extension LockGroup {
    static let presets: [(name: String, color: String, icon: String)] = [
        ("Redes Sociais", "#E91E8C", "bubble.left.and.bubble.right.fill"),
        ("Jogos", "#FF6B35", "gamecontroller.fill"),
        ("Entretenimento", "#7B2FBE", "play.rectangle.fill"),
        ("Compras", "#06D6A0", "bag.fill"),
        ("Trabalho", "#4361EE", "briefcase.fill"),
        ("Personalizado", "#FF6B6B", "lock.fill"),
    ]
}
