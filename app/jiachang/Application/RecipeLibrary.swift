import Foundation
import Observation

@MainActor
@Observable
final class RecipeLibrary {
    enum Problem: Equatable {
        case load
        case save
        case delete
    }

    private(set) var recipes: [RecipeSummary] = []
    private(set) var journal: [JournalEntry] = []
    private(set) var deletedBuiltInCount = 0
    private(set) var isLoaded = false
    private(set) var isLoading = false
    var problem: Problem?

    private let repository: any RecipeRepository & JournalRepository
    private var imageCache: [String: Data] = [:]

    init(repository: any RecipeRepository & JournalRepository) {
        self.repository = repository
    }

    func refresh() async {
        isLoading = true
        defer {
            isLoading = false
            isLoaded = true
        }
        do {
            recipes = try await repository.listRecipes()
            journal = try await repository.journalEntries()
            deletedBuiltInCount = try await repository.deletedBuiltInCount()
            if problem == .load { problem = nil }
        } catch {
            problem = .load
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
            return try await repository.recipe(id: summary.id)
        } catch {
            problem = .load
            return nil
        }
    }

    func save(_ draft: RecipeDraft, replacing recipe: Recipe?) async -> Recipe? {
        problem = nil
        do {
            let saved = try await repository.save(draft.normalized, replacing: recipe)
            await refresh()
            return saved
        } catch {
            problem = .save
            return nil
        }
    }

    /// Keeps the line that travels with a recipe into share cards and cookbooks.
    func saveDedication(_ text: String, for recipe: Recipe) async -> Recipe? {
        var draft = RecipeDraft(recipe: recipe)
        draft.dedication = text
        return await save(draft, replacing: recipe)
    }

    func delete(_ summary: RecipeSummary) async -> Bool {
        problem = nil
        do {
            try await repository.delete(id: summary.id)
            await refresh()
            return true
        } catch {
            problem = .delete
            return false
        }
    }

    func restoreOriginal(_ recipe: Recipe) async -> Recipe? {
        problem = nil
        do {
            let original = try await repository.restoreOriginal(id: recipe.id)
            await refresh()
            return original
        } catch {
            problem = .save
            return nil
        }
    }

    func restoreDeletedBuiltIns() async {
        problem = nil
        do {
            try await repository.restoreDeletedBuiltIns()
            await refresh()
        } catch {
            problem = .save
        }
    }

    func entries(for recipeID: UUID) -> [JournalEntry] {
        journal.filter { $0.recipeID == recipeID }
    }

    func recipeName(for entry: JournalEntry) -> String? {
        recipes.first { $0.id == entry.recipeID }?.name
    }

    func addJournal(_ draft: JournalDraft, to recipeID: UUID) async -> JournalEntry? {
        problem = nil
        do {
            let entry = try await repository.addJournal(draft, to: recipeID)
            await refresh()
            return entry
        } catch {
            problem = .save
            return nil
        }
    }

    func deleteJournal(_ entry: JournalEntry) async -> Bool {
        problem = nil
        do {
            try await repository.deleteJournal(id: entry.id)
            await refresh()
            return true
        } catch {
            problem = .delete
            return false
        }
    }

    func imageData(for recipe: RecipeSummary) async -> Data? {
        await imageData(token: recipe.imageToken)
    }

    func imageData(for entry: JournalEntry) async -> Data? {
        await imageData(token: entry.imageToken)
    }

    private func imageData(token: String?) async -> Data? {
        guard let token, !token.isEmpty else { return nil }
        if let cached = imageCache[token] { return cached }
        guard let data = try? await repository.imageData(token: token) else { return nil }
        imageCache[token] = data
        return data
    }
}
