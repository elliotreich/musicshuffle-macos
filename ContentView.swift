import SwiftUI
import MusicKit

struct ContentView: View {
    @EnvironmentObject var player: MusicPlayerController
    @State private var showSourcePicker = false

    var body: some View {
        Group {
            if !player.isAuthorized {
                authView
            } else if showSourcePicker {
                SourcePickerView(isPresented: $showSourcePicker)
                    .environmentObject(player)
                    .transition(.move(edge: .trailing))
            } else {
                playerView
                    .transition(.move(edge: .leading))
            }
        }
        .frame(width: 280)
        .background(Color.black)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.2), value: showSourcePicker)
    }

    // MARK: - Auth

    private var authView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 48))
                .foregroundColor(.white)
            Text("Music Access Required")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text("MusicShuffle needs permission to access your Apple Music library.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Grant Access") {
                Task { await player.checkAuthorization() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
    }

    // MARK: - Player

    private var playerView: some View {
        VStack(spacing: 0) {
            trackInfo
                .padding(.top, 20)
                .padding(.bottom, 16)

            if player.isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.8)
                    .padding(.bottom, 8)
            } else if let error = player.error {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            ClickWheel(
                isPlaying: player.isPlaying,
                onPlayPause: { player.togglePlayPause() },
                onNext: { Task { await player.playNext() } },
                onPrevious: { Task { await player.playPrevious() } },
                onVolumeUp: { player.volumeUp() },
                onVolumeDown: { player.volumeDown() }
            )
            .padding(.bottom, 20)

            Divider().background(Color.white.opacity(0.15))

            Button {
                showSourcePicker = true
            } label: {
                HStack {
                    Image(systemName: player.source.icon)
                        .font(.system(size: 12))
                    Text(player.source.displayName)
                        .font(.system(size: 13))
                    Spacer()
                    Text("\(player.trackCount) tracks")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            Divider().background(Color.white.opacity(0.15))

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit MusicShuffle")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Track Info

    private var trackInfo: some View {
        VStack(spacing: 8) {
            if let track = player.currentTrack, let artwork = track.artwork {
                AsyncImage(url: artwork.url(width: 80, height: 80)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    artworkPlaceholder
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4)
            } else {
                artworkPlaceholder
            }

            if let track = player.currentTrack {
                Text(track.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(track.artistName)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            } else {
                Text("Ready to Shuffle")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(white: 0.15))
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 24))
                    .foregroundColor(Color(white: 0.35))
            )
    }
}

// MARK: - Click Wheel

struct ClickWheel: View {
    let isPlaying: Bool
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onVolumeUp: () -> Void
    let onVolumeDown: () -> Void

    private let diameter: CGFloat = 200
    private let centerSize: CGFloat = 68
    private let iconDistance: CGFloat = 60

    var body: some View {
        ZStack {
            // Outer wheel
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.26), Color(white: 0.18)],
                        center: .center,
                        startRadius: 20,
                        endRadius: 100
                    )
                )
                .frame(width: diameter, height: diameter)
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)

            // Subtle edge ring
            Circle()
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: diameter, height: diameter)

            // Volume up (top)
            wheelButton("plus", size: 13, offset: .init(width: 0, height: -iconDistance), action: onVolumeUp)
            // Volume down (bottom)
            wheelButton("minus", size: 15, offset: .init(width: 0, height: iconDistance), action: onVolumeDown)
            // Previous (left)
            wheelButton("backward.fill", size: 14, offset: .init(width: -iconDistance, height: 0), action: onPrevious)
            // Next (right)
            wheelButton("forward.fill", size: 14, offset: .init(width: iconDistance, height: 0), action: onNext)

            // Center play/pause
            Button(action: onPlayPause) {
                Circle()
                    .fill(Color(white: 0.30))
                    .frame(width: centerSize, height: centerSize)
                    .overlay(
                        Circle().strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
                    .overlay(
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .offset(x: isPlaying ? 0 : 2)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
            }
            .buttonStyle(.plain)
        }
        .frame(width: diameter, height: diameter)
    }

    private func wheelButton(_ icon: String, size: CGFloat, offset: CGSize, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .offset(offset)
    }
}
