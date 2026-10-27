import SwiftUI

struct ShareRecipeSheet: View {
    let recipe: Recipe

    @Environment(RecipeLibrary.self) private var library
    @Environment(SharingService.self) private var sharing
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @State private var dedication: String
    @State private var imageData: Data?
    @State private var result: ExportResult?

    init(recipe: Recipe) {
        self.recipe = recipe
        _dedication = State(initialValue: recipe.dedication ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ShareCardView(content: preview)
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .frame(maxWidth: 360)
                        .frame(maxWidth: .infinity)
                        .shadow(color: Color.ink.opacity(0.12), radius: 16, y: 8)
                    editor
                    Button { create() } label: {
                        if sharing.isWorking { ProgressView().tint(.white) }
                        else { Text(copy(.shareSaveAndCreate, language)) }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(sharing.isWorking)
                    .accessibilityIdentifier("share.create")
                    if sharing.isWorking {
                        Text(copy(.shareGenerating, language))
                            .font(.footnote)
                            .foregroundStyle(Color.muted)
                            .frame(maxWidth: .infinity)
                    } else if sharing.problem != nil {
                        Text(copy(sharing.problem == .fileFailed ? .exportFailed : .shareFailed, language))
                            .font(.footnote)
                            .foregroundStyle(Color.terracotta)
                    }
                }
                .padding(20)
                .padding(.bottom, 12)
            }
            .background(Color.cream)
            .navigationTitle(copy(.shareDish, language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(copy(.cancel, language)) { dismiss() }
                }
            }
            .task { imageData = await library.imageData(for: recipe.summary) }
            .sheet(item: $result) { ShareResultSheet(result: $0) }
        }
    }

    private var preview: ShareCardContent {
        ShareCardContent(
            recipe: recipe,
            imageData: imageData,
            dedication: dedication.trimmingCharacters(in: .whitespacesAndNewlines),
            language: language
        )
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(copy(.shareDedication, language))
                .font(JiachangFont.emotional(19))
                .foregroundStyle(Color.ink)
            TextField(copy(.shareDedicationHint, language), text: $dedication, axis: .vertical)
                .font(JiachangFont.reading(16))
                .lineLimit(2...4)
                .padding(14)
                .background(Color.paper)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.hairline) }
                .accessibilityIdentifier("share.dedication")
        }
    }

    private func create() {
        Task {
            if let url = await sharing.makeCard(for: recipe.summary, dedication: dedication, language: language) {
                result = ExportResult(url: url, kind: .card)
            }
        }
    }
}
