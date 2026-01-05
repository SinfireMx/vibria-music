import SwiftUI

struct PlayerExtraControlsView: View {
    @Binding var isShuffling: Bool
    @Binding var loopMode: LoopMode
    let onLoopTap: () -> Void

    var body: some View {
        HStack {
            shuffleButton
            Spacer()
            loopButton
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // MARK: - Buttons

    private var shuffleButton: some View {
        Button(action: { isShuffling.toggle() }) {
            Image(systemName: "shuffle")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(isShuffling ? .modaX(3) : .modaX(1).opacity(0.5))
        }
        .accessibilityLabel("Shuffle")
        .accessibilityValue(isShuffling ? "On" : "Off")
    }

    private var loopButton: some View {
        Button(action: onLoopTap) {
            loopIcon
                .font(.system(size: 24, weight: .bold))
        }
        .accessibilityLabel("Loop")
        .accessibilityValue(loopModeDescription)
    }

    // MARK: - Loop icon

    @ViewBuilder
    private var loopIcon: some View {
        switch loopMode {
        case .off:
            Image(systemName: "repeat")
                .foregroundColor(.modaX(1).opacity(0.5))

        case .single:
            Image(systemName: "repeat.1")
                .foregroundColor(.modaX(3))

        case .all:
            Image(systemName: "repeat")
                .foregroundColor(.modaX(3))
                .overlay(
                    Circle()
                        .stroke(Color.modaX(3), lineWidth: 2)
                        .frame(width: 30, height: 30)
                )
        }
    }

    private var loopModeDescription: String {
        switch loopMode {
        case .off: return "Off"
        case .single: return "Single"
        case .all: return "All"
        }
    }
}
