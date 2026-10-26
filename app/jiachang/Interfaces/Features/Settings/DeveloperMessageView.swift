import SwiftUI

struct DeveloperMessageView: View {
    @Environment(\.appLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(copy(.developerMessage, language), systemImage: "heart.text.square")
                .font(AboutTypography.heading)
                .foregroundStyle(Color.terracotta)
                .accessibilityAddTraits(.isHeader)
            Text(copy(.developerMessageBody, language))
                .font(AboutTypography.body)
                .foregroundStyle(Color.ink)
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
