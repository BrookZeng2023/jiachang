import Foundation

/// The read-only starter recipes shipped inside the app bundle.
struct BundledCatalog {
    let recipes: [Recipe]
    private let directory: URL

    init(directory: URL) throws {
        self.directory = directory
        let data = try Data(contentsOf: directory.appending(path: "recipes.json"))
        recipes = try JSONDecoder().decode([BundledRecipeDTO].self, from: data).map(\.domain)
    }

    func imageData(key: String) throws -> Data {
        try Data(contentsOf: directory.appending(path: "images/\(key).jpg"))
    }
}

private struct BundledRecipeDTO: Decodable {
    let id: UUID
    let key: String
    let name: String
    let description: String?
    let servings: Double?
    let total_minutes: Int?
    let ingredients: [String]
    let steps: [String]

    var domain: Recipe {
        Recipe(
            id: id,
            name: name,
            description: description,
            servings: servings,
            totalMinutes: total_minutes,
            imageToken: RecipeImageToken.bundled(key).rawValue,
            ingredients: ingredients.map { RecipeIngredient(text: $0) },
            instructions: steps.map { RecipeInstruction(text: $0) },
            origin: .builtIn
        )
    }
}
