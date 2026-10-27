import SwiftUI

struct RecipeJournalSection: View {
    let recipe: RecipeSummary
    let addEntry: () -> Void

    @Environment(RecipeLibrary.self) private var library
    @Environment(\.appLanguage) private var language
    @State private var deleting: JournalEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                SectionHeading(title: copy(.journalHistory, language))
                Spacer()
                Button(action: addEntry) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.persimmon)
                        .frame(width: 42, height: 42)
                        .background(Color.paper)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.hairline, lineWidth: 1))
                }
                .accessibilityLabel(copy(.journalHistory, language))
                .accessibilityIdentifier("journal.new.section")
            }
            ForEach(library.entries(for: recipe.id)) { entry in
                VStack(alignment: .trailing, spacing: 4) {
                    JournalCard(entry: entry, recipe: recipe, compact: true)
                    Button(role: .destructive) { deleting = entry } label: {
                        Label(copy(.journalDelete, language), systemImage: "trash")
                            .font(.footnote)
                            .padding(10)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("journal.page.\(entry.id.uuidString)")
            }
        }
        .confirmationDialog(copy(.journalDeleteConfirm, language), isPresented: Binding(
            get: { deleting != nil },
            set: { if !$0 { deleting = nil } }
        ), titleVisibility: .visible) {
            if let deleting {
                Button(copy(.journalDelete, language), role: .destructive) {
                    Task { _ = await library.deleteJournal(deleting) }
                }
                .accessibilityIdentifier("journal.confirmDelete")
            }
        }
    }
}
