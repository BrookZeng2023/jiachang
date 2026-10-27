import SwiftUI

@MainActor
struct CookStepView: View {
    let session: CookingSession
    let onFinish: () -> Void
    @Environment(\.appLanguage) private var language

    var body: some View {
        if let step = session.currentStep {
            VStack(alignment: .leading, spacing: 18) {
                Text(copy(.cookStepProgress, language, session.stepIndex + 1, session.recipe.instructions.count))
                    .font(.headline)
                    .foregroundStyle(Color.muted)
                if let title = step.localizedTitle(language), !title.isEmpty {
                    Text(title)
                        .font(JiachangFont.reading(20))
                        .foregroundStyle(Color.ink)
                }
                Text(step.localizedText(language))
                    .font(JiachangFont.reading(20))
                    .foregroundStyle(Color.ink)
                    .lineSpacing(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) { navigationButtons }
                    VStack(alignment: .leading, spacing: 12) { navigationButtons }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.paper, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    @ViewBuilder
    private var navigationButtons: some View {
        Button(copy(.cookPrevious, language)) { session.previousStep() }
            .buttonStyle(.bordered)
            .disabled(!session.canGoPrevious)
        if session.canGoNext {
            Button(copy(.cookNext, language)) { session.nextStep() }
                .buttonStyle(.borderedProminent)
        } else {
            Button(copy(.cookDone, language), action: onFinish)
                .buttonStyle(.borderedProminent)
        }
    }
}
