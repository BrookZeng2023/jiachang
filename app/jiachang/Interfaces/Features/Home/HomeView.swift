import SwiftUI

struct HomeView: View {
    @Environment(RecipeLibrary.self) private var library
    @Environment(\.appLanguage) private var language
    @Binding var showEditor: Bool
    @State private var tonight: RecipeSummary?
    @State private var openedTonight: RecipeSummary?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    ProblemText(problem: library.problem)
                    TonightCard(recipe: tonight) { shuffle() }
                        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .onTapGesture { openedTonight = tonight }
                    recentSection
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
            .background(Color.cream)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: RecipeSummary.self) { RecipeDetailView(summary: $0) }
            .navigationDestination(item: $openedTonight) { RecipeDetailView(summary: $0) }
            .refreshable { await library.refresh() }
            .task { if tonight == nil { tonight = library.recipes.randomElement() } }
            .onChange(of: library.recipes) { _, recipes in
                tonight = recipes.first { $0.id == tonight?.id } ?? recipes.randomElement()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(dateText)
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.persimmon)
                Text(greeting)
                    .font(JiachangFont.display(34))
                    .foregroundStyle(Color.ink)
            }
            Spacer()
            NavigationLink { SettingsView() } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 27, weight: .medium))
                    .foregroundStyle(Color.ink)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(copy(.settings, language))
            .accessibilityHint(copy(.settingsHint, language))
            Button { showEditor = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.persimmon)
                    .clipShape(Circle())
                    .shadow(color: Color.persimmon.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(PressableCardStyle())
            .accessibilityLabel(copy(.newRecipe, language))
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private var recentSection: some View {
        if library.recipes.isEmpty && !library.isLoading {
            EmptyKitchenView { showEditor = true }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeading(title: copy(.recent, language))
                    Spacer()
                    Text(copy(.dishCount, language, library.recipes.count))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.muted)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(library.recipes.prefix(10)) { recipe in
                            NavigationLink(value: recipe) {
                                RecipeImageCard(recipe: recipe, height: 190)
                                    .frame(width: 280)
                            }
                            .buttonStyle(PressableCardStyle())
                        }
                    }
                    .padding(.bottom, 18)
                }
                .contentMargins(.horizontal, 0, for: .scrollContent)
            }
        }
    }

    private func shuffle() {
        guard !library.recipes.isEmpty else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
            if library.recipes.count == 1 {
                tonight = library.recipes[0]
            } else {
                let previous = tonight
                repeat { tonight = library.recipes.randomElement() } while tonight == previous
            }
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<11: copy(.morning, language)
        case 11..<14: copy(.noon, language)
        case 14..<18: copy(.afternoon, language)
        default: copy(.evening, language)
        }
    }

    private var dateText: String {
        Date().formatted(.dateTime.month(.wide).day().weekday(.wide).locale(language.locale))
    }
}
