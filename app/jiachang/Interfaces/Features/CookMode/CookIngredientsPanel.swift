import SwiftUI

@MainActor
struct CookIngredientsPanel: View {
    let session: CookingSession
    @Environment(\.appLanguage) private var language
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(copy(.ingredients, language), isExpanded: $isExpanded) {
            if session.recipe.ingredients.isEmpty {
                Text(copy(.cookNoIngredients, language))
                    .foregroundStyle(Color.muted)
                    .padding(.vertical, 12)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(session.recipe.ingredients) { ingredient in
                        let checked = session.checkedIngredients.contains(ingredient.id)
                        Button {
                            session.toggleIngredient(ingredient.id)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Color.persimmon)
                                Text(ingredient.localizedText(language))
                                    .font(JiachangFont.reading(18))
                                    .foregroundStyle(checked ? Color.muted : Color.ink)
                                    .strikethrough(checked)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(checked ? .isSelected : [])
                    }
                }
            }
        }
        .padding(18)
        .background(Color.paper, in: RoundedRectangle(cornerRadius: 20))
    }
}
