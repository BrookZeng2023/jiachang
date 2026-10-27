import SwiftUI

@main
struct JiachangApp: App {
    @State private var library = RecipeLibrary(repository: LocalRecipeRepository.standard())
    @State private var language = LanguageController()
    @State private var photoCapture = PhotoCapture(
        cameraAccess: SystemCameraAccess(),
        normalizer: JPEGPhotoNormalizer()
    )

    init() {
        BundledFontRegistrar().registerAll()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(library)
                .environment(language)
                .environment(photoCapture)
                .environment(\.appLanguage, language.current)
                .environment(\.locale, language.current.locale)
                .tint(Color.persimmon)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @Environment(RecipeLibrary.self) private var library

    var body: some View {
        Group {
            if library.isLoaded {
                MainTabs()
            } else {
                LaunchView()
            }
        }
        .background(Color.cream.ignoresSafeArea())
        .task { await library.refresh() }
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
                    .font(JiachangFont.emotional(38))
                    .foregroundStyle(.white)
                Text("A PERSONAL KITCHEN JOURNAL")
                    .font(.caption.weight(.semibold))
                    .tracking(2.4)
                    .foregroundStyle(.white.opacity(0.72))
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
            HomeView(showEditor: $showEditor, openCookbook: { selectedTab = .library })
                .tag(Tab.home)
                .tabItem { Label(copy(.todayTab, language), systemImage: "book.pages.fill") }
            LibraryView()
                .tag(Tab.library)
                .tabItem { Label(copy(.recipesTab, language), systemImage: "book.closed.fill") }
        }
        .toolbarBackground(Color.paper, for: .tabBar)
        .sheet(isPresented: $showEditor) { RecipeEditorView(recipe: nil) }
        .sheet(item: $debugDetail) { RecipeDetailView(summary: $0) }
        #if DEBUG
        .task {
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-jcLibrary") { selectedTab = .library }
            if args.contains("-jcEdit") { showEditor = true }
            if let index = args.firstIndex(of: "-jcOpen"),
               args.indices.contains(index + 1) {
                debugDetail = library.recipes.first { $0.id.uuidString == args[index + 1].uppercased() }
            }
        }
        #endif
    }
}
