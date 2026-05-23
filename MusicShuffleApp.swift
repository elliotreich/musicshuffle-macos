import SwiftUI
import MusicKit

@main
struct MusicShuffleApp: App {
    @StateObject private var player = MusicPlayerController()

    var body: some Scene {
        MenuBarExtra("MusicShuffle", systemImage: "shuffle") {
            ContentView()
                .environmentObject(player)
        }
        .menuBarExtraStyle(.window)
    }
}
