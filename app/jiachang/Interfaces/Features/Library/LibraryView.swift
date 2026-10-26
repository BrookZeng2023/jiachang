import SwiftUI

struct LibraryView: View {
    @Environment(RecipeLibrary.self) private var library
    @Environment(\.appLanguage) private var language
    @State private var query = ""
    @State private var showEditor = false

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
                    if library.recipes.isEmpty && !library.isLoading {
                        EmptyKitchenView { showEditor = true }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 56)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(library.search(query)) { recipe in
                                NavigationLink(value: recipe) {
                                    compactCard(recipe)
                                }
                                .buttonStyle(PressableCardStyle())
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
            .sheet(isPresented: $showEditor) { RecipeEditorView(recipe: nil) }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(copy(.myKitchen, language))
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.persimmon)
                Text(copy(.cookbook, language))
                    .font(JiachangFont.display(36))
                    .foregroundStyle(Color.ink)
            }
            Spacer()
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
                    .font(JiachangFont.display(19, weight: .semibold))
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
    }
}
