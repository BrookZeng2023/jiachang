import AudioToolbox
import SwiftUI
import UIKit

/// Entry point for cooking mode. Present with `.fullScreenCover { CookModeView(recipe: recipe) }`.
@MainActor
struct CookModeView: View {
    @State private var session: CookingSession
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    init(recipe: Recipe) {
        _session = State(initialValue: CookingSession(recipe: recipe))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(session.recipe.summary.localizedName(language))
                        .font(JiachangFont.emotional(30))
                        .foregroundStyle(Color.ink)
                    if session.currentStep != nil {
                        CookStepView(session: session, onFinish: finish)
                    } else {
                        CookEmptyStateView()
                        Button(copy(.cookDone, language), action: finish)
                            .buttonStyle(.borderedProminent)
                    }
                    CookIngredientsPanel(session: session)
                    CookTimerPanel(session: session)
                }
                .padding(20)
                .frame(maxWidth: 700, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Color.cream)
            .navigationTitle(copy(.cookMode, language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(copy(.cookClose, language)) { finish() }
                }
            }
        }
        .tint(Color.persimmon)
        .onChange(of: scenePhase, initial: true) { _, phase in
            session.setActive(phase == .active)
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                if scenePhase == .active,
                   UIApplication.shared.applicationState == .active, session.tick() {
                    AudioServicesPlaySystemSound(1005)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                do {
                    try await Task.sleep(for: .milliseconds(250))
                } catch {
                    return
                }
            }
        }
        .onDisappear { session.close() }
    }

    private func finish() {
        session.close()
        dismiss()
    }
}

private struct CookEmptyStateView: View {
    @Environment(\.appLanguage) private var language

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "cooktop")
                .font(.system(size: 44))
                .foregroundStyle(Color.caramel)
            Text(copy(.cookNoSteps, language))
                .font(JiachangFont.emotional(26))
                .foregroundStyle(Color.ink)
            Text(copy(.cookNoStepsMessage, language))
                .font(JiachangFont.reading(17))
                .foregroundStyle(Color.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
        }
        .padding(24)
    }
}
