import Foundation

/// One time a recipe was cooked: the page of the journal, as opposed to the
/// recipe itself, which stays relatively stable.
struct JournalEntry: Hashable, Identifiable {
    let id: UUID
    var recipeID: UUID
    var date: Date
    var note: String
    var cookedFor: String?
    var imageToken: String?

    var hasImage: Bool { !(imageToken ?? "").isEmpty }
}

struct JournalDraft {
    var date = Date()
    var note = ""
    var cookedFor = ""
    var imageData: Data?

    var normalized: JournalDraft {
        var value = self
        value.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        value.cookedFor = cookedFor.trimmingCharacters(in: .whitespacesAndNewlines)
        return value
    }
}

/// Journal entries live beside the recipes and always point back at one by id.
/// Deleting a recipe removes its entries.
protocol JournalRepository {
    func journalEntries() async throws -> [JournalEntry]
    func addJournal(_ draft: JournalDraft, to recipeID: UUID) async throws -> JournalEntry
    func deleteJournal(id: UUID) async throws
}
