import Foundation

struct MealieSessionGateway: SessionGateway {
    func connect(using credentials: Credentials) async throws -> any RecipeRepository {
        guard let url = normalizedURL(credentials.server) else {
            throw MealieAPIError.invalidServer
        }
        let token = try await MealieAPIClient(baseURL: url).login(
            username: credentials.username,
            password: credentials.password
        )
        return MealieRecipeRepository(client: MealieAPIClient(baseURL: url, token: token))
    }

    private func normalizedURL(_ value: String) -> URL? {
        var text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.hasPrefix("http://") && !text.hasPrefix("https://") {
            text = "http://" + text
        }
        return URL(string: text)
    }
}

struct MealieRecipeRepository: RecipeRepository {
    let client: MealieAPIClient

    func listRecipes() async throws -> [RecipeSummary] {
        var recipes: [RecipeSummary] = []
        var page = 1
        while page <= 20 {
            let result: MealiePageDTO<MealieRecipeDTO> = try await client.send(
                "/api/recipes?orderBy=dateUpdated&orderDirection=desc&page=\(page)&perPage=100"
            )
            recipes.append(contentsOf: result.items.map(\.summary))
            if result.items.count < 100 { break }
            page += 1
        }
        return recipes
    }

    func recipe(slug: String) async throws -> Recipe {
        let dto: MealieRecipeDTO = try await client.send("/api/recipes/\(slug)")
        return dto.domain
    }

    func save(_ draft: RecipeDraft, replacing recipe: Recipe?) async throws -> Recipe {
        let slug: String
        if let recipe {
            slug = recipe.slug
        } else {
            slug = try await client.send(
                "/api/recipes",
                method: "POST",
                body: CreateRecipeDTO(name: draft.name)
            )
        }
        let dto: MealieRecipeDTO = try await client.send(
            "/api/recipes/\(slug)",
            method: "PATCH",
            body: PatchRecipeDTO(draft: draft, isNew: recipe == nil)
        )
        if let imageData = draft.imageData {
            try await client.uploadImage(slug: slug, jpeg: imageData)
            return try await self.recipe(slug: slug)
        }
        return dto.domain
    }

    func delete(slug: String) async throws {
        try await client.sendVoid("/api/recipes/\(slug)", method: "DELETE")
    }

    func imageData(recipeID: UUID, size: RecipeImageSize) async throws -> Data {
        let filename = size == .thumbnail ? "min-original.webp" : "original.webp"
        return try await client.raw("/api/media/recipes/\(recipeID.uuidString)/images/\(filename)")
    }
}
