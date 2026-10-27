import SwiftUI

struct DeveloperMessageView: View {
    @Environment(\.appLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("A NOTE FROM THE KITCHEN")
                .font(.system(.caption, design: .serif))
                .tracking(1.8)
                .foregroundStyle(Color.persimmon)
            Text(copy(.developerMessage, language))
                .font(AboutTypography.heading)
                .foregroundStyle(Color.ink)
                .accessibilityAddTraits(.isHeader)
            Text(copy(.developerMessageBody, language))
                .font(JiachangFont.emotional(18))
                .foregroundStyle(AboutTypography.bodyColor)
                .lineSpacing(AboutTypography.lineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}
