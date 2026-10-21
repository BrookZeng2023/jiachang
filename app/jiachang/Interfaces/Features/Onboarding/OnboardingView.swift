import SwiftUI

struct OnboardingView: View {
    @Environment(SessionController.self) private var session
    @Environment(\.appLanguage) private var language
    let onConnect: () async -> Void

    var body: some View {
        @Bindable var session = session
        ScrollView {
            VStack(spacing: 26) {
                Spacer(minLength: 54)
                ZStack {
                    Circle().fill(Color.persimmon.opacity(0.12)).frame(width: 150, height: 150)
                    Image("LaunchMark").resizable().scaledToFit().frame(width: 96)
                }
                VStack(spacing: 8) {
                    Text("家常")
                        .font(JiachangFont.display(42))
                        .foregroundStyle(Color.ink)
                    Text(copy(.tagline, language))
                        .foregroundStyle(Color.muted)
                }
                VStack(spacing: 13) {
                    WarmTextField(title: copy(.server, language), text: $session.credentials.server)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    WarmTextField(title: copy(.username, language), text: $session.credentials.username)
                        .textInputAutocapitalization(.never)
                    SecureField(copy(.password, language), text: $session.credentials.password)
                        .padding(16)
                        .background(Color.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 17))
                        .overlay { RoundedRectangle(cornerRadius: 17).stroke(Color.hairline) }
                }
                if case .offline(let message) = session.status {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.terracotta)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button(copy(.enterKitchen, language)) { Task { await onConnect() } }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!session.credentials.isComplete)
                    .opacity(session.credentials.isComplete ? 1 : 0.45)
                Spacer(minLength: 24)
            }
            .padding(.horizontal, 28)
        }
        .background(Color.cream)
    }
}
