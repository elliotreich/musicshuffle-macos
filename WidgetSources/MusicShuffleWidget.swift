import SwiftUI
import WidgetKit

struct MusicShuffleEntry: TimelineEntry {
    let date: Date
}

struct MusicShuffleProvider: TimelineProvider {
    func placeholder(in context: Context) -> MusicShuffleEntry { MusicShuffleEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (MusicShuffleEntry) -> Void) {
        completion(MusicShuffleEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MusicShuffleEntry>) -> Void) {
        completion(Timeline(entries: [MusicShuffleEntry(date: .now)], policy: .after(.now.addingTimeInterval(900))))
    }
}

struct MusicShuffleWidgetView: View {
    let entry: MusicShuffleEntry

    var body: some View {
        Link(destination: URL(string: "musicshuffle://shuffle")!) {
            ZStack {
                Color.white.opacity(0.96)
                Circle()
                    .fill(Color.white)
                    .overlay { Circle().stroke(Color.black.opacity(0.08), lineWidth: 1) }
                    .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
                    .padding(15)
                Circle()
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    .padding(32)
                Image(systemName: "shuffle")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .semibold))
                    .offset(y: -49)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .offset(y: 49)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .semibold))
                    .offset(x: -49)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .offset(x: 49)
                    .foregroundStyle(.secondary)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.white, Color(red: 0.86, green: 0.86, blue: 0.84)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct MusicShuffleWidget: Widget {
    let kind = "MusicShuffleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MusicShuffleProvider()) { entry in
            MusicShuffleWidgetView(entry: entry)
        }
        .configurationDisplayName("MusicShuffle")
        .description("Tap the shuffle dial to pick a song from your Apple Music library.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct MusicShuffleWidgetBundle: WidgetBundle {
    var body: some Widget {
        MusicShuffleWidget()
    }
}
