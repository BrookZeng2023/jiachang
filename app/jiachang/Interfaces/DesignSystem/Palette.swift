import SwiftUI

extension Color {
    static let cream = Color(hex: 0xFDF8F0)
    static let paper = Color(hex: 0xFFFDFC)
    static let persimmon = Color(hex: 0xD9542B)
    static let terracotta = Color(hex: 0xB23A20)
    static let sage = Color(hex: 0x5F7F52)
    static let caramel = Color(hex: 0xE8A54B)
    static let ink = Color(hex: 0x2E2420)
    static let muted = Color(hex: 0x8A7A6E)
    static let hairline = Color(hex: 0xEDE3D7)

    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

enum JiachangTheme {
    static let corner: CGFloat = 24
    static let sectionSpacing: CGFloat = 30

    static let placeholderGradients: [LinearGradient] = [
        LinearGradient(colors: [Color(hex: 0xE9683B), .terracotta], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: 0x789866), Color(hex: 0x496841)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: 0xF1B653), Color(hex: 0xD7832F)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: 0x8A657D), Color(hex: 0x5F4259)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: 0xC45A45), Color(hex: 0x89392D)], startPoint: .topLeading, endPoint: .bottomTrailing)
    ]

    static func placeholder(for name: String) -> LinearGradient {
        placeholderGradients[stableIndex(name, count: placeholderGradients.count)]
    }

    private static func stableIndex(_ value: String, count: Int) -> Int {
        value.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) % count }
    }
}
