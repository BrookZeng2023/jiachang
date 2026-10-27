import SwiftUI

@MainActor
struct CookTimerPanel: View {
    let session: CookingSession
    @Environment(\.appLanguage) private var language
    @State private var selectedMinutes = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(copy(.cookTimer, language), systemImage: "timer")
                .font(.headline)
            if let timer = session.timer {
                if !session.recipe.instructions.isEmpty {
                    Text(copy(.cookTimerSourceStep, language, timer.stepIndex + 1))
                        .font(.subheadline)
                        .foregroundStyle(Color.muted)
                }
                Text(timeDisplay(timer.remainingSeconds))
                    .font(.system(size: 40, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .accessibilityLabel(copy(.cookTimer, language))
                    .accessibilityValue(timeDisplay(timer.remainingSeconds))
                if timer.state == .paused {
                    Text(copy(.cookTimerPaused, language)).foregroundStyle(Color.muted)
                } else if timer.state == .finished {
                    Text(copy(.cookTimerFinished, language)).font(.headline)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { timerButtons(timer) }
                    VStack(alignment: .leading, spacing: 12) { timerButtons(timer) }
                }
            } else {
                Stepper(value: $selectedMinutes, in: CookingTimer.minuteRange) {
                    Text(copy(.cookTimerMinutes, language, selectedMinutes))
                }
                Button(copy(.cookTimerStart, language)) {
                    session.startTimer(minutes: selectedMinutes)
                }
                .buttonStyle(.borderedProminent)
            }
            Text(copy(.cookTimerPolicy, language))
                .font(.footnote)
                .foregroundStyle(Color.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Color.ink)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.paper, in: RoundedRectangle(cornerRadius: 20))
        .onChange(of: session.stepIndex, initial: true) { _, _ in
            selectedMinutes = session.suggestedMinutes ?? 5
        }
    }

    @ViewBuilder
    private func timerButtons(_ timer: CookingTimer) -> some View {
        if timer.state == .running {
            Button(copy(.cookTimerPause, language)) { session.pauseTimer() }
                .buttonStyle(.borderedProminent)
        } else if timer.state == .paused {
            Button(copy(.cookTimerResume, language)) { session.resumeTimer() }
                .buttonStyle(.borderedProminent)
        }
        Button(copy(.cookTimerReset, language)) { session.resetTimer() }
            .buttonStyle(.bordered)
        Button(copy(.cookTimerCancel, language), role: .destructive) { session.cancelTimer() }
            .buttonStyle(.bordered)
    }

    private func timeDisplay(_ seconds: Int) -> String {
        String(format: "%02d:%02d", locale: language.locale, seconds / 60, seconds % 60)
    }
}
