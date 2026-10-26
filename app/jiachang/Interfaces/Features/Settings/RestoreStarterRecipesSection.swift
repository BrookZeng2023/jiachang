import SwiftUI

struct RestoreStarterRecipesSection: View {
    @Environment(RecipeLibrary.self) private var library
    @Environment(\.appLanguage) private var language
    @State private var confirmRestore = false
    @State private var isRestoring = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AboutSectionHeading(title: copy(.starterRecipes, language))
            Button(copy(.restoreDeleted, language, library.deletedBuiltInCount)) {
                confirmRestore = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isRestoring)
        }
        .confirmationDialog(
            copy(.restoreDeletedTitle, language),
            isPresented: $confirmRestore,
            titleVisibility: .visible
        ) {
            Button(copy(.restoreDeletedAction, language)) {
                isRestoring = true
                Task {
                    await library.restoreDeletedBuiltIns()
                    isRestoring = false
                }
            }
            Button(copy(.cancel, language), role: .cancel) {}
        } message: {
            Text(copy(.restoreDeletedMessage, language, library.deletedBuiltInCount))
        }
    }
}
