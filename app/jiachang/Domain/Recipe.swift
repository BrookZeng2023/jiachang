import Foundation

struct RecipeTag: Hashable, Identifiable {
    let id: UUID
    var name: String
    var slug: String?
}

struct RecipeIngredient: Hashable, Identifiable {
    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

struct RecipeInstruction: Hashable, Identifiable {
    let id: UUID
    var title: String?
    var text: String

    init(id: UUID = UUID(), title: String? = nil, text: String) {
        self.id = id
        self.title = title
        self.text = text
    }
}

struct RecipeSummary: Hashable, Identifiable {
    let id: UUID
    var name: String
    var slug: String
    var description: String?
    var servings: Double?
    var totalMinutes: Int?
    var imageToken: String?
    var categories: [RecipeTag]
    var tags: [RecipeTag]

    var hasImage: Bool { !(imageToken ?? "").isEmpty }
}

struct Recipe: Hashable, Identifiable {
    let id: UUID
    var name: String
    var slug: String
    var description: String?
    var servings: Double?
    var totalMinutes: Int?
    var imageToken: String?
    var ingredients: [RecipeIngredient]
    var instructions: [RecipeInstruction]
    var categories: [RecipeTag]
    var tags: [RecipeTag]

    var summary: RecipeSummary {
        RecipeSummary(
            id: id,
            name: name,
            slug: slug,
            description: description,
            servings: servings,
            totalMinutes: totalMinutes,
            imageToken: imageToken,
            categories: categories,
            tags: tags
        )
    }
}

struct RecipeDraft {
    var name = ""
    var description = ""
    var servings = 2.0
    var ingredients = [RecipeIngredient(text: "")]
    var instructions = [RecipeInstruction(text: "")]
    var imageData: Data?

    init() {}

    init(recipe: Recipe) {
        name = recipe.name
        description = recipe.description ?? ""
        servings = recipe.servings ?? 2
        ingredients = recipe.ingredients.isEmpty ? [RecipeIngredient(text: "")] : recipe.ingredients
        instructions = recipe.instructions.isEmpty ? [RecipeInstruction(text: "")] : recipe.instructions
    }

    var normalized: RecipeDraft {
        var value = self
        value.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        value.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        value.ingredients = ingredients.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
        value.instructions = instructions.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
        return value
    }
}
