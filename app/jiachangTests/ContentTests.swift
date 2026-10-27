import CoreText
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

    func testBundledFontsCoverEveryInterfaceString() throws {
        let registrar = BundledFontRegistrar(directory: Bundle(for: RecipeLibrary.self).bundleURL.appending(path: "Fonts"))
        let registered = Set(registrar.registerAll())
        XCTAssertEqual(registered, Set(["JiachangKai-Regular.ttf", "JiachangKai-Medium.ttf", "JiachangHei-Regular.ttf"]))

        // Either layer may render any string, so both fonts must cover all of them.
        for postScriptName in ["JiachangKai-Medium", "JiachangHei-Regular"] {
            let font = CTFontCreateWithName(postScriptName as CFString, 17, nil)
            XCTAssertEqual(CTFontCopyPostScriptName(font) as String, postScriptName)
            for language in AppLanguage.allCases {
                guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
                      let bundle = Bundle(path: path) else { return XCTFail("missing lproj for \(language)") }
                for key in CopyKey.allCases {
                    let text = bundle.localizedString(forKey: key.rawValue, value: "", table: nil)
                    XCTAssertFalse(text.isEmpty, "\(key.rawValue) is empty in \(language.rawValue)")
                    for character in text where !character.isASCII {
                        let units = Array(character.utf16)
                        var glyphs = [CGGlyph](repeating: 0, count: units.count)
                        XCTAssertTrue(
                            CTFontGetGlyphsForCharacters(font, units, &glyphs, units.count),
                            "\(postScriptName) is missing a glyph for \(character) in \(key.rawValue)"
                        )
                    }
                }
            }
        }
    }

    func testBilingualContentUsesSelectedLanguageAndKeepsPlainText() {
        XCTAssertEqual("番茄炒蛋 · Tomato and egg stir-fry".localizedContent(.chinese), "番茄炒蛋")
        XCTAssertEqual("番茄炒蛋 · Tomato and egg stir-fry".localizedContent(.english), "Tomato and egg stir-fry")
        XCTAssertEqual("Grandma's soup".localizedContent(.chinese), "Grandma's soup")
    }
}
