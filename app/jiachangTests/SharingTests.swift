import CoreGraphics
import UIKit
import XCTest
@testable import jiachang

@MainActor
final class SharingTests: XCTestCase {
    override func setUp() {
        super.setUp()
        BundledFontRegistrar(directory: Bundle(for: RecipeLibrary.self).bundleURL.appending(path: "Fonts"))
            .registerAll()
    }

    func testLoaderRejectsEmptySelection() async {
        let loader = ShareContentLoader(library: await makeLibrary())
        do {
            _ = try await loader.cookbook(summaries: [], title: "t", dedication: "", language: .chinese)
            XCTFail("expected emptySelection")
        } catch let error as SharingError {
            XCTAssertEqual(error, .emptySelection)
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    func testLoaderReportsMissingRecipe() async {
        let library = await makeLibrary()
        let loader = ShareContentLoader(library: library)
        let missing = RecipeSummary(
            id: UUID(), name: "不存在", description: nil, servings: nil,
            totalMinutes: nil, imageToken: nil, origin: .personal
        )
        do {
            _ = try await loader.card(for: missing, dedication: "", language: .chinese)
            XCTFail("expected recipeUnavailable")
        } catch let error as SharingError {
            XCTAssertEqual(error, .recipeUnavailable)
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    func testCookbookCarriesLocalizedMetaAndLatestJournal() async throws {
        let recipe = makeRecipe()
        let entry = JournalEntry(
            id: UUID(), recipeID: recipe.id, date: Date(), note: "少放了一点盐",
            cookedFor: "妈妈", imageToken: nil
        )
        let library = await makeLibrary(recipes: [recipe], journal: [entry])
        let loader = ShareContentLoader(library: library)
        let content = try await loader.cookbook(
            summaries: [recipe.summary], title: "我家的菜谱", dedication: "给妈妈", language: .chinese
        )

        XCTAssertEqual(content.recipes.first?.recipe.name, "番茄炒蛋")
        XCTAssertEqual(content.recipes.first?.latestJournal?.note, "少放了一点盐")
        XCTAssertTrue(content.recipes.first?.meta.contains("2 人份") == true)
        XCTAssertFalse(content.recipes.first?.journalDate?.isEmpty ?? true)
    }

    func testShareCardRendersFullSizePNG() throws {
        let content = ShareCardContent(
            recipe: makeRecipe(), imageData: nil, dedication: "给晚归的人", language: .chinese
        )
        let data = try ShareCardRenderer().pngData(for: content)
        let image = try XCTUnwrap(UIImage(data: data))
        XCTAssertGreaterThan(data.count, 10_000)
        XCTAssertEqual(image.cgImage?.width, 1080)
        XCTAssertEqual(image.cgImage?.height, 1440)
    }

    func testCookbookPDFHasCoverContentsAndRecipePage() throws {
        let data = try CookbookPDFWriter().pdfData(for: makeCookbook(count: 1))
        XCTAssertEqual(String(decoding: data.prefix(5), as: UTF8.self), "%PDF-")
        let document = try XCTUnwrap(CGPDFDocument(CGDataProvider(data: data as CFData)!))
        XCTAssertEqual(document.numberOfPages, 3)
        let box = try XCTUnwrap(document.page(at: 1)).getBoxRect(.mediaBox)
        XCTAssertEqual(box.width, 595.2, accuracy: 0.5)
        XCTAssertEqual(box.height, 841.8, accuracy: 0.5)
        XCTAssertLessThan(data.count, 12_000_000)
    }

    func testCookbookPDFGrowsWithRecipes() throws {
        let document = try XCTUnwrap(CGPDFDocument(CGDataProvider(
            data: try CookbookPDFWriter().pdfData(for: makeCookbook(count: 3)) as CFData
        )!))
        XCTAssertGreaterThanOrEqual(document.numberOfPages, 5)
    }

    func testCookbookPDFRejectsEmptySelection() {
        XCTAssertThrowsError(try CookbookPDFWriter().pdfData(for: makeCookbook(count: 0))) {
            XCTAssertEqual($0 as? SharingError, .emptySelection)
        }
    }

    func testExportStoreWritesAndPrunesOldFiles() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "export-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ExportFileStore(directory: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let stale = directory.appending(path: "yesterday.png")
        try Data("old".utf8).write(to: stale)
        try FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(-3 * 86_400)],
            ofItemAtPath: stale.path
        )

        let fresh = try store.store(Data("new".utf8), kind: .cookbook)

        XCTAssertTrue(FileManager.default.fileExists(atPath: fresh.path))
        XCTAssertEqual(fresh.pathExtension, "pdf")
        XCTAssertFalse(FileManager.default.fileExists(atPath: stale.path), "exports older than a day are cleared")
    }

    private func makeLibrary(recipes: [Recipe] = [], journal: [JournalEntry] = []) async -> RecipeLibrary {
        let repository = StubRepository()
        repository.recipes = Dictionary(uniqueKeysWithValues: recipes.map { ($0.id, $0) })
        repository.journal = journal
        let library = RecipeLibrary(repository: repository)
        await library.refresh()
        return library
    }

    private func makeRecipe(name: String = "番茄炒蛋 · Tomato and Egg") -> Recipe {
        Recipe(
            id: UUID(),
            name: name,
            description: "酸甜鲜嫩 · Sweet and tender",
            dedication: nil,
            servings: 2,
            totalMinutes: 15,
            imageToken: nil,
            ingredients: [
                RecipeIngredient(text: "番茄 3 个 · 3 tomatoes"),
                RecipeIngredient(text: "鸡蛋 4 个 · 4 eggs")
            ],
            instructions: [
                RecipeInstruction(text: "打蛋 · Beat the eggs"),
                RecipeInstruction(text: "炒熟 · Stir-fry until set")
            ],
            origin: .personal
        )
    }

    private func makeCookbook(count: Int) -> CookbookContent {
        let items = (0..<count).map { index in
            CookbookRecipeContent(
                recipe: makeRecipe(name: "第 \(index + 1) 道菜"),
                imageData: nil,
                latestJournal: nil,
                meta: "2 人份",
                journalDate: nil
            )
        }
        return CookbookContent(
            title: "我家的菜谱",
            dedication: "给翻开它的人",
            recipes: items,
            strings: CookbookStrings(
                contents: "目录", ingredients: "食材", method: "做法",
                latestNote: "最近一次", continued: "续", brand: "家常 · Jiachang"
            ),
            coverDate: "十月二十七"
        )
    }
}

private final class StubRepository: RecipeRepository, JournalRepository {
    var recipes: [UUID: Recipe] = [:]
    var journal: [JournalEntry] = []

    func listRecipes() async throws -> [RecipeSummary] { recipes.values.map(\.summary) }

    func recipe(id: UUID) async throws -> Recipe {
        guard let recipe = recipes[id] else { throw LocalLibraryError.recipeNotFound }
        return recipe
    }

    func save(_ draft: RecipeDraft, replacing recipe: Recipe?) async throws -> Recipe {
        throw LocalLibraryError.notBuiltIn
    }

    func delete(id: UUID) async throws {}

    func restoreOriginal(id: UUID) async throws -> Recipe {
        throw LocalLibraryError.notBuiltIn
    }

    func deletedBuiltInCount() async throws -> Int { 0 }

    func restoreDeletedBuiltIns() async throws {}

    func imageData(token: String) async throws -> Data {
        throw LocalLibraryError.recipeNotFound
    }

    func journalEntries() async throws -> [JournalEntry] { journal }

    func addJournal(_ draft: JournalDraft, to recipeID: UUID) async throws -> JournalEntry {
        throw LocalLibraryError.recipeNotFound
    }

    func deleteJournal(id: UUID) async throws {}
}

