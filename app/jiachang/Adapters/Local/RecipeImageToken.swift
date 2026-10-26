import Foundation

/// Opaque image reference stored on a recipe: either a catalog photo or a user photo on disk.
enum RecipeImageToken: Equatable {
    case bundled(String)
    case local(String)

    init?(rawValue: String) {
        if rawValue.hasPrefix("bundle:") {
            self = .bundled(String(rawValue.dropFirst("bundle:".count)))
        } else if rawValue.hasPrefix("local:") {
            self = .local(String(rawValue.dropFirst("local:".count)))
        } else {
            return nil
        }
    }

    var rawValue: String {
        switch self {
        case .bundled(let key): "bundle:\(key)"
        case .local(let filename): "local:\(filename)"
        }
    }
}
