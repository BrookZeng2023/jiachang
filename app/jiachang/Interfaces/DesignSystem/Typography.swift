import SwiftUI

/// Three-layer typography: WenKai carries feeling (names, dates, stories),
/// XiHei carries reading (ingredients, steps, prose), and the system font
/// carries controls (buttons, navigation, tab bar).
enum JiachangFont {
    /// Emotional layer: recipe names, story headings, dates, greetings, notes from the kitchen.
    static func emotional(_ size: CGFloat) -> Font {
        .custom("JiachangKai-Medium", size: size, relativeTo: .title)
    }

    /// Reading layer: body prose, ingredients, steps, remarks.
    static func reading(_ size: CGFloat) -> Font {
        .custom("JiachangHei-Regular", size: size, relativeTo: .body)
    }
}

struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(configuration.isPressed ? Color.ink.opacity(0.8) : Color.persimmon)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
