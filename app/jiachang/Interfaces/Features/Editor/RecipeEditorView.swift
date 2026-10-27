import SwiftUI

struct RecipeEditorView: View {
    let recipe: Recipe?

    @Environment(RecipeLibrary.self) private var library
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @State private var draft: RecipeDraft
    @State private var isSaving = false

    init(recipe: Recipe?) {
        self.recipe = recipe
        _draft = State(initialValue: recipe.map(RecipeDraft.init) ?? RecipeDraft())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    EditorPhotoPicker(existing: recipe?.summary, imageData: $draft.imageData)
                    basics
                    ingredients
                    instructions
                    if library.problem == .save {
                        ProblemText(problem: .save)
                    }
                    Button {
                        save()
                    } label: {
                        if isSaving { ProgressView().tint(.white) }
                        else { Text(recipe == nil ? copy(.saveNew, language) : copy(.saveEdit, language)) }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
                .padding(18)
                .padding(.bottom, 24)
            }
            .background(Color.cream)
            .navigationTitle(recipe == nil ? copy(.newRecipe, language) : copy(.editTitle, language))
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(isSaving)
            .toolbarBackground(Color.cream, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(copy(.cancel, language)) { dismiss() } }
            }
        }
    }

    private var basics: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeading(title: copy(.aboutDish, language))
            WarmTextField(title: copy(.recipeName, language), text: $draft.name)
                .font(JiachangFont.emotional(21))
            WarmTextField(title: copy(.recipeDescription, language), text: $draft.description, axis: .vertical)
                .lineLimit(2...4)
            HStack {
                Text(copy(.howMany, language))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink)
                Spacer()
                Stepper(copy(.servings, language, Int(draft.servings)), value: $draft.servings, in: 1...20)
                    .fixedSize()
                    .font(Font.system(size: 16, weight: .semibold))
            }
            .padding(16)
            .background(Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: 17))
        }
    }

    private var ingredients: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                SectionHeading(title: copy(.ingredients, language), subtitle: copy(.ingredientHint, language))
                Spacer()
                addButton { draft.ingredients.append(RecipeIngredient(text: "")) }
            }
            VStack(spacing: 10) {
                ForEach($draft.ingredients) { $ingredient in
                    HStack(spacing: 9) {
                        WarmTextField(title: copy(.ingredientPlaceholder, language), text: $ingredient.text)
                        deleteButton {
                            if draft.ingredients.count > 1 { draft.ingredients.removeAll { $0.id == ingredient.id } }
                        }
                    }
                }
            }
        }
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                SectionHeading(title: copy(.steps, language))
                Spacer()
                addButton { draft.instructions.append(RecipeInstruction(text: "")) }
            }
            VStack(spacing: 12) {
                ForEach($draft.instructions) { $instruction in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(stepNumber(of: instruction))")
                            .font(Font.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.persimmon)
                            .clipShape(Circle())
                            .padding(.top, 9)
                        WarmTextField(title: copy(.stepPlaceholder, language), text: $instruction.text, axis: .vertical)
                            .lineLimit(2...5)
                        deleteButton {
                            if draft.instructions.count > 1 { draft.instructions.removeAll { $0.id == instruction.id } }
                        }
                        .padding(.top, 6)
                    }
                }
            }
        }
    }

    private func stepNumber(of instruction: RecipeInstruction) -> Int {
        (draft.instructions.firstIndex { $0.id == instruction.id } ?? 0) + 1
    }

    private func addButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.headline.bold())
                .foregroundStyle(Color.persimmon)
                .frame(width: 38, height: 38)
                .background(Color.persimmon.opacity(0.1))
                .clipShape(Circle())
        }
    }

    private func deleteButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "minus.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.muted.opacity(0.6))
        }
        .buttonStyle(.plain)
    }

    private func save() {
        isSaving = true
        Task {
            let saved = await library.save(draft, replacing: recipe)
            isSaving = false
            if saved != nil { dismiss() }
        }
    }
}
