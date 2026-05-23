import Foundation
import MusicKit

@MainActor
class MusicPlayerController: ObservableObject {
    @Published var currentTrack: Track?
    @Published var isPlaying = false
    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var trackCount = 0
    @Published var source: ShuffleSource
    @Published var availablePlaylists: [(id: String, name: String)] = []
    @Published var availableGenres: [String] = []

    private let player = ApplicationMusicPlayer.shared
    private var tracks: [Track] = []
    private var currentIndex = -1
    private var history: [Track] = []

    init() {
        self.source = ShuffleSource.load()
        Task { await checkAuthorization() }
    }

    func checkAuthorization() async {
        let status = await MusicAuthorization.request()
        isAuthorized = status == .authorized
        if isAuthorized {
            await loadOptions()
            await loadTracks()
            if !tracks.isEmpty { await playNext() }
        }
    }

    // MARK: - Source Management

    func loadOptions() async {
        async let p: () = loadPlaylists()
        async let g: () = loadGenres()
        _ = await (p, g)
    }

    private func loadPlaylists() async {
        do {
            var request = MusicLibraryRequest<Playlist>()
            request.limit = 200
            let response = try await request.response()
            availablePlaylists = response.items.map { (id: $0.id.rawValue, name: $0.name) }
        } catch {
            print("Failed to load playlists: \(error)")
        }
    }

    private func loadGenres() async {
        do {
            var request = MusicLibraryRequest<Track>()
            request.limit = 10000
            let response = try await request.response()
            let genres = Set(response.items.compactMap { $0.genreNames.first })
            availableGenres = genres.sorted()
        } catch {
            print("Failed to load genres: \(error)")
        }
    }

    func setSource(_ newSource: ShuffleSource) async {
        source = newSource
        ShuffleSource.save(newSource)
        await loadTracks()
        if !tracks.isEmpty { await playNext() }
    }

    // MARK: - Track Loading

    func loadTracks() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            switch source.mode {
            case .fullLibrary:
                tracks = try await fetchAllTracks()
            case .playlist:
                guard let id = source.playlistID else { tracks = []; return }
                tracks = try await fetchPlaylistTracks(id: id)
            case .genre:
                guard let genre = source.genreName else { tracks = []; return }
                tracks = try await fetchTracksByGenre(genre)
            }
            trackCount = tracks.count
            tracks.shuffle()
            currentIndex = -1
            history = []
        } catch {
            self.error = "Failed to load: \(error.localizedDescription)"
        }
    }

    private func fetchAllTracks() async throws -> [Track] {
        var request = MusicLibraryRequest<Track>()
        request.limit = 10000
        let response = try await request.response()
        return Array(response.items)
    }

    private func fetchPlaylistTracks(id: String) async throws -> [Track] {
        var request = MusicLibraryRequest<Playlist>()
        request.limit = 200
        let response = try await request.response()
        guard let playlist = response.items.first(where: { $0.id.rawValue == id }) else { return [] }
        let detailed = try await playlist.with([.tracks])
        guard let tracks = detailed.tracks else { return [] }
        return Array(tracks)
    }

    private func fetchTracksByGenre(_ genre: String) async throws -> [Track] {
        var request = MusicLibraryRequest<Track>()
        request.limit = 10000
        let response = try await request.response()
        return response.items.filter { $0.genreNames.contains(genre) }
    }

    // MARK: - Playback

    func playNext() async {
        guard !tracks.isEmpty else { return }
        if let current = currentTrack { history.append(current) }
        currentIndex += 1
        if currentIndex >= tracks.count {
            tracks.shuffle()
            currentIndex = 0
        }
        await play(tracks[currentIndex])
    }

    func playPrevious() async {
        if let prev = history.popLast() {
            currentIndex = max(currentIndex - 1, 0)
            await play(prev)
        }
    }

    private func play(_ track: Track) async {
        currentTrack = track
        do {
            player.queue = [track]
            try await player.play()
            isPlaying = true
        } catch {
            self.error = "Playback error: \(error.localizedDescription)"
        }
    }

    func togglePlayPause() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            Task {
                if currentTrack != nil {
                    try? await player.play()
                    isPlaying = true
                } else {
                    await playNext()
                }
            }
        }
    }

    // MARK: - Volume

    func volumeUp() {
        adjustVolume(by: 6)
    }

    func volumeDown() {
        adjustVolume(by: -6)
    }

    private func adjustVolume(by delta: Int) {
        let script = "set volume output volume ((output volume of (get volume settings)) + \(delta))"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }
}
