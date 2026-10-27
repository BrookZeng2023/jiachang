import SwiftUI
import UIKit

struct ExportResult: Identifiable {
    let id = UUID()
    let url: URL
    let kind: ExportFileStore.Kind
}

struct ShareResultSheet: View {
    let result: ExportResult

    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @State private var preview: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Spacer(minLength: 0)
                if let preview {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .frame(maxHeight: 420)
                } else {
                    fileSummary
                }
                ShareLink(item: result.url) {
                    Label(copy(.shareShare, language), systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("share.send")
                Button(copy(.cookDone, language)) { dismiss() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.muted)
                Spacer(minLength: 0)
            }
            .padding(22)
            .background(Color.cream)
            .navigationTitle(result.kind == .card ? copy(.shareReady, language) : copy(.cookbookReady, language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(copy(.cookClose, language)) { dismiss() }
                }
            }
        }
        .task {
            guard result.kind == .card, let data = try? Data(contentsOf: result.url) else { return }
            preview = UIImage(data: data)
        }
    }

    private var fileSummary: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(Color.persimmon)
            Text(result.url.lastPathComponent)
                .font(JiachangFont.reading(15))
                .foregroundStyle(Color.ink)
            if let size = fileSize {
                Text(size)
                    .font(.footnote)
                    .foregroundStyle(Color.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 46)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var fileSize: String? {
        guard let values = try? result.url.resourceValues(forKeys: [.fileSizeKey]),
              let bytes = values.fileSize else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
