import SwiftUI

struct SettingsView: View {
    @Environment(RecipeLibrary.self) private var library
    @Environment(LanguageController.self) private var languageController
    @Environment(\.appLanguage) private var language

    var body: some View {
        @Bindable var languageController = languageController
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("家常")
                        .font(AboutTypography.title)
                        .foregroundStyle(Color.ink)
                    Text(copy(.privateCookbook, language))
                        .foregroundStyle(Color.muted)
                }
                DeveloperMessageView()
                settingsSection(copy(.language, language)) {
                    Picker(copy(.language, language), selection: $languageController.current) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                if library.deletedBuiltInCount > 0 {
                    RestoreStarterRecipesSection()
                }
                ProblemText(problem: library.problem)
                Divider().overlay(Color.hairline)
                AboutNoticesView()
                Text(copy(.storageNote, language, appVersion))
                    .font(AboutTypography.note)
                    .foregroundStyle(Color.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
            }
            .padding(20)
        }
        .background(Color.cream)
        .navigationTitle(copy(.settings, language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.cream, for: .navigationBar)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            AboutSectionHeading(title: title)
            content()
        }
    }
}
