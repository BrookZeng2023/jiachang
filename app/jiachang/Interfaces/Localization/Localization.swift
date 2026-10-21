import SwiftUI

enum CopyKey: String {
    case todayTab = "tab.today"
    case recipesTab = "tab.recipes"
    case tagline
    case server
    case username
    case password
    case enterKitchen = "onboarding.enter"
    case morning = "greeting.morning"
    case noon = "greeting.noon"
    case afternoon = "greeting.afternoon"
    case evening = "greeting.evening"
    case tonight = "home.tonight"
    case warmKitchen = "home.warmKitchen"
    case pick = "home.pick"
    case pickAgain = "home.pickAgain"
    case recent = "home.recent"
    case dishCount = "home.dishCount"
    case myKitchen = "library.myKitchen"
    case cookbook = "library.cookbook"
    case search = "library.search"
    case servings = "recipe.servings"
    case minutes = "recipe.minutes"
    case ingredients = "recipe.ingredients"
    case ingredientsHint = "recipe.ingredientsHint"
    case steps = "recipe.steps"
    case editRecipe = "recipe.edit"
    case deleteRecipe = "recipe.delete"
    case deleteConfirm = "recipe.deleteConfirm"
    case emptyTitle = "empty.title"
    case emptySubtitle = "empty.subtitle"
    case emptyAction = "empty.action"
    case newRecipe = "editor.new"
    case editTitle = "editor.edit"
    case cancel
    case changePhoto = "editor.changePhoto"
    case aboutDish = "editor.aboutDish"
    case recipeName = "editor.name"
    case recipeDescription = "editor.description"
    case howMany = "editor.howMany"
    case ingredientHint = "editor.ingredientHint"
    case ingredientPlaceholder = "editor.ingredientPlaceholder"
    case stepPlaceholder = "editor.stepPlaceholder"
    case saveNew = "editor.saveNew"
    case saveEdit = "editor.saveEdit"
    case settings
    case privateCookbook = "settings.privateCookbook"
    case account
    case reconnect
    case about
    case backendNote = "settings.backendNote"
    case language
}

private struct AppLanguageEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppLanguage.chinese
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageEnvironmentKey.self] }
        set { self[AppLanguageEnvironmentKey.self] = newValue }
    }
}

func copy(_ key: CopyKey, _ language: AppLanguage, _ arguments: CVarArg...) -> String {
    let bundle: Bundle
    if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
       let localized = Bundle(path: path) {
        bundle = localized
    } else {
        bundle = .main
    }
    let format = bundle.localizedString(forKey: key.rawValue, value: key.rawValue, table: nil)
    return String(format: format, locale: language.locale, arguments: arguments)
}
