import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }
    var locale: Locale { Locale(identifier: rawValue) }
    var displayName: String { self == .chinese ? "中文" : "English" }
}

extension String {
    func localizedContent(_ language: AppLanguage) -> String {
        let parts = components(separatedBy: " · ")
        guard parts.count >= 2 else { return self }
        if language == .chinese { return parts[0].trimmingCharacters(in: .whitespaces) }
        return parts.dropFirst().joined(separator: " · ").trimmingCharacters(in: .whitespaces)
    }
}

extension RecipeSummary {
    func localizedName(_ language: AppLanguage) -> String { name.localizedContent(language) }
    func localizedDescription(_ language: AppLanguage) -> String? { description?.localizedContent(language) }
}

extension RecipeIngredient {
    func localizedText(_ language: AppLanguage) -> String { text.localizedContent(language) }
}

extension RecipeInstruction {
    func localizedTitle(_ language: AppLanguage) -> String? { title?.localizedContent(language) }
    func localizedText(_ language: AppLanguage) -> String { text.localizedContent(language) }
}
