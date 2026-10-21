import SwiftUI

@main
struct JiachangApp: App {
    @State private var session = SessionController(
        credentialsStore: SystemCredentialsStore(),
        gateway: MealieSessionGateway()
    )
    @State private var library = RecipeLibrary()
    @State private var language = LanguageController()

    var body: some Scene {
        WindowGroup {
            RootView(session: session, library: library)
                .environment(session)
                .environment(library)
                .environment(language)
                .environment(\.appLanguage, language.current)
                .environment(\.locale, language.current.locale)
                .tint(Color.persimmon)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    let session: SessionController
    let library: RecipeLibrary
    @State private var isHydrated = false

    var body: some View {
        Group {
            switch session.status {
            case .ready where isHydrated:
                MainTabs()
            case .connecting, .ready:
                LaunchView()
            case .idle, .offline:
                OnboardingView { await connect() }
            }
        }
        .background(Color.cream.ignoresSafeArea())
        .task {
            if session.credentials.isComplete { await connect() }
        }
    }

    private func connect() async {
        isHydrated = false
        await session.connect()
        if let repository = session.repository {
            library.bind(to: repository)
            await library.refresh()
            isHydrated = true
        }
    }
}

struct LaunchView: View {
    var body: some View {
        ZStack {
            Color.persimmon.ignoresSafeArea()
            VStack(spacing: 16) {
                Image("LaunchMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 122, height: 122)
                Text("家常")
                    .font(JiachangFont.display(34))
                    .foregroundStyle(.white)
            }
        }
    }
}

struct MainTabs: View {
    private enum Tab { case home, library }

    @Environment(RecipeLibrary.self) private var library
    @Environment(\.appLanguage) private var language
    @State private var selectedTab: Tab = .home
    @State private var showEditor = false
    @State private var debugDetail: RecipeSummary?

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(showEditor: $showEditor)
                .tag(Tab.home)
                .tabItem { Label(copy(.todayTab, language), systemImage: "house.fill") }
            LibraryView()
                .tag(Tab.library)
                .tabItem { Label(copy(.recipesTab, language), systemImage: "book.closed.fill") }
        }
        .toolbarBackground(Color.paper, for: .tabBar)
        .sheet(isPresented: $showEditor) { RecipeEditorView(recipe: nil) }
        .sheet(item: $debugDetail) { RecipeDetailView(summary: $0) }
        .task {
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-jcLibrary") { selectedTab = .library }
            if args.contains("-jcEdit") { showEditor = true }
            if let index = args.firstIndex(of: "-jcOpen"),
               args.indices.contains(index + 1) {
                debugDetail = library.recipes.first { $0.slug == args[index + 1] }
            }
        }
    }
}
