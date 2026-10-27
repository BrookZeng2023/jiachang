import SwiftUI

struct CookJournalEditorView: View {
    let recipe: RecipeSummary

    @Environment(RecipeLibrary.self) private var library
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @State private var draft = JournalDraft()
    @State private var isSaving = false
    @State private var failed = false
    private enum Field: Hashable { case cookedFor, note }
    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(recipe.localizedName(language))
                        .font(JiachangFont.emotional(30))
                        .foregroundStyle(Color.ink)
                    DatePicker(copy(.journalDate, language), selection: $draft.date, displayedComponents: [.date, .hourAndMinute])
                    WarmTextField(title: copy(.journalFor, language), text: $draft.cookedFor)
                        .accessibilityIdentifier("journal.cookedFor")
                        .focused($focusedField, equals: .cookedFor)
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeading(title: copy(.journalNote, language))
                        WarmTextField(title: copy(.journalNoteHint, language), text: $draft.note, axis: .vertical)
                            .font(JiachangFont.emotional(18))
                            .lineLimit(5...12)
                            .accessibilityIdentifier("journal.note")
                            .focused($focusedField, equals: .note)
                    }
                    EditorPhotoPicker(existing: nil, imageData: $draft.imageData)
                    if failed { ProblemText(problem: .save) }
                    Button {
                        isSaving = true
                        Task {
                            let entry = await library.addJournal(draft, to: recipe.id)
                            isSaving = false
                            failed = entry == nil
                            if entry != nil { dismiss() }
                        }
                    } label: {
                        if isSaving { ProgressView().tint(.white) }
                        else { Text(copy(.journalSave, language)) }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("journal.save")
                }
                .padding(20)
                .disabled(isSaving)
            }
            .background(Color.cream)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(copy(.journalHistory, language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(copy(.finishEditing, language)) { focusedField = nil }
                        .accessibilityIdentifier("journal.finishEditing")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(copy(.cancel, language)) { dismiss() }.disabled(isSaving)
                }
            }
        }
        .interactiveDismissDisabled(isSaving)
    }
}
