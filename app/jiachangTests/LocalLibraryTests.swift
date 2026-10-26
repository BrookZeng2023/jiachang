import XCTest
@testable import jiachang

final class LocalLibraryTests: XCTestCase {
    private let tomato = UUID()
    private let noodles = UUID()
    private let curry = UUID()
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appending(path: "jiachang-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root.appending(path: "Catalog/images"), withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    func testUserChangesSurviveCatalogUpdate() async throws {
        try writeCatalog([(tomato, "番茄炒蛋 v1"), (noodles, "葱油拌面")])
        let before = makeRepository()
        let original = try await before.recipe(id: tomato)
        var draft = RecipeDraft(recipe: original)
        draft.name = "我的番茄炒蛋"
        draft.imageData = Data("photo".utf8)
        _ = try await before.save(draft, replacing: original)
        try await before.delete(id: noodles)

        try writeCatalog([(tomato, "番茄炒蛋 v2"), (noodles, "葱油拌面"), (curry, "咖喱鸡")])
        let after = makeRepository()
        let recipes = try await after.listRecipes()

        XCTAssertEqual(recipes.map(\.name), ["我的番茄炒蛋", "咖喱鸡"])
        XCTAssertEqual(recipes.first?.origin, .editedBuiltIn)
        let photo = try await after.imageData(token: try XCTUnwrap(recipes.first?.imageToken))
        XCTAssertEqual(photo, Data("photo".utf8))

        let restored = try await after.restoreOriginal(id: tomato)
        XCTAssertEqual(restored.name, "番茄炒蛋 v2")
        try await after.restoreDeletedBuiltIns()
        let count = try await after.listRecipes().count
        XCTAssertEqual(count, 3)
    }

    func testUnreadableLibraryIsSetAsideNotOverwritten() async throws {
        try writeCatalog([(tomato, "番茄炒蛋")])
        let storage = root.appending(path: "Storage")
        try FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: storage.appending(path: "library.json"))

        let recipes = try await makeRepository().listRecipes()

        XCTAssertEqual(recipes.map(\.name), ["番茄炒蛋"])
        let files = try FileManager.default.contentsOfDirectory(atPath: storage.path)
        XCTAssertTrue(files.contains { $0.hasPrefix("library.unreadable-") })
    }

    private func makeRepository() -> LocalRecipeRepository {
        LocalRecipeRepository(
            catalogDirectory: root.appending(path: "Catalog"),
            storageDirectory: root.appending(path: "Storage")
        )
    }

    private func writeCatalog(_ entries: [(UUID, String)]) throws {
        let json = entries.map { id, name in
            ["id": id.uuidString, "key": name, "name": name, "ingredients": ["盐"], "steps": ["炒"]] as [String: Any]
        }
        let data = try JSONSerialization.data(withJSONObject: json)
        try data.write(to: root.appending(path: "Catalog/recipes.json"))
    }
}
