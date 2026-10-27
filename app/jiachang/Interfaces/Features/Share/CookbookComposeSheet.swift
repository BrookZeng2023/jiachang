import SwiftUI

struct CookbookComposeSheet: View {
    let recipes: [RecipeSummary]

    @Environment(SharingService.self) private var sharing
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var dedication = ""
    @State private var result: ExportResult?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(copy(.cookbookTitle, language))
                            .font(JiachangFont.emotional(30))
                            .foregroundStyle(Color.ink)
                        Text(copy(.cookbookRecipeCount, language, recipes.count))
                            .font(JiachangFont.reading(15))
                            .foregroundStyle(Color.muted)
                    }
                    field(copy(.cookbookTitleField, language), text: $title, lines: 1...2, identifier: "cookbook.title")
                    field(copy(.cookbookDedication, language), text: $dedication, lines: 3...6, identifier: "cookbook.dedication")
                    Button { create() } label: {
                        if sharing.isWorking { ProgressView().tint(.white) }
                        else { Text(copy(.cookbookGenerate, language)) }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(sharing.isWorking || recipes.isEmpty)
                    .accessibilityIdentifier("cookbook.generate")
                    if sharing.isWorking {
                        Text(copy(.cookbookGenerating, language))
                            .font(.footnote)
                            .foregroundStyle(Color.muted)
                            .frame(maxWidth: .infinity)
                    } else if sharing.problem != nil {
                        Text(copy(sharing.problem == .emptySelection ? .exportEmpty : .exportFailed, language))
                            .font(.footnote)
                            .foregroundStyle(Color.terracotta)
                    }
                }
                .padding(20)
            }
            .background(Color.cream)
            .navigationTitle(copy(.cookbookTitle, language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(copy(.cancel, language)) { dismiss() }
                }
            }
            .task { if title.isEmpty { title = copy(.cookbookDefaultTitle, language) } }
            .sheet(item: $result) { ShareResultSheet(result: $0) }
        }
    }

    private func field(_ label: String, text: Binding<String>, lines: ClosedRange<Int>, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(JiachangFont.emotional(18))
                .foregroundStyle(Color.ink)
            TextField("", text: text, axis: .vertical)
                .font(JiachangFont.reading(16))
                .lineLimit(lines)
                .padding(14)
                .background(Color.paper)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.hairline) }
                .accessibilityIdentifier(identifier)
        }
    }

    private func create() {
        Task {
            if let url = await sharing.makeCookbook(
                from: recipes,
                title: title,
                dedication: dedication,
                language: language
            ) {
                result = ExportResult(url: url, kind: .cookbook)
            }
        }
    }
}
