import Foundation
import Observation

@MainActor
@Observable
final class RecipeLibrary {
    private(set) var recipes: [RecipeSummary] = []
    private(set) var isLoading = false
    var lastError: String?

    private var repository: (any RecipeRepository)?
    private var imageCache: [String: Data] = [:]

    func bind(to repository: any RecipeRepository) {
        self.repository = repository
    }

    func refresh() async {
        guard let repository else { return }
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        do {
            recipes = try await repository.listRecipes()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func search(_ query: String) -> [RecipeSummary] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return recipes }
        return recipes.filter {
            $0.name.localizedCaseInsensitiveContains(needle)
                || ($0.description ?? "").localizedCaseInsensitiveContains(needle)
        }
    }

    func detail(for summary: RecipeSummary) async -> Recipe? {
        do {
            return try await repository?.recipe(slug: summary.slug)
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    func save(_ draft: RecipeDraft, replacing recipe: Recipe?) async -> Recipe? {
        guard let repository else { return nil }
        do {
            let saved = try await repository.save(draft.normalized, replacing: recipe)
            let summary = saved.summary
            if let index = recipes.firstIndex(where: { $0.id == summary.id }) {
                recipes[index] = summary
            } else {
                recipes.insert(summary, at: 0)
            }
            imageCache = imageCache.filter { !$0.key.hasPrefix(summary.id.uuidString) }
            return saved
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    func delete(_ summary: RecipeSummary) async -> Bool {
        guard let repository else { return false }
        do {
            try await repository.delete(slug: summary.slug)
            recipes.removeAll { $0.id == summary.id }
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func imageData(for recipe: RecipeSummary, size: RecipeImageSize) async -> Data? {
        guard recipe.hasImage, let repository else { return nil }
        let key = "\(recipe.id.uuidString)-\(size)"
        if let cached = imageCache[key] { return cached }
        do {
            let data = try await repository.imageData(recipeID: recipe.id, size: size)
            imageCache[key] = data
            return data
        } catch {
            return nil
        }
    }
}
