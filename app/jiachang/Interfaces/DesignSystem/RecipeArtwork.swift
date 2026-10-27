import SwiftUI

enum RecipeImageSize {
    case thumbnail
    case original
}

struct RecipeArtwork: View {
    let recipe: RecipeSummary
    var size: RecipeImageSize = .thumbnail
    var showsPlaceholder = true

    @Environment(RecipeLibrary.self) private var library
    @State private var imageData: Data?

    // The photo is an overlay so a filled image never widens the container.
    var body: some View {
        JiachangTheme.placeholder(for: recipe.name)
            .overlay {
                if let imageData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                } else if showsPlaceholder {
                    Image("LaunchMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size == .original ? 150 : 96)
                        .opacity(0.92)
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                }
            }
            .clipped()
            .task(id: recipe.imageToken ?? "") {
                imageData = await library.imageData(for: recipe)
            }
    }
}

struct RecipeImageCard: View {
    let recipe: RecipeSummary
    var height: CGFloat = 230
    @Environment(\.appLanguage) private var language

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RecipeArtwork(recipe: recipe)
                .frame(height: height)
                .frame(maxWidth: .infinity)
            LinearGradient(
                colors: [.clear, .black.opacity(0.08), .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 7) {
                Text(recipe.localizedName(language))
                    .font(JiachangFont.emotional(24))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    if let servings = recipe.servings, servings > 0 {
                        Label(copy(.servings, language, Int(servings)), systemImage: "person.2.fill")
                    }
                    if let minutes = recipe.totalMinutes, minutes > 0 {
                        Label(copy(.minutes, language, minutes), systemImage: "clock.fill")
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: JiachangTheme.corner, style: .continuous))
        .shadow(color: Color.ink.opacity(0.12), radius: 14, y: 8)
    }
}
