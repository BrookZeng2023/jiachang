import Foundation
import Observation

/// Turns a recipe or a selection into a file on this device, ready for the system share sheet.
@MainActor
@Observable
final class SharingService {
    private(set) var isWorking = false
    var problem: SharingError?

    private let library: RecipeLibrary
    private let loader: ShareContentLoader
    private let cardRenderer: any ShareCardRendering
    private let pdfWriter: any CookbookPDFWriting
    private let files: ExportFileStore

    init(
        library: RecipeLibrary,
        cardRenderer: any ShareCardRendering,
        pdfWriter: any CookbookPDFWriting,
        files: ExportFileStore = ExportFileStore()
    ) {
        self.library = library
        loader = ShareContentLoader(library: library)
        self.cardRenderer = cardRenderer
        self.pdfWriter = pdfWriter
        self.files = files
    }

    func makeCard(for summary: RecipeSummary, dedication: String, language: AppLanguage) async -> URL? {
        await run {
            let text = dedication.trimmingCharacters(in: .whitespacesAndNewlines)
            if let recipe = await self.library.detail(for: summary),
               text != (recipe.dedication ?? ""),
               await self.library.saveDedication(text, for: recipe) == nil {
                throw SharingError.saveFailed
            }
            let content = try await self.loader.card(for: summary, dedication: text, language: language)
            let data = try self.cardRenderer.pngData(for: content)
            return try self.files.store(data, kind: .card)
        }
    }

    func makeCookbook(
        from summaries: [RecipeSummary],
        title: String,
        dedication: String,
        language: AppLanguage
    ) async -> URL? {
        await run {
            let content = try await self.loader.cookbook(
                summaries: summaries,
                title: title,
                dedication: dedication,
                language: language
            )
            let writer = self.pdfWriter
            let data = try await Task.detached(priority: .userInitiated) {
                try writer.pdfData(for: content)
            }.value
            return try self.files.store(data, kind: .cookbook)
        }
    }

    private func run(_ work: @escaping @MainActor () async throws -> URL) async -> URL? {
        isWorking = true
        problem = nil
        defer { isWorking = false }
        do {
            return try await work()
        } catch is CancellationError {
            return nil
        } catch let error as SharingError {
            problem = error
            return nil
        } catch {
            problem = .fileFailed
            return nil
        }
    }
}
