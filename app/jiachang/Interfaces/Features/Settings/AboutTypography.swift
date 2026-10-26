import SwiftUI

/// Quiet, scalable sans-serif typography for long-form app information.
enum AboutTypography {
    static let title = Font.system(.largeTitle, design: .default, weight: .semibold)
    static let heading = Font.system(.headline, design: .default, weight: .medium)
    static let body = Font.system(.body, design: .default, weight: .regular)
    static let lineSpacing: CGFloat = 7
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
