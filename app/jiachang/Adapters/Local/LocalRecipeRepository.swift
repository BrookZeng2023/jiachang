import Foundation

enum LocalLibraryError: Error, Equatable {
    case recipeNotFound
    case notBuiltIn
}

/// Merges the bundled catalog with the user's on-disk overlay.
///
/// Conflict rules: an edited built-in keeps the user's version across catalog
/// updates, a deleted built-in stays deleted, and new built-ins simply appear.
actor LocalRecipeRepository: RecipeRepository, JournalRepository {
    private let catalogDirectory: URL
    private let file: LocalLibraryFile
    private let images: LocalImageStore
    private let now: () -> Date
    private var cachedCatalog: BundledCatalog?
    private var cachedLibrary: LocalLibraryDTO?

    init(catalogDirectory: URL, storageDirectory: URL, now: @escaping () -> Date = Date.init) {
        self.catalogDirectory = catalogDirectory
        file = LocalLibraryFile(url: storageDirectory.appending(path: "library.json"))
        images = LocalImageStore(directory: storageDirectory.appending(path: "Images"))
        self.now = now
    }

    static func standard() -> LocalRecipeRepository {
        LocalRecipeRepository(
            catalogDirectory: Bundle.main.bundleURL.appending(path: "Catalog"),
            storageDirectory: URL.applicationSupportDirectory.appending(path: "Library")
        )
    }

    func listRecipes() throws -> [RecipeSummary] {
        try merged().map(\.summary)
    }

    func recipe(id: UUID) throws -> Recipe {
        guard let recipe = try merged().first(where: { $0.id == id }) else {
            throw LocalLibraryError.recipeNotFound
        }
        return recipe
    }

    func save(_ draft: RecipeDraft, replacing recipe: Recipe?) throws -> Recipe {
        var library = try library()
        let id = recipe?.id ?? UUID()
        let previousImage = recipe?.imageToken
        var imageToken = previousImage
        if let imageData = draft.imageData {
            imageToken = RecipeImageToken.local(try images.write(imageData, for: id)).rawValue
        }
        let stored = LocalRecipeDTO(
            id: id,
            draft: draft,
            totalMinutes: recipe?.totalMinutes,
            imageToken: imageToken,
            updatedAt: now()
        )
        library.recipes.removeAll { $0.id == id }
        library.recipes.append(stored)
        do {
            try persist(library)
        } catch {
            if imageToken != previousImage { removeLocalImage(imageToken) }
            throw error
        }
        if imageToken != previousImage { removeLocalImage(previousImage) }
        return try self.recipe(id: id)
    }

    func delete(id: UUID) throws {
        var library = try library()
        let removed = library.recipes.filter { $0.id == id }
        let removedEntries = library.journalEntries.filter { $0.recipeID == id }
        library.recipes.removeAll { $0.id == id }
        library.journalEntries.removeAll { $0.recipeID == id }
        if try builtInIDs().contains(id), !library.deletedBuiltInIDs.contains(id) {
            library.deletedBuiltInIDs.append(id)
        }
        try persist(library)
        removed.forEach { removeLocalImage($0.imageToken) }
        removedEntries.forEach { removeLocalImage($0.imageToken) }
    }

    func journalEntries() throws -> [JournalEntry] {
        try library().journalEntries.map(\.domain).sorted { $0.date > $1.date }
    }

    func addJournal(_ draft: JournalDraft, to recipeID: UUID) throws -> JournalEntry {
        guard try merged().contains(where: { $0.id == recipeID }) else {
            throw LocalLibraryError.recipeNotFound
        }
        var library = try library()
        let id = UUID()
        let imageToken = try draft.imageData.map { RecipeImageToken.local(try images.write($0, for: id)).rawValue }
        let stored = LocalJournalDTO(id: id, recipeID: recipeID, draft: draft.normalized, imageToken: imageToken)
        library.journalEntries.append(stored)
        do {
            try persist(library)
        } catch {
            removeLocalImage(imageToken)
            throw error
        }
        return stored.domain
    }

    func deleteJournal(id: UUID) throws {
        var library = try library()
        let removed = library.journalEntries.filter { $0.id == id }
        library.journalEntries.removeAll { $0.id == id }
        try persist(library)
        removed.forEach { removeLocalImage($0.imageToken) }
    }

    func restoreOriginal(id: UUID) throws -> Recipe {
        guard let original = try catalog().recipes.first(where: { $0.id == id }) else {
            throw LocalLibraryError.notBuiltIn
        }
        var library = try library()
        let removed = library.recipes.filter { $0.id == id }
        library.recipes.removeAll { $0.id == id }
        library.deletedBuiltInIDs.removeAll { $0 == id }
        try persist(library)
        removed.forEach { removeLocalImage($0.imageToken) }
        return original
    }

    func deletedBuiltInCount() throws -> Int {
        let ids = try builtInIDs()
        return try library().deletedBuiltInIDs.filter(ids.contains).count
    }

    func restoreDeletedBuiltIns() throws {
        var library = try library()
        library.deletedBuiltInIDs = []
        try persist(library)
    }

    func imageData(token: String) throws -> Data {
        switch RecipeImageToken(rawValue: token) {
        case .bundled(let key): try catalog().imageData(key: key)
        case .local(let filename): try images.read(filename)
        case nil: throw LocalLibraryError.recipeNotFound
        }
    }

    private func merged() throws -> [Recipe] {
        let catalog = try catalog().recipes
        let library = try library()
        let builtIn = Set(catalog.map(\.id))
        let deleted = Set(library.deletedBuiltInIDs)
        let overlay = library.recipes.sorted { $0.updatedAt > $1.updatedAt }
        let overridden = Set(overlay.map(\.id))
        let own = overlay.map { $0.domain(origin: builtIn.contains($0.id) ? .editedBuiltIn : .personal) }
        let untouched = catalog.filter { !deleted.contains($0.id) && !overridden.contains($0.id) }
        return own + untouched
    }

    private func catalog() throws -> BundledCatalog {
        if let cachedCatalog { return cachedCatalog }
        let catalog = try BundledCatalog(directory: catalogDirectory)
        cachedCatalog = catalog
        return catalog
    }

    private func builtInIDs() throws -> Set<UUID> {
        Set(try catalog().recipes.map(\.id))
    }

    private func library() throws -> LocalLibraryDTO {
        if let cachedLibrary { return cachedLibrary }
        let library = try file.load()
        cachedLibrary = library
        return library
    }

    private func persist(_ library: LocalLibraryDTO) throws {
        var library = library
        library.version = LocalLibraryDTO.currentVersion
        try file.save(library)
        cachedLibrary = library
    }

    private func removeLocalImage(_ token: String?) {
        guard let token, case .local(let filename) = RecipeImageToken(rawValue: token) else { return }
        images.remove(filename)
    }
}
