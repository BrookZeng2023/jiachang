import Foundation

/// On-disk overlay: edited built-ins and personal recipes, deleted built-in ids and journal entries.
/// Version 2 added `journalEntries`; version 1 files load unchanged with an empty journal.
struct LocalLibraryDTO: Codable, Equatable {
    static let currentVersion = 2

    var version = currentVersion
    var recipes: [LocalRecipeDTO] = []
    var deletedBuiltInIDs: [UUID] = []
    var journalEntries: [LocalJournalDTO] = []
}

extension LocalLibraryDTO {
    // Missing keys fall back to defaults so adding a field never makes an older file unreadable.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        recipes = try container.decodeIfPresent([LocalRecipeDTO].self, forKey: .recipes) ?? []
        deletedBuiltInIDs = try container.decodeIfPresent([UUID].self, forKey: .deletedBuiltInIDs) ?? []
        journalEntries = try container.decodeIfPresent([LocalJournalDTO].self, forKey: .journalEntries) ?? []
    }
}

struct LocalJournalDTO: Codable, Equatable {
    var id: UUID
    var recipeID: UUID
    var date: Date
    var note: String
    var cookedFor: String?
    var imageToken: String?

    init(id: UUID, recipeID: UUID, draft: JournalDraft, imageToken: String?) {
        self.id = id
        self.recipeID = recipeID
        date = draft.date
        note = draft.note
        cookedFor = draft.cookedFor.isEmpty ? nil : draft.cookedFor
        self.imageToken = imageToken
    }

    var domain: JournalEntry {
        JournalEntry(id: id, recipeID: recipeID, date: date, note: note, cookedFor: cookedFor, imageToken: imageToken)
    }
}

struct LocalRecipeDTO: Codable, Equatable {
    struct Step: Codable, Equatable {
        var title: String?
        var text: String
    }

    var id: UUID
    var name: String
    var description: String?
    var servings: Double?
    var totalMinutes: Int?
    var imageToken: String?
    var ingredients: [String]
    var steps: [Step]
    var updatedAt: Date

    init(id: UUID, draft: RecipeDraft, totalMinutes: Int?, imageToken: String?, updatedAt: Date) {
        self.id = id
        name = draft.name
        description = draft.description.isEmpty ? nil : draft.description
        servings = draft.servings > 0 ? draft.servings : nil
        self.totalMinutes = totalMinutes
        self.imageToken = imageToken
        ingredients = draft.ingredients.map(\.text)
        steps = draft.instructions.map { Step(title: $0.title, text: $0.text) }
        self.updatedAt = updatedAt
    }

    func domain(origin: RecipeOrigin) -> Recipe {
        Recipe(
            id: id,
            name: name,
            description: description,
            servings: servings,
            totalMinutes: totalMinutes,
            imageToken: imageToken,
            ingredients: ingredients.map { RecipeIngredient(text: $0) },
            instructions: steps.map { RecipeInstruction(title: $0.title, text: $0.text) },
            origin: origin
        )
    }
}
