import SwiftUI

struct JournalCard: View {
    let entry: JournalEntry
    let recipe: RecipeSummary?
    var compact = false

    @Environment(RecipeLibrary.self) private var library
    @Environment(\.appLanguage) private var language
    @State private var imageData: Data?

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(KitchenDate.short(entry.date, language: language))
                .font(JiachangFont.emotional(16))
                .foregroundStyle(Color.persimmon)
            if entry.hasImage || (!compact && recipe?.hasImage == true) {
                artwork
                    .frame(height: compact ? 180 : 240)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            if !compact, let recipe {
                Text(recipe.localizedName(language))
                    .font(JiachangFont.emotional(27))
                    .foregroundStyle(Color.ink)
            }
            if let cookedFor = entry.cookedFor, !cookedFor.isEmpty {
                Text(copy(.journalForPerson, language, cookedFor))
                    .font(JiachangFont.emotional(17))
                    .foregroundStyle(Color.muted)
            }
            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(JiachangFont.emotional(18))
                    .foregroundStyle(Color.ink)
                    .lineSpacing(7)
                    .lineLimit(compact ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .task(id: entry.imageToken) { imageData = await library.imageData(for: entry) }
    }

    @ViewBuilder
    private var artwork: some View {
        if let imageData, let image = UIImage(data: imageData) {
            Color.cream.overlay { Image(uiImage: image).resizable().scaledToFill() }.clipped()
        } else if let recipe {
            RecipeArtwork(recipe: recipe, size: .original)
        } else {
            Color.cream
        }
    }
}
