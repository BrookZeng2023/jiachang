import Foundation

/// Built-in recipes ship with each release; the user's edits, deletions and
/// own recipes are layered on top and always win over a newer catalog.
protocol RecipeRepository {
    func listRecipes() async throws -> [RecipeSummary]
    func recipe(id: UUID) async throws -> Recipe
    func save(_ draft: RecipeDraft, replacing recipe: Recipe?) async throws -> Recipe
    func delete(id: UUID) async throws
    func restoreOriginal(id: UUID) async throws -> Recipe
    func deletedBuiltInCount() async throws -> Int
    func restoreDeletedBuiltIns() async throws
    func imageData(token: String) async throws -> Data
}

enum CameraAvailability: Equatable {
    case ready
    case denied
    case unavailable
}

/// Asks the system for camera access; the UI never touches permission APIs directly.
protocol CameraAccess {
    func requestAccess() async -> CameraAvailability
}

/// Shrinks and re-encodes a picked or captured photo before it is stored.
protocol PhotoNormalizer {
    func normalize(_ data: Data) -> Data?
}
