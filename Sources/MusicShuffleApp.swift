import SwiftUI
import MusicKit
import Observation
import AppKit

@main
struct MusicShuffleApp: App {
    @State private var model = LibraryModel()
    @State private var isFlipped = false

    var body: some Scene {
        MenuBarExtra {
            FlipWidget(model: model, isFlipped: $isFlipped)
                .frame(width: 250, height: 266)
                .fixedSize()
                .onOpenURL { url in
                    guard url.scheme == "musicshuffle", url.host == "shuffle" else { return }
                    Task { await model.shuffle() }
                }
        } label: {
            Image(systemName: model.isPlaying ? "waveform" : "shuffle")
                .contextMenu {
                    if model.phase == .ready {
                        Button("Shuffle Now") {
                            Task { await model.shuffle() }
                        }
                        if model.isPlaying {
                            Button("Stop Playback") {
                                model.stop()
                            }
                        }
                        Divider()
                    }
                    Button("Quit MusicShuffle", role: .destructive) {
                        NSApplication.shared.terminate(nil)
                    }
                }
        }
        .menuBarExtraStyle(.window)
    }
}

enum ShuffleSource: Equatable {
    case allSongs
    case recentlyAdded
    case playlist(MusicItemID, String)

    var title: String {
        switch self {
        case .allSongs: "All songs"
        case .recentlyAdded: "Recently added"
        case .playlist(_, let name): name
        }
    }
}

@MainActor
@Observable
final class LibraryModel {
    enum Phase: Equatable {
        case idle, authorizing, loading, ready, needsPermission, failed(String)
    }

    var phase: Phase = .idle
    var songs: [Song] = []
    var playlists: [Playlist] = []
    var currentTrack: Song?
    var isPlaying = false
    var statusText = "Tap the wheel to shuffle"
    var source: ShuffleSource = .allSongs

    private let pageSize = 50
    private let maxSongs = 250
    private var playlistTracks: [MusicItemID: [Song]] = [:]
    private var hasStarted = false

    var sourceCount: Int {
        switch source {
        case .allSongs: songs.count
        case .recentlyAdded: recentCount
        case .playlist(let id, _): playlistTracks[id]?.count ?? 0
        }
    }

    var recentCount: Int {
        songs.filter { $0.libraryAddedDate != nil }.count
    }

    func playlistCount(_ id: MusicItemID) -> Int? {
        playlistTracks[id]?.count
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        phase = .authorizing
        statusText = "Checking Apple Music access…"

        let status = await MusicAuthorization.request()
        guard status == .authorized else {
            phase = .needsPermission
            statusText = "Music access is off"
            return
        }
        await refreshLibrary()
    }

    func refreshLibrary() async {
        phase = .loading
        statusText = "Loading a small library sample…"
        do {
            async let loadedSongs = loadSongs()
            async let loadedPlaylists = loadPlaylists()
            songs = try await loadedSongs
            playlists = try await loadedPlaylists
            phase = .ready
            statusText = "Ready to shuffle"
        } catch {
            phase = .failed(error.localizedDescription)
            statusText = "Couldn’t read your library"
        }
    }

    func requestAccess() async {
        let status = await MusicAuthorization.request()
        if status == .authorized {
            await refreshLibrary()
        } else {
            phase = .needsPermission
            statusText = "Apple Music access is off"
        }
    }

    func shuffle() async {
        guard phase == .ready else { return }
        let pool: [Song]
        do {
            pool = try await songsForCurrentSource()
        } catch {
            statusText = "Couldn’t load that source"
            return
        }
        guard let next = pool.randomElement() else {
            statusText = "That source has no songs yet"
            return
        }

        do {
            let player = ApplicationMusicPlayer.shared
            player.queue = [next]
            try await player.play()
            currentTrack = next
            isPlaying = true
            statusText = "Playing now"
        } catch {
            statusText = "Playback unavailable"
        }
    }

    func stop() {
        ApplicationMusicPlayer.shared.stop()
        isPlaying = false
        currentTrack = nil
        statusText = "Ready to shuffle"
    }

    private func songsForCurrentSource() async throws -> [Song] {
        switch source {
        case .allSongs:
            return songs
        case .recentlyAdded:
            return songs.filter { $0.libraryAddedDate != nil }
        case .playlist(let id, _):
            if let cached = playlistTracks[id] {
                return cached
            } else if let playlist = playlists.first(where: { $0.id == id }) {
                let loaded = try await playlist.with(.entries)
                let tracks = loaded.entries?.compactMap { entry -> Song? in
                    guard case let .song(song) = entry.item else { return nil }
                    return song
                } ?? []
                playlistTracks[id] = tracks
                return tracks
            } else {
                return []
            }
        }
    }

    private func loadPlaylists() async throws -> [Playlist] {
        var result: [Playlist] = []
        var offset = 0
        while true {
            var request = MusicLibraryRequest<Playlist>()
            request.limit = pageSize
            request.offset = offset
            let page = Array(try await request.response().items)
            result.append(contentsOf: page)
            guard page.count == pageSize else { break }
            offset += page.count
        }
        return result
    }

    private func loadSongs() async throws -> [Song] {
        var result: [Song] = []
        var offset = 0
        while result.count < maxSongs {
            var request = MusicLibraryRequest<Song>()
            request.limit = min(pageSize, maxSongs - result.count)
            request.offset = offset
            let page = Array(try await request.response().items)
            result.append(contentsOf: page)
            guard page.count == request.limit else { break }
            offset += page.count
        }
        return result
    }
}

struct FlipWidget: View {
    @Bindable var model: LibraryModel
    @Binding var isFlipped: Bool

    var body: some View {
        ZStack {
            ShuffleFace(model: model, flip: { withAnimation(.smooth(duration: 0.45)) { isFlipped = true } })
                .frame(width: 250, height: 290, alignment: .topLeading)
                .opacity(isFlipped ? 0 : 1)
                .allowsHitTesting(!isFlipped)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            SettingsFace(model: model, flip: { withAnimation(.smooth(duration: 0.45)) { isFlipped = false } })
                .frame(width: 250, height: 290, alignment: .topLeading)
                .opacity(isFlipped ? 1 : 0)
                .allowsHitTesting(isFlipped)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .background(deviceSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
        .animation(.smooth(duration: 0.45), value: isFlipped)
        .task { await model.start() }
    }

    private var deviceSurface: some View {
        LinearGradient(
            colors: [Color.white.opacity(0.98), Color(red: 0.86, green: 0.86, blue: 0.84)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ShuffleFace: View {
    @Bindable var model: LibraryModel
    let flip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 2)

            StatusStrip(model: model)
                .padding(.horizontal, 18)
                .frame(height: 52)

            ShuffleWheel {
                Task { await model.shuffle() }
            }
            .padding(.top, 6)

            Button(action: flip) {
                ZStack {
                    Text(model.source.title)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 172, alignment: .center)
                        .multilineTextAlignment(.center)
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                    }
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.primary.opacity(0.72))
                .padding(.vertical, 7)
                .padding(.horizontal, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(width: 208, height: 34)
            .background(Color.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            }
            .help("Choose a shuffle source")
            .accessibilityLabel("Shuffle source: \(model.source.title)")
            .padding(.top, 6)

            HStack {
                Spacer()
                Button(action: flip) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Settings")
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 13)
            .padding(.top, 4)
            .frame(height: 26, alignment: .top)
        }
        .frame(width: 250, height: 290, alignment: .top)
    }
}

struct SettingsFace: View {
    @Bindable var model: LibraryModel
    let flip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: flip) { Image(systemName: "chevron.left") }
                    .buttonStyle(.plain)
                Text("Settings")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Spacer()
                if model.phase == .loading || model.phase == .authorizing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        Task { await model.refreshLibrary() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .help("Refresh library")
                    .accessibilityLabel("Refresh library")
                }
            }
            .padding(.bottom, 20)

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("SHUFFLE FROM")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .tracking(1.2)
                        .padding(.bottom, 9)

                    SourceRow(title: "All songs", detail: "\(model.songs.count) songs", isSelected: model.source == .allSongs) {
                        model.source = .allSongs
                    }
                    SourceRow(title: "Recently added", detail: "\(model.recentCount) songs", isSelected: model.source == .recentlyAdded) {
                        model.source = .recentlyAdded
                    }

                    if !model.playlists.isEmpty {
                        Text("PLAYLISTS")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(1.2)
                            .padding(.top, 20)
                            .padding(.bottom, 9)
                        ForEach(model.playlists, id: \.id) { playlist in
                            SourceRow(title: playlist.name, detail: model.playlistCount(playlist.id).map { "\($0) songs" } ?? "Playlist", isSelected: model.source == .playlist(playlist.id, playlist.name)) {
                                model.source = .playlist(playlist.id, playlist.name)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.visible)
            .frame(maxHeight: .infinity)

            HStack {
                Image(systemName: "music.note")
                Text(model.phase == .needsPermission ? "Allow Apple Music access to begin" : "Changes apply to the next shuffle")
            }
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
            .padding(.top, 10)
        }
        .padding(24)
        .frame(width: 250, height: 290, alignment: .topLeading)
    }
}

struct ShuffleWheel: View {
    let action: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.92))
                .overlay { Circle().stroke(Color.black.opacity(0.08), lineWidth: 1) }
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            Circle()
                .stroke(.primary.opacity(0.08), lineWidth: 1)
                .padding(18)
            Image(systemName: "shuffle")
                .font(.system(size: 27, weight: .medium))
                .foregroundStyle(.primary)
            Button(action: action) { Color.clear }
                .frame(width: 156, height: 156)
                .contentShape(Circle())
                .buttonStyle(WheelPressStyle())
                .accessibilityLabel("Shuffle")
                .zIndex(1)
            Image(systemName: "chevron.up")
                .font(.system(size: 11, weight: .semibold))
                .offset(y: -70)
                .foregroundStyle(.secondary)
                .allowsHitTesting(false)
            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .semibold))
                .offset(y: 70)
                .foregroundStyle(.secondary)
                .allowsHitTesting(false)
            Image(systemName: "chevron.left")
                .font(.system(size: 11, weight: .semibold))
                .offset(x: -70)
                .foregroundStyle(.secondary)
                .allowsHitTesting(false)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .offset(x: 70)
                .foregroundStyle(.secondary)
                .allowsHitTesting(false)
        }
        .frame(width: 156, height: 156)
    }
}

struct SourceRow: View {
    let title: String
    let detail: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.shuffleAccent : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                    Text(detail)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    func stripSurface() -> some View {
        padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.045), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            }
    }
}

struct WheelPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct StatusStrip: View {
    @Bindable var model: LibraryModel

    var body: some View {
        switch model.phase {
        case .authorizing, .loading:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text(model.statusText)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            .stripSurface()
        case .needsPermission:
            VStack(alignment: .leading, spacing: 5) {
                Text("Apple Music access is off")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                HStack(spacing: 10) {
                    Button("Grant access") {
                        Task { await model.requestAccess() }
                    }
                    .foregroundStyle(Color.shuffleAccent)
                    Button("Open Settings") {
                        openMediaPrivacyPane()
                    }
                    .foregroundStyle(.secondary)
                }
                .controlSize(.small)
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
            }
            .stripSurface()
        case .failed:
            HStack(spacing: 8) {
                Text(model.statusText)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 4)
                Button("Try again") {
                    Task { await model.refreshLibrary() }
                }
                .controlSize(.small)
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.shuffleAccent)
            }
            .stripSurface()
        case .idle, .ready:
            if let track = model.currentTrack {
                NowPlayingCard(track: track, isPlaying: model.isPlaying, onStop: { model.stop() })
                    .stripSurface()
            } else {
                HStack(spacing: 7) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.shuffleAccent)
                    Text(model.statusText)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                }
                .stripSurface()
            }
        }
    }

    private func openMediaPrivacyPane() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Media") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct NowPlayingCard: View {
    let track: Song
    let isPlaying: Bool
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            artwork
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                }
            VStack(alignment: .leading, spacing: 1) {
                Text(track.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(track.artistName)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 4)
            if isPlaying {
                Circle()
                    .fill(Color.shuffleLed)
                    .frame(width: 6, height: 6)
                    .shadow(color: Color.shuffleLed.opacity(0.55), radius: 2)
                    .accessibilityHidden(true)
            }
            Button(action: onStop) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .background(Color.black.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Stop playback")
            .accessibilityLabel("Stop playback")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var artwork: some View {
        Group {
            if let url = track.artwork?.url(width: 80, height: 80) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        artworkPlaceholder
                    @unknown default:
                        artworkPlaceholder
                    }
                }
            } else {
                artworkPlaceholder
            }
        }
    }

    private var artworkPlaceholder: some View {
        ZStack {
            Color(red: 0.94, green: 0.93, blue: 0.92)
            Image(systemName: "music.note")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.tertiary)
        }
    }
}

extension Color {
    static let shuffleAccent = Color(red: 0.44, green: 0.30, blue: 0.80)
    static let shuffleLed = Color(red: 0.20, green: 0.62, blue: 0.32)
}
