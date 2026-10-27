import Foundation

/// Everything a share card needs, gathered before rendering so the renderer stays pure.
struct ShareCardContent: Sendable {
    let recipe: Recipe
    let imageData: Data?
    let dedication: String
    let language: AppLanguage
}

struct CookbookRecipeContent: Sendable {
    let recipe: Recipe
    let imageData: Data?
    let latestJournal: JournalEntry?
    /// Pre-localized "2 人份 · 15 分钟" line.
    let meta: String
    /// Pre-localized date for the journal excerpt.
    let journalDate: String?
}

/// Pre-localized labels so the PDF writer stays free of the string table.
struct CookbookStrings: Sendable {
    let contents: String
    let ingredients: String
    let method: String
    let latestNote: String
    let continued: String
    let brand: String
}

struct CookbookContent: Sendable {
    let title: String
    let dedication: String
    let recipes: [CookbookRecipeContent]
    let strings: CookbookStrings
    let coverDate: String
}

enum SharingError: Error, Equatable {
    case emptySelection
    case recipeUnavailable
    case saveFailed
    case renderFailed
    case fileFailed
}

/// Output ports. Interfaces render the card; Adapters write the PDF and the file.
@MainActor
protocol ShareCardRendering {
    func pngData(for content: ShareCardContent) throws -> Data
}

protocol CookbookPDFWriting: Sendable {
    func pdfData(for content: CookbookContent) throws -> Data
}
