import SwiftUI

/// Mała plakietka:  ⏱ 1:23:45  •  ♪ 12
/// Wymaga:
/// - TimeInterval.hmsString
/// - AudioDurationCache (async) z MusicPlayerViewModel.swift
struct PlaylistMetaBadge: View {
    let urls: [URL]
    @State private var total: Double = 0
    @State private var isLoading = true

    var body: some View {
        HStack(spacing: 8) {
            Label(isLoading ? "…" : total.hmsString, systemImage: "clock")
                .font(.caption2)
            Label("\(urls.count)", systemImage: "music.note.list")
                .font(.caption2)
        }
        .foregroundColor(Color.moda3.opacity(0.80))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.moda5.opacity(0.08))
        .cornerRadius(8)
        .task(id: urls) {     // odpala na starcie i przy każdej zmianie urls
            await recalc()
        }
    }

    @MainActor
    private func recalc() async {
        isLoading = true
        let value = await AudioDurationCache.shared.totalDuration(for: urls)
        total = value
        isLoading = false
    }
}
