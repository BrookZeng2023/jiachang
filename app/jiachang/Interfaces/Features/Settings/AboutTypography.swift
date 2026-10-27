import SwiftUI

/// About-page styles built on the app's three-layer typography:
/// WenKai for the headings and the note from the kitchen (feeling),
/// XiHei for the notices (reading).
enum AboutTypography {
    static let title = JiachangFont.emotional(34)
    static let heading = JiachangFont.emotional(22)
    static let body = JiachangFont.reading(17)
    static let note = JiachangFont.reading(14)
    static let lineSpacing: CGFloat = 9
    static let bodyColor = Color.ink.opacity(0.9)
}

struct AboutSectionHeading: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AboutTypography.heading)
            .foregroundStyle(Color.ink)
            .accessibilityAddTraits(.isHeader)
    }
}
