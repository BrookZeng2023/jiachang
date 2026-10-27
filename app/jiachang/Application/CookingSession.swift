import Foundation
import Observation

@MainActor
@Observable
final class CookingSession {
    let recipe: Recipe
    private(set) var stepIndex = 0
    private(set) var checkedIngredients = Set<UUID>()
    private(set) var timer: CookingTimer?
    private(set) var isActive = true
    @ObservationIgnored private let now: () -> Date

    init(recipe: Recipe, now: @escaping () -> Date = Date.init) {
        self.recipe = recipe
        self.now = now
    }

    var currentStep: RecipeInstruction? {
        recipe.instructions.indices.contains(stepIndex) ? recipe.instructions[stepIndex] : nil
    }

    var canGoPrevious: Bool { stepIndex > 0 }
    var canGoNext: Bool { stepIndex + 1 < recipe.instructions.count }

    var suggestedMinutes: Int? {
        currentStep.flatMap { CookingDurationParser.suggestedMinutes(in: $0.text) }
    }

    func previousStep() {
        guard canGoPrevious else { return }
        stepIndex -= 1
    }

    func nextStep() {
        guard canGoNext else { return }
        stepIndex += 1
    }

    func toggleIngredient(_ id: UUID) {
        guard recipe.ingredients.contains(where: { $0.id == id }) else { return }
        if checkedIngredients.contains(id) {
            checkedIngredients.remove(id)
        } else {
            checkedIngredients.insert(id)
        }
    }

    /// One timer per session. Step navigation never silently replaces a running timer.
    func startTimer(minutes: Int) {
        guard isActive, timer == nil, CookingTimer.minuteRange.contains(minutes) else { return }
        timer = CookingTimer(minutes: minutes, stepIndex: stepIndex, now: now())
    }

    /// The caller may issue foreground sound/haptics only when this returns true.
    @discardableResult
    func tick() -> Bool {
        guard isActive else { return false }
        return timer?.tick(now: now()) ?? false
    }

    func pauseTimer() { timer?.pause(now: now()) }

    func resumeTimer() {
        guard isActive else { return }
        timer?.resume(now: now())
    }

    func resetTimer() { timer?.reset() }
    func cancelTimer() { timer = nil }

    func setActive(_ active: Bool) {
        if !active { pauseTimer() }
        // Becoming active does not resume a timer. The user must explicitly resume it.
        isActive = active
    }

    func close() {
        cancelTimer()
        isActive = false
    }
}
