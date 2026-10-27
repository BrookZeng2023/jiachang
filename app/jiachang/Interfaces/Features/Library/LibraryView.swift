import SwiftUI

struct LibraryView: View {
    @Environment(RecipeLibrary.self) private var library
    @Environment(\.appLanguage) private var language
    @State private var query = ""
    @State private var showEditor = false
    @State private var tonight: RecipeSummary?
    @State private var openedTonight: RecipeSummary?
    @State private var isSelecting = false
    @State private var selected = Set<UUID>()
    @State private var showCompose = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    searchField
                    ProblemText(problem: library.problem)
                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        && !library.recipes.isEmpty && !isSelecting {
                        TonightCard(recipe: tonight, onShuffle: shuffle)
                            .onTapGesture { openedTonight = tonight }
                    }
                    if library.recipes.isEmpty && !library.isLoading {
                        EmptyKitchenView { showEditor = true }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 56)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(library.search(query)) { recipe in
                                if isSelecting {
                                    Button { toggle(recipe) } label: { compactCard(recipe) }
                                        .buttonStyle(PressableCardStyle())
                                        .accessibilityIdentifier("library.recipeCard")
                                } else {
                                    NavigationLink(value: recipe) {
                                        compactCard(recipe)
                                    }
                                    .buttonStyle(PressableCardStyle())
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
            .background(Color.cream)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: RecipeSummary.self) { RecipeDetailView(summary: $0) }
            .overlay { if library.isLoading { ProgressView().controlSize(.large) } }
            .refreshable { await library.refresh() }
            .safeAreaInset(edge: .bottom) {
                if isSelecting { selectionBar }
            }
            .sheet(isPresented: $showEditor) { RecipeEditorView(recipe: nil) }
            .sheet(isPresented: $showCompose) { CookbookComposeSheet(recipes: selectedRecipes) }
            .navigationDestination(item: $openedTonight) { RecipeDetailView(summary: $0) }
            .task { if tonight == nil { shuffle() } }
            .onChange(of: library.recipes) { _, recipes in
                tonight = recipes.first { $0.id == tonight?.id } ?? recipes.randomElement()
                selected = selected.intersection(Set(recipes.map(\.id)))
            }
        }
    }

    private func shuffle() {
        let choices = library.recipes.filter { $0.id != tonight?.id }
        tonight = choices.randomElement() ?? library.recipes.first
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(copy(.myKitchen, language))
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.persimmon)
                Text(copy(.cookbook, language))
                    .font(JiachangFont.emotional(36))
                    .foregroundStyle(Color.ink)
            }
            Spacer()
            if isSelecting {
                Button(copy(.libraryCancelSelection, language)) { endSelection() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.persimmon)
                    .accessibilityIdentifier("library.cancelSelection")
            } else {
                Button(copy(.librarySelect, language)) { startSelection() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.persimmon)
                    .padding(.trailing, 4)
                    .accessibilityIdentifier("library.select")
                Button { showEditor = true } label: {
                    Image(systemName: "plus")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.persimmon)
                        .clipShape(Circle())
                }
                .buttonStyle(PressableCardStyle())
            }
        }
        .padding(.top, 12)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Color.muted)
            TextField(copy(.search, language), text: $query)
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .foregroundStyle(Color.muted)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(Color.paper)
        .clipShape(Capsule())
        .overlay { Capsule().stroke(Color.hairline) }
    }

    private func compactCard(_ recipe: RecipeSummary) -> some View {
        ZStack(alignment: .bottomLeading) {
            RecipeArtwork(recipe: recipe)
                .frame(height: 220)
                .frame(maxWidth: .infinity)
            LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.localizedName(language))
                    .font(JiachangFont.emotional(19))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if let servings = recipe.servings, servings > 0 {
                    Text(copy(.servings, language, Int(servings)))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
        .shadow(color: Color.ink.opacity(0.10), radius: 10, y: 6)
        .overlay(alignment: .topTrailing) {
            if isSelecting {
                let picked = selected.contains(recipe.id)
                Image(systemName: picked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(picked ? Color.persimmon : Color.white)
                    .padding(10)
            }
        }
    }

    private var selectedRecipes: [RecipeSummary] {
        library.recipes.filter { selected.contains($0.id) }
    }

    private func toggle(_ recipe: RecipeSummary) {
        if selected.contains(recipe.id) { selected.remove(recipe.id) } else { selected.insert(recipe.id) }
    }

    private func startSelection() {
        isSelecting = true
        selected = []
    }

    private func endSelection() {
        isSelecting = false
        selected = []
    }

    private var selectionBar: some View {
        HStack(spacing: 14) {
            Text(copy(.librarySelectedCount, language, selected.count))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.ink)
            Button(allVisibleSelected ? copy(.libraryDeselectAll, language) : copy(.librarySelectAll, language)) {
                if allVisibleSelected {
                    selected = []
                } else {
                    selected = Set(library.search(query).map(\.id))
                }
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.persimmon)
            .disabled(library.recipes.isEmpty)
            Spacer()
            Button(copy(.libraryCompose, language)) { showCompose = true }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(selected.isEmpty ? Color.muted.opacity(0.45) : Color.persimmon)
                .clipShape(Capsule())
                .disabled(selected.isEmpty)
                .accessibilityIdentifier("library.compose")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("library.selectionBar")
    }

    private var allVisibleSelected: Bool {
        let visible = library.search(query).map(\.id)
        return !visible.isEmpty && visible.allSatisfy(selected.contains)
    }
}
