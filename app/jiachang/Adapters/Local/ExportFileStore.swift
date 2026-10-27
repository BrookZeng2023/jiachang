import Foundation

/// Share files live in the temporary directory: they are not backups and can be recreated.
struct ExportFileStore: Sendable {
    enum Kind: Sendable {
        case card
        case cookbook

        var slug: String { self == .card ? "dish" : "cookbook" }
        var fileExtension: String { self == .card ? "png" : "pdf" }
    }

    private let directory: URL

    init(directory: URL = URL.temporaryDirectory.appending(path: "JiachangExports")) {
        self.directory = directory
    }

    func store(_ data: Data, kind: Kind, now: Date = Date()) throws -> URL {
        let manager = FileManager.default
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        prune(manager: manager, now: now)
        let name = "jiachang-\(kind.slug)-\(Self.stamp.string(from: now)).\(kind.fileExtension)"
        let url = directory.appending(path: name)
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Old exports are only share history; keep the folder from growing without bound.
    private func prune(manager: FileManager, now: Date) {
        guard let files = try? manager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }
        let cutoff = now.addingTimeInterval(-24 * 60 * 60)
        for file in files {
            let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            if let modified, modified < cutoff {
                try? manager.removeItem(at: file)
            }
        }
    }

    private static let stamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}
