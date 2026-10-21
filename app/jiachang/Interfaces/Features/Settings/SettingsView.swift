import SwiftUI

struct SettingsView: View {
    @Environment(SessionController.self) private var session
    @Environment(RecipeLibrary.self) private var library
    @Environment(LanguageController.self) private var languageController
    @Environment(\.appLanguage) private var language

    var body: some View {
        @Bindable var session = session
        @Bindable var languageController = languageController
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("家常")
                        .font(JiachangFont.display(36))
                        .foregroundStyle(Color.ink)
                    Text(copy(.privateCookbook, language))
                        .foregroundStyle(Color.muted)
                }
                settingsSection(copy(.language, language)) {
                    Picker(copy(.language, language), selection: $languageController.current) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                settingsSection(copy(.server, language)) {
                    WarmTextField(title: copy(.server, language), text: $session.credentials.server)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                settingsSection(copy(.account, language)) {
                    WarmTextField(title: copy(.username, language), text: $session.credentials.username)
                        .textInputAutocapitalization(.never)
                    SecureField(copy(.password, language), text: $session.credentials.password)
                        .padding(16)
                        .background(Color.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 17))
                        .overlay { RoundedRectangle(cornerRadius: 17).stroke(Color.hairline) }
                }
                Button(copy(.reconnect, language)) {
                    Task {
                        await session.connect()
                        if let repository = session.repository {
                            library.bind(to: repository)
                            await library.refresh()
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                if case .offline(let message) = session.status {
                    Text(message).font(.footnote).foregroundStyle(Color.terracotta)
                }
                Text(copy(.backendNote, language))
                    .font(.footnote)
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

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: title)
            content()
        }
    }
}
