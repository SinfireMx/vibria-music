import SwiftUI

struct PlayerMainControlsView: View {
    var isPlaying: Bool
    var onPrev: (() -> Void)?
    var onPlayPause: (() -> Void)?
    var onNext: (() -> Void)?
    var isLandscape: Bool = false   // domyślnie portrait

    var body: some View {
        HStack(spacing: isLandscape ? 150 : 50) {
            Button(action: { onPrev?() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: isLandscape ? 30 : 34, weight: .bold))
                    .foregroundColor(.modaX(3))
            }
            Button(action: { onPlayPause?() }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: isLandscape ? 80 : 60, weight: .bold))
                    .foregroundColor(.modaX(3))
                    .shadow(radius: isLandscape ? 1 : 3, y: 1)
            }
            Button(action: { onNext?() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: isLandscape ? 30 : 34, weight: .bold))
                    .foregroundColor(.modaX(3))
            }
        }
        .padding(.top, isLandscape ? 1 : 6)
    }
}
