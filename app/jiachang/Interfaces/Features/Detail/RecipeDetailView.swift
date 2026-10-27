import SwiftUI

struct RecipeDetailView: View {
    let summary: RecipeSummary

    @Environment(RecipeLibrary.self) private var library
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @State private var recipe: Recipe?
    @State private var didFailToLoad = false
    @State private var checked = Set<UUID>()
    @State private var showEditor = false
    @State private var confirmDelete = false
    @State private var showJournal = false
    @State private var showCooking = false

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    RecipeArtwork(recipe: current, size: .original)
                        .frame(height: 390)
                        .frame(maxWidth: .infinity)
                    content
                        .padding(.top, 30)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 50)
                        .background(Color.cream)
                        .clipShape(UnevenRoundedRectangle(
                            topLeadingRadius: 32,
                            topTrailingRadius: 32
                        ))
                        .offset(y: -32)
                }
            }
            .ignoresSafeArea(edges: .top)
            toolbar
        }
        .background(Color.cream)
        .toolbar(.hidden, for: .navigationBar)
        .task { await load() }
        .sheet(isPresented: $showEditor, onDismiss: { Task { await load() } }) {
            if let recipe { RecipeEditorView(recipe: recipe) }
        }
        .sheet(isPresented: $showJournal) { CookJournalEditorView(recipe: current) }
        .fullScreenCover(isPresented: $showCooking) {
            if let recipe { CookModeView(recipe: recipe) }
        }
        .confirmationDialog(copy(.deleteConfirm, language, current.localizedName(language)), isPresented: $confirmDelete) {
            Button(copy(.deleteRecipe, language), role: .destructive) {
                Task { if await library.delete(current) { dismiss() } }
            }
        } message: {
            Text(copy(.deleteRecipeJournalWarning, language, library.entries(for: current.id).count))
        }
    }

    private var current: RecipeSummary { recipe?.summary ?? summary }

    private func load() async {
        recipe = await library.detail(for: summary)
        didFailToLoad = recipe == nil
    }

    private var toolbar: some View {
        HStack {
            RoundToolbarButton(action: dismiss.callAsFunction) {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Menu {
                Button { showEditor = true } label: { Label(copy(.editRecipe, language), systemImage: "pencil") }
                    .disabled(recipe == nil)
                if let recipe, recipe.origin == .editedBuiltIn {
                    Button {
                        Task { if let original = await library.restoreOriginal(recipe) { self.recipe = original } }
                    } label: {
                        Label(copy(.restoreOriginal, language), systemImage: "arrow.uturn.backward")
                    }
                }
                Button(role: .destructive) { confirmDelete = true } label: {
                    Label(copy(.deleteRecipe, language), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 42, height: 42)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(copy(.recipeActions, language))
            .accessibilityIdentifier("recipe.actions")
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: JiachangTheme.sectionSpacing) {
            VStack(alignment: .leading, spacing: 10) {
                Text(current.localizedName(language))
                    .font(JiachangFont.emotional(36))
                    .foregroundStyle(Color.ink)
                if let description = current.localizedDescription(language), !description.isEmpty {
                    Text(description)
                        .font(JiachangFont.reading(17))
                        .foregroundStyle(Color.muted)
                        .lineSpacing(6)
                }
                HStack(spacing: 9) {
                    if let servings = current.servings, servings > 0 {
                        MetadataPill(icon: "person.2.fill", text: copy(.servings, language, Int(servings)))
                    }
                    if let minutes = current.totalMinutes, minutes > 0 {
                        MetadataPill(icon: "clock.fill", text: copy(.minutes, language, minutes))
                    }
                }
                ProblemText(problem: library.problem)
            }
            HStack(spacing: 12) {
                Button { showCooking = true } label: {
                    Label(copy(.cookStart, language), systemImage: "flame")
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("recipe.startCooking")
                // Icon only: the journal has no action phrase, the section heading names it.
                Button { showJournal = true } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.persimmon)
                        .frame(width: 54, height: 54)
                        .background(Color.paper)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.hairline, lineWidth: 1))
                }
                .accessibilityLabel(copy(.journalHistory, language))
                .accessibilityIdentifier("journal.new")
            }
            .disabled(recipe == nil)
            ingredientSection
            instructionSection
            RecipeJournalSection(recipe: current) { showJournal = true }
                .disabled(recipe == nil)
        }
    }

    @ViewBuilder
    private var ingredientSection: some View {
        if let ingredients = recipe?.ingredients, !ingredients.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeading(title: copy(.ingredients, language), subtitle: copy(.ingredientsHint, language))
                VStack(spacing: 0) {
                    ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, ingredient in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                                if checked.contains(ingredient.id) {
                                    checked.remove(ingredient.id)
                                } else {
                                    checked.insert(ingredient.id)
                                }
                            }
                        } label: {
                            HStack(spacing: 13) {
                                Image(systemName: checked.contains(ingredient.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Color.persimmon)
                                    .symbolEffect(.bounce, value: checked.contains(ingredient.id))
                                Text(ingredient.localizedText(language))
                                    .font(JiachangFont.reading(17))
                                    .foregroundStyle(checked.contains(ingredient.id) ? Color.muted : Color.ink)
                                    .strikethrough(checked.contains(ingredient.id))
                                Spacer()
                            }
                            .padding(.vertical, 15)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if index < ingredients.count - 1 { Divider().overlay(Color.hairline) }
                    }
                }
                .padding(.horizontal, 17)
                .background(Color.paper)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private var instructionSection: some View {
        if let instructions = recipe?.instructions, !instructions.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeading(title: copy(.steps, language))
                ForEach(Array(instructions.enumerated()), id: \.element.id) { index, instruction in
                    HStack(alignment: .top, spacing: 15) {
                        Text("\(index + 1)")
                            .font(Font.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.persimmon)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 5) {
                            if let title = instruction.localizedTitle(language), !title.isEmpty {
                                Text(title).font(.headline).foregroundStyle(Color.ink)
                            }
                            Text(instruction.localizedText(language))
                                .font(JiachangFont.reading(17))
                                .foregroundStyle(Color.ink)
                                .lineSpacing(6)
                        }
                        .padding(.top, 5)
                    }
                    .padding(17)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }
        } else if recipe == nil && !didFailToLoad {
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 40)
        }
    }
}
