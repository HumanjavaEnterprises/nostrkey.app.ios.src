import SwiftUI

/// NostrKeep teal-on-navy color theme
enum NostrKeepSignerTheme {
    // MARK: - Background
    static let bg = Color("MonokaiBg")              // #0f172a (navy)
    static let bgLight = Color("MonokaiBgLight")    // #1e293b (slate)

    // MARK: - Accent (primary interactive color)
    static let accent = Color("AccentColor")         // #2dd4bf (teal)
    static let accentHover = Color(hex: 0x5eead4)    // Lighter teal

    // MARK: - Semantic Colors
    static let orange = Color("MonokaiOrange")       // #FD971F
    static let red = Color("MonokaiRed")             // #F92672
    static let cyan = Color("MonokaiCyan")           // #66D9EF
    static let brown = Color("MonokaiBrown")         // #8B7355
    static let yellow = Color(hex: 0xE6DB74)         // #E6DB74

    // MARK: - Text
    static let text = Color(hex: 0xF8FAFC)           // #f8fafc
    static let textMuted = Color(hex: 0x94A3B8)      // #94a3b8
}

// MARK: - Hex Color Initializer

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
