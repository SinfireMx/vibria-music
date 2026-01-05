import SwiftUI

struct PlayerMainControlsView: View {
    let isPlaying: Bool
    let onPrev: (() -> Void)?
    let onPlayPause: (() -> Void)?
    let onNext: (() -> Void)?
    var isLandscape: Bool = false   // default: portrait

    var body: some View {
        HStack {
            prevButton
            Spacer(minLength: isLandscape ? 80 : 24)
            playPauseButton
            Spacer(minLength: isLandscape ? 80 : 24)
            nextButton
        }
        .padding(.top, isLandscape ? 1 : 6)
        .padding(.horizontal)
    }

    // MARK: - Buttons

    private var prevButton: some View {
        Button(action: { onPrev?() }) {
            Image(systemName: "backward.fill")
                .font(.system(size: isLandscape ? 30 : 34, weight: .bold))
                .foregroundColor(.modaX(3))
        }
        .accessibilityLabel("Previous track")
        .disabled(onPrev == nil)
        .opacity(onPrev == nil ? 0.4 : 1)
    }

    private var playPauseButton: some View {
        Button(action: { onPlayPause?() }) {
            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: isLandscape ? 80 : 60, weight: .bold))
                .foregroundColor(.modaX(3))
                .shadow(radius: isLandscape ? 1 : 3, y: 1)
        }
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
        .disabled(onPlayPause == nil)
        .opacity(onPlayPause == nil ? 0.4 : 1)
    }

    private var nextButton: some View {
        Button(action: { onNext?() }) {
            Image(systemName: "forward.fill")
                .font(.system(size: isLandscape ? 30 : 34, weight: .bold))
                .foregroundColor(.modaX(3))
        }
        .accessibilityLabel("Next track")
        .disabled(onNext == nil)
        .opacity(onNext == nil ? 0.4 : 1)
    }
}
