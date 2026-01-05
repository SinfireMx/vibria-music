import SwiftUI

/// Compact metadata badge displaying:
/// ⏱ Total playlist duration  •  ♪ Number of tracks
///
/// Requirements:
/// - `TimeInterval.hmsString` extension for formatted duration output
/// - `AudioDurationCache` actor (defined in MusicPlayerViewModel.swift)
///
/// The view recalculates total duration asynchronously whenever
/// the playlist content changes.
struct PlaylistMetaBadge: View {

    /// List of audio file URLs belonging to the playlist
    let urls: [URL]

    /// Cached total duration of all tracks (in seconds)
    @State private var total: Double = 0

    /// Indicates whether duration calculation is in progress
    @State private var isLoading = true

    var body: some View {
        HStack(spacing: 8) {
            // Total playlist duration
            Label(isLoading ? "…" : total.hmsString, systemImage: "clock")
                .font(.caption2)

            // Number of tracks in the playlist
            Label("\(urls.count)", systemImage: "music.note.list")
                .font(.caption2)
        }
        .foregroundColor(Color.moda3.opacity(0.80))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.moda5.opacity(0.08))
        .cornerRadius(8)
        // Recalculate duration on appear and whenever `urls` changes
        .task(id: urls) {
            await recalc()
        }
    }

    /// Asynchronously recalculates the total duration of the playlist.
    /// Runs on the main actor to safely update view state.
    @MainActor
    private func recalc() async {
        isLoading = true
        let value = await AudioDurationCache.shared.totalDuration(for: urls)
        total = value
        isLoading = false
    }
}
