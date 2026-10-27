import Foundation

/// Gathers immutable content for sharing. Only this type touches the library actor;
/// renderers receive plain values.
@MainActor
struct ShareContentLoader {
    let library: RecipeLibrary

    func card(for summary: RecipeSummary, dedication: String, language: AppLanguage) async throws -> ShareCardContent {
        try Task.checkCancellation()
        guard let recipe = await library.detail(for: summary) else { throw SharingError.recipeUnavailable }
        let image = await library.imageData(for: summary)
        try Task.checkCancellation()
        return ShareCardContent(
            recipe: recipe,
            imageData: image,
            dedication: dedication.trimmingCharacters(in: .whitespacesAndNewlines),
            language: language
        )
    }

    func cookbook(
        summaries: [RecipeSummary],
        title: String,
        dedication: String,
        language: AppLanguage
    ) async throws -> CookbookContent {
        guard !summaries.isEmpty else { throw SharingError.emptySelection }
        var items: [CookbookRecipeContent] = []
        items.reserveCapacity(summaries.count)
        for summary in summaries {
            try Task.checkCancellation()
            guard let recipe = await library.detail(for: summary) else { throw SharingError.recipeUnavailable }
            let image = await library.imageData(for: summary)
            let latest = library.entries(for: recipe.id).first
            items.append(CookbookRecipeContent(
                recipe: localized(recipe, language),
                imageData: image,
                latestJournal: latest,
                meta: meta(for: recipe, language: language),
                journalDate: latest.map { KitchenDate.short($0.date, language: language) }
            ))
        }
        return CookbookContent(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            dedication: dedication.trimmingCharacters(in: .whitespacesAndNewlines),
            recipes: items,
            strings: CookbookStrings(
                contents: copy(.cookbookContents, language),
                ingredients: copy(.ingredients, language),
                method: copy(.steps, language),
                latestNote: copy(.cookbookLatestNote, language),
                continued: copy(.cookbookContinued, language),
                brand: "家常 · Jiachang"
            ),
            coverDate: KitchenDate.short(Date(), language: language)
        )
    }

    /// The PDF draws plain strings, so bilingual catalog text is resolved here.
    private func localized(_ recipe: Recipe, _ language: AppLanguage) -> Recipe {
        var value = recipe
        value.name = recipe.localizedName(language)
        value.description = recipe.localizedDescription(language)
        value.ingredients = recipe.ingredients.map {
            RecipeIngredient(id: $0.id, text: $0.localizedText(language))
        }
        value.instructions = recipe.instructions.map {
            RecipeInstruction(id: $0.id, title: $0.localizedTitle(language), text: $0.localizedText(language))
        }
        return value
    }

    private func meta(for recipe: Recipe, language: AppLanguage) -> String {
        var parts: [String] = []
        if let servings = recipe.servings, servings > 0 {
            parts.append(copy(.servings, language, Int(servings)))
        }
        if let minutes = recipe.totalMinutes, minutes > 0 {
            parts.append(copy(.minutes, language, minutes))
        }
        return parts.joined(separator: " · ")
    }
}
