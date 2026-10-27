import Foundation

/// JSON file holding the user's overlay. An unreadable file is moved aside, never overwritten.
struct LocalLibraryFile {
    let url: URL

    func load() throws -> LocalLibraryDTO {
        guard FileManager.default.fileExists(atPath: url.path) else { return LocalLibraryDTO() }
        let data = try Data(contentsOf: url)
        do {
            return try Self.decoder.decode(LocalLibraryDTO.self, from: data)
        } catch {
            let stamp = Int(Date().timeIntervalSince1970)
            let backup = url.deletingPathExtension().appendingPathExtension("unreadable-\(stamp).json")
            try FileManager.default.moveItem(at: url, to: backup)
            return LocalLibraryDTO()
        }
    }

    func save(_ library: LocalLibraryDTO) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Self.encoder.encode(library).write(to: url, options: .atomic)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

/// User photos stored next to the library file.
struct LocalImageStore {
    let directory: URL

    func write(_ data: Data, for recipeID: UUID) throws -> String {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = "\(recipeID.uuidString)-\(UUID().uuidString.prefix(8)).jpg"
        try data.write(to: directory.appending(path: filename), options: .atomic)
        return filename
    }

    func read(_ filename: String) throws -> Data {
        try Data(contentsOf: directory.appending(path: filename))
    }

    func remove(_ filename: String) {
        try? FileManager.default.removeItem(at: directory.appending(path: filename))
    }
}
