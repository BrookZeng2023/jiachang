import UIKit
import XCTest
@testable import jiachang

final class ContentTests: XCTestCase {
    func testShippedCatalogDecodesWithUniqueIDsAndPhotos() throws {
        let directory = Bundle(for: RecipeLibrary.self).bundleURL.appending(path: "Catalog")
        let catalog = try BundledCatalog(directory: directory)

        XCTAssertFalse(catalog.recipes.isEmpty)
        XCTAssertEqual(Set(catalog.recipes.map(\.id)).count, catalog.recipes.count)
        for recipe in catalog.recipes {
            guard case .bundled(let key) = RecipeImageToken(rawValue: recipe.imageToken ?? "") else {
                return XCTFail("\(recipe.name) has no bundled photo token")
            }
            XCTAssertNoThrow(try catalog.imageData(key: key), "missing photo for \(key)")
        }
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

    func testPhotoNormalizerCapsSizeAndRejectsGarbage() throws {
        let normalizer = JPEGPhotoNormalizer(maximumEdge: 100)
        let big = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 200))
        }
        let output = try XCTUnwrap(normalizer.normalize(try XCTUnwrap(big.pngData())))
        let image = try XCTUnwrap(UIImage(data: output))

        XCTAssertEqual(image.size.width, 100, accuracy: 1)
        XCTAssertEqual(image.size.height, 50, accuracy: 1)
        XCTAssertNil(normalizer.normalize(Data("not an image".utf8)))
    }

    func testBilingualContentUsesSelectedLanguageAndKeepsPlainText() {
        XCTAssertEqual("番茄炒蛋 · Tomato and egg stir-fry".localizedContent(.chinese), "番茄炒蛋")
        XCTAssertEqual("番茄炒蛋 · Tomato and egg stir-fry".localizedContent(.english), "Tomato and egg stir-fry")
        XCTAssertEqual("Grandma's soup".localizedContent(.chinese), "Grandma's soup")
    }
}
