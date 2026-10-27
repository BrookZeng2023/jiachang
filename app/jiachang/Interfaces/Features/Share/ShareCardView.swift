import SwiftUI

/// A 3:4 card, sized by its parent: 360×480 in the renderer, scaled to fit in the preview.
struct ShareCardView: View {
    let content: ShareCardContent

    private var language: AppLanguage { content.language }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            photo
                .frame(maxWidth: .infinity)
                .frame(height: 248)
                .clipped()
            VStack(alignment: .leading, spacing: 9) {
                Text(copy(.shareCardKicker, language))
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.persimmon)
                Text(content.recipe.localizedName(language))
                    .font(JiachangFont.emotional(30))
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                if let description = content.recipe.localizedDescription(language), !description.isEmpty {
                    Text(description)
                        .font(JiachangFont.reading(15))
                        .foregroundStyle(Color.muted)
                        .lineLimit(2)
                        .lineSpacing(4)
                }
                if !content.dedication.isEmpty {
                    dedication
                }
                Spacer(minLength: 6)
                footer
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private var photo: some View {
        if let data = content.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            JiachangTheme.placeholder(for: content.recipe.name)
                .overlay {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                }
        }
    }

    private var dedication: some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle()
                .fill(Color.persimmon)
                .frame(width: 3)
            Text(content.dedication)
                .font(JiachangFont.emotional(17))
                .foregroundStyle(Color.ink)
                .lineSpacing(5)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    private var footer: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("家常 · Jiachang")
                .font(.system(size: 12, design: .serif))
                .tracking(1.4)
                .foregroundStyle(Color.persimmon)
            Spacer()
            Text(KitchenDate.short(Date(), language: language))
                .font(JiachangFont.reading(12))
                .foregroundStyle(Color.muted)
        }
    }
}
