import SwiftUI

struct AboutNoticesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            AboutNoticeSection(title: .privacyTitle, paragraphs: [
                .privacyLocalBody, .privacyBackupBody, .privacyTransferBody
            ])
            AboutNoticeSection(title: .permissionsTitle, paragraphs: [
                .cameraPermissionBody, .photoPermissionBody
            ])
            AboutNoticeSection(title: .foodSafetyTitle, paragraphs: [.foodSafetyBody])
            AboutNoticeSection(title: .licensesTitle, paragraphs: [
                .starterContentBody, .softwareLicenseBody, .userPhotosBody
            ])
        }
    }
}

private struct AboutNoticeSection: View {
    let title: CopyKey
    let paragraphs: [CopyKey]
    @Environment(\.appLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AboutSectionHeading(title: copy(title, language))
            ForEach(paragraphs, id: \.rawValue) { paragraph in
                Text(copy(paragraph, language))
                    .font(AboutTypography.body)
                    .foregroundStyle(Color.ink.opacity(0.85))
                    .lineSpacing(AboutTypography.lineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
