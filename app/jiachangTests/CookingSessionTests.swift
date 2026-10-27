import XCTest
@testable import jiachang

@MainActor
final class CookingSessionTests: XCTestCase {
    private func makeRecipe(instructions: [String]) -> Recipe {
        Recipe(
            id: UUID(),
            name: "Test",
            description: nil,
            servings: nil,
            totalMinutes: nil,
            imageToken: nil,
            ingredients: [],
            instructions: instructions.map { RecipeInstruction(text: $0) },
            origin: .personal
        )
    }

    func testPauseResumeKeepsDeadlineBasedRemaining() {
        var time = Date(timeIntervalSince1970: 1_000)
        var timer = CookingTimer(minutes: 1, stepIndex: 0, now: time)
        time.addTimeInterval(20)
        XCTAssertFalse(timer.tick(now: time))
        XCTAssertEqual(timer.remainingSeconds, 40)
        timer.pause(now: time)
        XCTAssertEqual(timer.state, .paused)
        time.addTimeInterval(600)
        XCTAssertFalse(timer.tick(now: time))
        XCTAssertEqual(timer.remainingSeconds, 40)
        timer.resume(now: time)
        XCTAssertEqual(timer.state, .running)
        time.addTimeInterval(39)
        XCTAssertFalse(timer.tick(now: time))
        XCTAssertEqual(timer.remainingSeconds, 1)
        XCTAssertTrue(timer.tick(now: time.addingTimeInterval(1)))
        XCTAssertEqual(timer.state, .finished)
        XCTAssertFalse(timer.tick(now: time.addingTimeInterval(100)))
        XCTAssertEqual(timer.remainingSeconds, 0)
    }

    func testResetCancelsAndFinishesOnlyOnce() {
        var time = Date(timeIntervalSince1970: 0)
        var timer = CookingTimer(minutes: 2, stepIndex: 0, now: time)
        timer.reset()
        XCTAssertEqual(timer.state, .paused)
        XCTAssertEqual(timer.remainingSeconds, 120)
        timer.resume(now: time)
        time.addTimeInterval(120)
        XCTAssertTrue(timer.tick(now: time))
        timer.reset()
        XCTAssertEqual(timer.state, .paused)
        XCTAssertEqual(timer.remainingSeconds, 120)
    }

    func testStepBoundariesAndOneTimerAcrossNavigation() {
        let time = Date(timeIntervalSince1970: 0)
        let session = CookingSession(recipe: makeRecipe(instructions: ["A", "B"]), now: { time })
        session.previousStep()
        XCTAssertEqual(session.stepIndex, 0)
        session.nextStep()
        session.nextStep()
        XCTAssertEqual(session.stepIndex, 1)
        session.startTimer(minutes: 5)
        XCTAssertEqual(session.timer?.remainingSeconds, 300)
        session.previousStep()
        XCTAssertEqual(session.timer?.stepIndex, 1)
        session.startTimer(minutes: 1)
        XCTAssertEqual(session.timer?.remainingSeconds, 300)
    }

    func testBackgroundPausesAndForegroundNeedsManualResume() {
        var time = Date(timeIntervalSince1970: 0)
        let session = CookingSession(recipe: makeRecipe(instructions: ["A"]), now: { time })
        session.startTimer(minutes: 1)
        time.addTimeInterval(30)
        session.setActive(false)
        XCTAssertEqual(session.timer?.state, .paused)
        XCTAssertEqual(session.timer?.remainingSeconds, 30)
        time.addTimeInterval(500)
        session.setActive(true)
        XCTAssertEqual(session.timer?.state, .paused)
        session.tick()
        XCTAssertEqual(session.timer?.remainingSeconds, 30)
        session.resumeTimer()
        XCTAssertFalse(session.tick())
        time.addTimeInterval(30)
        XCTAssertTrue(session.tick())
        XCTAssertEqual(session.timer?.state, .finished)
    }

    func testCancelAndFinishSignal() {
        var time = Date(timeIntervalSince1970: 0)
        let session = CookingSession(recipe: makeRecipe(instructions: ["A"]), now: { time })
        session.startTimer(minutes: 1)
        session.cancelTimer()
        XCTAssertNil(session.timer)
        session.startTimer(minutes: 1)
        time.addTimeInterval(60)
        XCTAssertTrue(session.tick())
        XCTAssertFalse(session.tick())
    }

    func testEmptyStepsAndInvalidMinutesAreSafe() {
        let session = CookingSession(recipe: makeRecipe(instructions: []))
        session.nextStep()
        session.previousStep()
        XCTAssertNil(session.currentStep)
        XCTAssertEqual(session.stepIndex, 0)
        XCTAssertFalse(session.canGoNext)
        XCTAssertFalse(session.canGoPrevious)
        for minutes in [0, -1, 1_441, Int.max] {
            session.startTimer(minutes: minutes)
            XCTAssertNil(session.timer)
        }
    }

    func testExpiredWhileLeavingForegroundWaitsForExplicitResume() {
        var time = Date(timeIntervalSince1970: 0)
        let session = CookingSession(recipe: makeRecipe(instructions: ["A"]), now: { time })
        session.startTimer(minutes: 1)
        time.addTimeInterval(61)
        session.setActive(false)
        XCTAssertFalse(session.tick())
        session.resumeTimer()
        XCTAssertEqual(session.timer?.state, .paused)
        session.setActive(true)
        XCTAssertFalse(session.tick())
        session.resumeTimer()
        XCTAssertTrue(session.tick())
        XCTAssertFalse(session.tick())
        session.resetTimer()
        XCTAssertFalse(session.tick())
        session.resumeTimer()
        time.addTimeInterval(60)
        XCTAssertTrue(session.tick())
        XCTAssertFalse(session.tick())
        session.close()
        XCTAssertNil(session.timer)
        XCTAssertFalse(session.isActive)
        XCTAssertFalse(session.tick())
    }

    func testDurationParserRejectsAmbiguity() {
        XCTAssertEqual(CookingDurationParser.suggestedMinutes(in: "煮 5 分钟"), 5)
        XCTAssertEqual(CookingDurationParser.suggestedMinutes(in: "Simmer for 10 minutes"), 10)
        XCTAssertEqual(CookingDurationParser.suggestedMinutes(in: "sauté 3 min"), 3)
        XCTAssertEqual(CookingDurationParser.suggestedMinutes(in: "煮 十五分钟"), 15)
        XCTAssertEqual(CookingDurationParser.suggestedMinutes(in: "炖 两小时后煮 8 分钟"), 8)
        XCTAssertNil(CookingDurationParser.suggestedMinutes(in: "煮 5 分钟后焖 2 分钟"))
        XCTAssertNil(CookingDurationParser.suggestedMinutes(in: "cook 3-5 min"))
        XCTAssertNil(CookingDurationParser.suggestedMinutes(in: "bake 1.5 min"))
        XCTAssertEqual(CookingDurationParser.suggestedMinutes(in: "Boil 5 minutes · 煮 5 分钟"), 5)
        XCTAssertNil(CookingDurationParser.suggestedMinutes(in: "0.5分钟"))
        for text in ["cook 3–5 min", "煮3至5分钟", "煮三到五分钟", "bake .5 min", "1/2 min", "5 min and 5 min", "-5 min"] {
            XCTAssertNil(CookingDurationParser.suggestedMinutes(in: text), text)
        }
        XCTAssertEqual(CookingDurationParser.suggestedMinutes(in: "中火煮30分钟"), 30)
    }
}
