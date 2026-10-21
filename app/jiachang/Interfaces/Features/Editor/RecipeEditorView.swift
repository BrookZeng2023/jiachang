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
                    if let error = library.lastError {
                        Text(error).font(.footnote).foregroundStyle(Color.terracotta)
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
                .font(JiachangFont.display(21, weight: .semibold))
            WarmTextField(title: copy(.recipeDescription, language), text: $draft.description, axis: .vertical)
                .lineLimit(2...4)
            HStack {
                Text(copy(.howMany, language))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink)
                Spacer()
                Stepper(copy(.servings, language, Int(draft.servings)), value: $draft.servings, in: 1...20)
                    .fixedSize()
                    .font(JiachangFont.rounded(16, weight: .semibold))
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
                ForEach(draft.ingredients.indices, id: \.self) { index in
                    HStack(spacing: 9) {
                        WarmTextField(title: copy(.ingredientPlaceholder, language), text: $draft.ingredients[index].text)
                        deleteButton {
                            if draft.ingredients.count > 1 { draft.ingredients.remove(at: index) }
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
                ForEach(draft.instructions.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(JiachangFont.rounded(15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.persimmon)
                            .clipShape(Circle())
                            .padding(.top, 9)
                        WarmTextField(title: copy(.stepPlaceholder, language), text: $draft.instructions[index].text, axis: .vertical)
                            .lineLimit(2...5)
                        deleteButton {
                            if draft.instructions.count > 1 { draft.instructions.remove(at: index) }
                        }
                        .padding(.top, 6)
                    }
                }
            }
        }
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
