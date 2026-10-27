import CoreText
import Foundation

/// Registers fonts shipped in the app bundle so SwiftUI can use them by name.
struct BundledFontRegistrar {
    var directory: URL = Bundle.main.bundleURL.appending(path: "Fonts")

    @discardableResult
    func registerAll() -> [String] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )) ?? []
        return files.filter { $0.pathExtension.lowercased() == "ttf" }.compactMap { file in
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(file as CFURL, .process, &error) { return file.lastPathComponent }
            // Re-registering after a scene restart reports "already registered"; that is fine.
            let code = error.map { CFErrorGetCode($0.takeRetainedValue()) }
            return code == CTFontManagerError.alreadyRegistered.rawValue ? file.lastPathComponent : nil
        }
    }
}
