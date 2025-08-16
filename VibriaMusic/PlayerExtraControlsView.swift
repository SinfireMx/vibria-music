import SwiftUI

struct PlayerExtraControlsView: View {
    @Binding var isShuffling: Bool
    @Binding var loopMode: LoopMode
    var onLoopTap: (() -> Void)

    var body: some View {
        HStack(spacing: 160) {
            Button(action: { isShuffling.toggle() }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isShuffling ? .modaX(3) : .modaX(1).opacity(0.5))
            }
            Button(action: { onLoopTap() }) {
                loopIcon()
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func loopIcon() -> some View {
        if loopMode == .off {
            Image(systemName: "repeat")
                .foregroundColor(.modaX(1).opacity(0.5))
                .font(.system(size: 24, weight: .bold))
        } else if loopMode == .single {
            Image(systemName: "repeat.1")
                .foregroundColor(.modaX(3))
                .font(.system(size: 24, weight: .bold))
        } else if loopMode == .all {
            Image(systemName: "repeat")
                .foregroundColor(.modaX(3))
                .font(.system(size: 24, weight: .bold))
                .background(
                    Circle()
                        .stroke(Color.modaX(3), lineWidth: 2)
                        .frame(width: 30, height: 30)
                )
        }
    }
}
