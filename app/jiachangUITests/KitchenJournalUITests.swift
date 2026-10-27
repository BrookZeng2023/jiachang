import XCTest

/// One key UI contract: a new cooking entry survives relaunch and leads back to its recipe.
/// Runs only on a simulator so test entries are never added to the user's phone.
final class KitchenJournalUITests: XCTestCase {
    @MainActor
    func testJournalPersistsAndCookingModeOpens() throws {
        #if !targetEnvironment(simulator)
        throw XCTSkip("UI smoke creates a temporary journal entry; simulator only")
        #endif
        continueAfterFailure = false
        let app = XCUIApplication()
        let note = "Kitchen smoke \(UUID().uuidString.prefix(8))"
        app.launchArguments = ["-appLanguage", "zh-Hans", "-jcOpen", "02017C74-8647-421C-B56B-707066090623"]
        app.launch()
        let newPage = app.buttons["journal.new"]
        XCTAssertTrue(newPage.waitForExistence(timeout: 15))
        scrollTo(newPage, in: app)
        newPage.tap()

        let editor = app.descendants(matching: .any).matching(identifier: "journal.note").firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText(note)
        app.buttons["journal.finishEditing"].tap()
        let save = app.buttons["journal.save"]
        scrollTo(save, in: app)
        save.tap()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: save)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 10), .completed)
        app.terminate()

        app.launchArguments = ["-appLanguage", "zh-Hans"]
        app.launch()
        XCTAssertTrue(app.staticTexts[note].waitForExistence(timeout: 15))
        app.staticTexts[note].tap()
        let cook = app.buttons["recipe.startCooking"]
        XCTAssertTrue(cook.waitForExistence(timeout: 5))
        scrollTo(cook, in: app)
        cook.tap()
        XCTAssertTrue(app.navigationBars["烹饪模式"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["下一步"].exists)
        app.buttons["下一步"].tap()
        XCTAssertTrue(app.staticTexts["第 2 步，共 4 步"].exists)
        app.buttons["关闭"].tap()

        // Clean up only this uniquely named page; the recipe stays untouched.
        scrollTo(app.staticTexts[note], in: app)
        let page = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "journal.page."))
            .containing(.staticText, identifier: note).firstMatch
        let delete = page.buttons["删除这页手记"]
        scrollTo(delete, in: app)
        delete.tap()
        // The confirmation dialog exposes the action more than once; tap the first hittable one.
        let confirmation = app.buttons["journal.confirmDelete"].firstMatch
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.tap()
        XCTAssertTrue(page.waitForNonExistence(timeout: 5))
    }

    /// Selection and the cookbook form, without ever opening the system share sheet.
    @MainActor
    func testCookbookSelectionOpensComposeSheet() throws {
        #if !targetEnvironment(simulator)
        throw XCTSkip("UI smoke; simulator only")
        #endif
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-appLanguage", "zh-Hans", "-jcLibrary"]
        app.launch()

        let select = app.buttons["library.select"]
        XCTAssertTrue(select.waitForExistence(timeout: 15))
        select.tap()
        let card = app.buttons["library.recipeCard"].firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()

        let compose = app.buttons["library.compose"]
        XCTAssertTrue(compose.waitForExistence(timeout: 5))
        compose.tap()

        let title = app.descendants(matching: .any).matching(identifier: "cookbook.title").firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["cookbook.generate"].exists)

        app.navigationBars.buttons["取消"].tap()
        let cancel = app.buttons["library.cancelSelection"]
        if cancel.exists { cancel.tap() }
    }

    @MainActor
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<10 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }
}
