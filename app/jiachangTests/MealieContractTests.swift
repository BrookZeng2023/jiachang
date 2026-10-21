import XCTest
@testable import jiachang

final class MealieContractTests: XCTestCase {
    func testRecipeDecodingToleratesMissingOptionalCollections() throws {
        let json = #"{"id":"e5e4df36-f682-4dc0-9933-14ddc5fcafc9","name":"番茄炒蛋","slug":"fan-qie-chao-dan","totalTime":"15"}"#.data(using: .utf8)!
        let recipe = try JSONDecoder().decode(MealieRecipeDTO.self, from: json).domain

        XCTAssertEqual(recipe.name, "番茄炒蛋")
        XCTAssertEqual(recipe.totalMinutes, 15)
        XCTAssertTrue(recipe.ingredients.isEmpty)
        XCTAssertTrue(recipe.instructions.isEmpty)
    }

    func testDraftNormalizationDropsBlankRows() {
        var draft = RecipeDraft()
        draft.name = "  红烧肉  "
        draft.ingredients = [RecipeIngredient(text: "五花肉"), RecipeIngredient(text: "  ")]
        draft.instructions = [RecipeInstruction(text: "焯水"), RecipeInstruction(text: "")]

        let normalized = draft.normalized
        XCTAssertEqual(normalized.name, "红烧肉")
        XCTAssertEqual(normalized.ingredients.map(\.text), ["五花肉"])
        XCTAssertEqual(normalized.instructions.map(\.text), ["焯水"])
    }

    func testBilingualContentUsesSelectedLanguageAndKeepsPlainText() {
        XCTAssertEqual("番茄炒蛋 · Tomato and egg stir-fry".localizedContent(.chinese), "番茄炒蛋")
        XCTAssertEqual("番茄炒蛋 · Tomato and egg stir-fry".localizedContent(.english), "Tomato and egg stir-fry")
        XCTAssertEqual("Grandma's soup".localizedContent(.chinese), "Grandma's soup")
    }
}
