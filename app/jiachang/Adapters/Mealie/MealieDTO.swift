import Foundation

struct MealieTagDTO: Codable {
    var id: UUID?
    var name: String
    var slug: String?

    var domain: RecipeTag {
        RecipeTag(id: id ?? UUID(), name: name, slug: slug)
    }
}

struct MealieIngredientDTO: Codable {
    var note: String?
    var display: String?
    var food: MealieTagDTO?

    var domain: RecipeIngredient {
        RecipeIngredient(text: display?.nonEmpty ?? note?.nonEmpty ?? food?.name ?? "")
    }
}

struct MealieInstructionDTO: Codable {
    var title: String?
    var text: String?

    var domain: RecipeInstruction {
        RecipeInstruction(title: title?.nonEmpty, text: text ?? "")
    }
}

struct MealieRecipeDTO: Decodable {
    let id: UUID
    var name: String
    var slug: String
    var description: String?
    var recipeServings: Double?
    var totalTime: Int?
    var image: String?
    var recipeIngredient: [MealieIngredientDTO]?
    var recipeInstructions: [MealieInstructionDTO]?
    var recipeCategory: [MealieTagDTO]?
    var tags: [MealieTagDTO]?

    private enum CodingKeys: String, CodingKey {
        case id, name, slug, description, recipeServings, totalTime, image
        case recipeIngredient, recipeInstructions, recipeCategory, tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        slug = try container.decode(String.self, forKey: .slug)
        description = try? container.decode(String.self, forKey: .description)
        recipeServings = try? container.decode(Double.self, forKey: .recipeServings)
        image = try? container.decode(String.self, forKey: .image)
        recipeIngredient = try? container.decode([MealieIngredientDTO].self, forKey: .recipeIngredient)
        recipeInstructions = try? container.decode([MealieInstructionDTO].self, forKey: .recipeInstructions)
        recipeCategory = try? container.decode([MealieTagDTO].self, forKey: .recipeCategory)
        tags = try? container.decode([MealieTagDTO].self, forKey: .tags)
        if let minutes = try? container.decode(Int.self, forKey: .totalTime) {
            totalTime = minutes
        } else if let value = try? container.decode(String.self, forKey: .totalTime) {
            totalTime = Int(value)
        } else {
            totalTime = nil
        }
    }

    var summary: RecipeSummary {
        RecipeSummary(
            id: id,
            name: name,
            slug: slug,
            description: description?.nonEmpty,
            servings: recipeServings,
            totalMinutes: totalTime,
            imageToken: image?.nonEmpty,
            categories: (recipeCategory ?? []).map(\.domain),
            tags: (tags ?? []).map(\.domain)
        )
    }

    var domain: Recipe {
        Recipe(
            id: id,
            name: name,
            slug: slug,
            description: description?.nonEmpty,
            servings: recipeServings,
            totalMinutes: totalTime,
            imageToken: image?.nonEmpty,
            ingredients: (recipeIngredient ?? []).map(\.domain),
            instructions: (recipeInstructions ?? []).map(\.domain),
            categories: (recipeCategory ?? []).map(\.domain),
            tags: (tags ?? []).map(\.domain)
        )
    }
}

struct MealiePageDTO<T: Decodable>: Decodable {
    var items: [T]
}

struct MealieLoginDTO: Decodable {
    var access_token: String
}

struct CreateRecipeDTO: Encodable {
    var name: String
}

struct PatchRecipeDTO: Encodable {
    struct Ingredient: Encodable { var note: String }
    struct Instruction: Encodable { var title: String?; var text: String }

    var name: String?
    var description: String?
    var recipeServings: Double?
    var recipeIngredient: [Ingredient]
    var recipeInstructions: [Instruction]

    init(draft: RecipeDraft, isNew: Bool) {
        name = isNew ? nil : draft.name
        description = draft.description.nonEmpty
        recipeServings = draft.servings > 0 ? draft.servings : nil
        recipeIngredient = draft.ingredients.map { Ingredient(note: $0.text) }
        recipeInstructions = draft.instructions.map { Instruction(title: $0.title?.nonEmpty, text: $0.text) }
    }
}

private extension Optional where Wrapped == String {
    var nonEmpty: String? {
        guard let self, !self.isEmpty else { return nil }
        return self
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
