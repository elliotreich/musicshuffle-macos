import Foundation

enum ShuffleMode: String, Codable, CaseIterable, Identifiable {
    case fullLibrary = "Full Library"
    case playlist = "Playlist"
    case genre = "Genre"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fullLibrary: return "music.note.list"
        case .playlist: return "music.note.house"
        case .genre: return "guitars"
        }
    }
}

struct ShuffleSource: Codable, Equatable {
    var mode: ShuffleMode = .fullLibrary
    var playlistID: String?
    var playlistName: String?
    var genreName: String?

    var displayName: String {
        switch mode {
        case .fullLibrary: return "Full Library"
        case .playlist: return playlistName ?? "Select Playlist"
        case .genre: return genreName ?? "Select Genre"
        }
    }

    var icon: String { mode.icon }

    static func save(_ source: ShuffleSource) {
        if let data = try? JSONEncoder().encode(source) {
            UserDefaults.standard.set(data, forKey: "shuffleSource")
        }
    }

    static func load() -> ShuffleSource {
        guard let data = UserDefaults.standard.data(forKey: "shuffleSource"),
              let source = try? JSONDecoder().decode(ShuffleSource.self, from: data)
        else { return ShuffleSource() }
        return source
    }
}
