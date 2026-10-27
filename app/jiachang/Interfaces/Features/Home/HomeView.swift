import SwiftUI

struct HomeView: View {
    @Environment(RecipeLibrary.self) private var library
    @Environment(\.appLanguage) private var language
    @Binding var showEditor: Bool
    let openCookbook: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    header
                    introduction
                    ProblemText(problem: library.problem)
                    if library.journal.isEmpty {
                        emptyJournal
                    } else {
                        ForEach(library.journal) { entry in
                            if let recipe = library.recipes.first(where: { $0.id == entry.recipeID }) {
                                NavigationLink(value: recipe) {
                                    JournalCard(entry: entry, recipe: recipe)
                                }
                                .buttonStyle(PressableCardStyle())
                            } else {
                                JournalCard(entry: entry, recipe: nil)
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .background(Color.cream)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: RecipeSummary.self) { RecipeDetailView(summary: $0) }
            .refreshable { await library.refresh() }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("AT OUR TABLE")
                    .font(.system(.caption, design: .serif))
                    .tracking(2.4)
                    .foregroundStyle(Color.persimmon)
                Text("家常").font(JiachangFont.emotional(38)).foregroundStyle(Color.ink)
            }
            Spacer()
            NavigationLink { SettingsView() } label: {
                Image(systemName: "info.circle").font(.title2).frame(width: 44, height: 44)
            }
            .accessibilityLabel(copy(.settings, language))
            Button { showEditor = true } label: {
                Image(systemName: "plus").font(.headline).frame(width: 44, height: 44)
            }
            .accessibilityLabel(copy(.newRecipe, language))
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(today) · \(copy(season, language))")
                .font(JiachangFont.emotional(16))
                .foregroundStyle(Color.persimmon)
            Text(copy(.journalGreeting, language))
                .font(JiachangFont.emotional(30))
                .foregroundStyle(Color.ink)
            Text(copy(.journalTagline, language))
                .font(JiachangFont.emotional(18))
                .foregroundStyle(Color.muted)
                .lineSpacing(6)
        }
    }

    private var emptyJournal: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let recipe = library.recipes.first {
                NavigationLink(value: recipe) {
                    RecipeArtwork(recipe: recipe, size: .original)
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .buttonStyle(.plain)
            }
            Text(copy(.journalEmpty, language))
                .font(JiachangFont.emotional(24))
                .foregroundStyle(Color.ink)
            Text(copy(.journalEmptyHint, language))
                .font(JiachangFont.reading(17))
                .foregroundStyle(Color.muted)
                .lineSpacing(7)
            Button(copy(.journalBrowse, language), action: openCookbook)
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var today: String { KitchenDate.short(Date(), language: language) }

    private var season: CopyKey {
        switch Calendar.current.component(.month, from: Date()) {
        case 3...5: .seasonSpring
        case 6...8: .seasonSummer
        case 9...11: .seasonAutumn
        default: .seasonWinter
        }
    }
}
