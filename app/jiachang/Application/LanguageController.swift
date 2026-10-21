import Foundation
import Observation

@Observable
final class LanguageController {
    var current: AppLanguage {
        didSet { defaults.set(current.rawValue, forKey: key) }
    }

    private let defaults: UserDefaults
    private let key = "appLanguage"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let saved = defaults.string(forKey: key), let language = AppLanguage(rawValue: saved) {
            current = language
        } else {
            current = Locale.current.language.languageCode?.identifier == "zh" ? .chinese : .english
        }
    }
}
