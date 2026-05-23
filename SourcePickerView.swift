import SwiftUI

struct SourcePickerView: View {
    @EnvironmentObject var player: MusicPlayerController
    @Binding var isPresented: Bool

    @State private var selectedMode: ShuffleMode = .fullLibrary
    @State private var selectedPlaylistID: String?
    @State private var selectedGenre: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Music Source")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button("Done") {
                    applySource()
                }
                .font(.system(size: 13, weight: .medium))
                .buttonStyle(.plain)
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().background(Color.white.opacity(0.15))

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(ShuffleMode.allCases) { mode in
                        modeRow(mode)
                    }

                    if selectedMode == .playlist {
                        playlistSection
                    } else if selectedMode == .genre {
                        genreSection
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 340)
        }
        .background(Color.black)
        .onAppear {
            selectedMode = player.source.mode
            selectedPlaylistID = player.source.playlistID
            selectedGenre = player.source.genreName
        }
    }

    // MARK: - Mode Row

    private func modeRow(_ mode: ShuffleMode) -> some View {
        Button {
            selectedMode = mode
        } label: {
            HStack {
                Image(systemName: mode.icon)
                    .font(.system(size: 14))
                    .frame(width: 24)
                Text(mode.rawValue)
                    .font(.system(size: 14))
                Spacer()
                if selectedMode == mode {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(selectedMode == mode ? Color.white.opacity(0.06) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    // MARK: - Playlist Section

    private var playlistSection: some View {
        VStack(spacing: 1) {
            if player.availablePlaylists.isEmpty {
                Text("No playlists found")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(player.availablePlaylists, id: \.id) { playlist in
                    Button {
                        selectedPlaylistID = playlist.id
                    } label: {
                        HStack {
                            Text(playlist.name)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            if selectedPlaylistID == playlist.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Genre Section

    private var genreSection: some View {
        VStack(spacing: 1) {
            if player.availableGenres.isEmpty {
                Text("No genres found")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(player.availableGenres, id: \.self) { genre in
                    Button {
                        selectedGenre = genre
                    } label: {
                        HStack {
                            Text(genre)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            if selectedGenre == genre {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Apply

    private func applySource() {
        var source = ShuffleSource()
        source.mode = selectedMode
        if selectedMode == .playlist {
            source.playlistID = selectedPlaylistID
            source.playlistName = player.availablePlaylists.first(where: { $0.id == selectedPlaylistID })?.name
        } else if selectedMode == .genre {
            source.genreName = selectedGenre
        }
        Task { await player.setSource(source) }
        isPresented = false
    }
}
