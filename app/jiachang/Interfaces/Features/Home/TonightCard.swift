import SwiftUI

struct TonightCard: View {
    let recipe: RecipeSummary?
    let onShuffle: () -> Void
    @Environment(\.appLanguage) private var language

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let recipe {
                    RecipeArtwork(recipe: recipe, size: .original)
                } else {
                    LinearGradient(
                        colors: [Color(hex: 0xDF663C), Color(hex: 0xA83721)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image("LaunchMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 330)
            LinearGradient(
                colors: [.clear, .black.opacity(0.72)],
                startPoint: .center,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 10) {
                Text(copy(.tonight, language))
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(1.6)
                    .foregroundStyle(.white.opacity(0.74))
                Text(recipe?.localizedName(language) ?? copy(.warmKitchen, language))
                    .font(JiachangFont.display(31))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Button(action: onShuffle) {
                    Label(recipe == nil ? copy(.pick, language) : copy(.pickAgain, language), systemImage: "dice.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.92))
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableCardStyle())
            }
            .padding(22)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.ink.opacity(0.15), radius: 18, y: 10)
    }
}
