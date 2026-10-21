import Foundation

enum RecipeImageSize {
    case thumbnail
    case original
}

protocol RecipeRepository {
    func listRecipes() async throws -> [RecipeSummary]
    func recipe(slug: String) async throws -> Recipe
    func save(_ draft: RecipeDraft, replacing recipe: Recipe?) async throws -> Recipe
    func delete(slug: String) async throws
    func imageData(recipeID: UUID, size: RecipeImageSize) async throws -> Data
}

struct Credentials: Equatable {
    var server: String
    var username: String
    var password: String

    var isComplete: Bool {
        !server.trimmingCharacters(in: .whitespaces).isEmpty
            && !username.isEmpty
            && !password.isEmpty
    }
}

protocol CredentialsStore {
    func load() -> Credentials
    func save(_ credentials: Credentials)
}

protocol SessionGateway {
    func connect(using credentials: Credentials) async throws -> any RecipeRepository
}
