import SwiftUI

enum CopyKey: String {
    case todayTab = "tab.today"
    case recipesTab = "tab.recipes"
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
    case restoreOriginal = "recipe.restoreOriginal"
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
    case takePhoto = "photo.take"
    case chooseFromLibrary = "photo.library"
    case cameraDenied = "photo.denied"
    case cameraUnavailable = "photo.unavailable"
    case openSettings = "photo.settings"
    case photoLoadFailed = "photo.failed"
    case settings
    case settingsHint = "settings.hint"
    case privateCookbook = "settings.privateCookbook"
    case language
    case starterRecipes = "settings.starterRecipes"
    case restoreDeleted = "settings.restoreDeleted"
    case restoreDeletedTitle = "settings.restoreDeletedTitle"
    case restoreDeletedMessage = "settings.restoreDeletedMessage"
    case restoreDeletedAction = "settings.restoreDeletedAction"
    case storageNote = "settings.storageNote"
    case developerMessage = "settings.developerMessage"
    case developerMessageBody = "settings.developerMessageBody"
    case privacyTitle = "about.privacy"
    case privacyLocalBody = "about.privacy.local"
    case privacyBackupBody = "about.privacy.backup"
    case privacyTransferBody = "about.privacy.transfer"
    case permissionsTitle = "about.permissions"
    case cameraPermissionBody = "about.permissions.camera"
    case photoPermissionBody = "about.permissions.photos"
    case foodSafetyTitle = "about.foodSafety"
    case foodSafetyBody = "about.foodSafety.body"
    case licensesTitle = "about.licenses"
    case starterContentBody = "about.licenses.starter"
    case softwareLicenseBody = "about.licenses.software"
    case userPhotosBody = "about.licenses.userPhotos"
    case loadProblem = "problem.load"
    case saveProblem = "problem.save"
    case deleteProblem = "problem.delete"
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
