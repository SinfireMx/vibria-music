import SwiftUI

struct PlayerSliderView: View {
    @Binding var progress: Double
    @Binding var duration: Double

    /// Called when user finishes dragging the slider
    var onSeek: ((Double) -> Void)?

    /// Called when slider editing state changes (true = dragging)
    var onEditingChanged: ((Bool) -> Void)?

    // Slider time display modes:
    // 0 = elapsed time
    // 1 = remaining time (with minus)
    // 2 = remaining time (no minus)
    // 3 = total duration
    @AppStorage("sliderTimeMode") var sliderTimeMode: Int = 0
    @AppStorage("rememberSliderTimeMode") var rememberSliderTimeMode: Bool = true

    /// Stores the last value dragged by the user
    /// (used to commit seek only once after release)
    @State private var lastDraggedValue: Double = 0.0

    var body: some View {
        VStack(spacing: 2) {

            // Time label above the slider (premium-style display)
            HStack {
                Spacer()

                Text(currentTimeText)
                    .font(.system(size: 21, weight: .semibold, design: .serif))
                    .foregroundColor(.modaX(3))
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                    .padding(.bottom, 4)
                    // Tap cycles through time display modes
                    .onTapGesture {
                        sliderTimeMode = (sliderTimeMode + 1) % 4
                    }

                Spacer()
            }

            // Playback slider
            Slider(
                value: $progress,
                in: 0...duration,
                onEditingChanged: { editing in
                    // Notify parent view about editing state
                    onEditingChanged?(editing)

                    // Commit seek only when user releases the slider
                    if !editing {
                        onSeek?(lastDraggedValue)
                    }
                }
            )
            // Track slider changes to store last dragged value
            .onChange(of: progress) { newValue in
                lastDraggedValue = newValue
            }
            .accentColor(.modaX(3))
            .frame(height: 28)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .onAppear {
            // Reset time mode if user disabled persistence
            if !rememberSliderTimeMode {
                sliderTimeMode = 0
            }
        }
    }

    // MARK: - Time display logic

    /// Returns the text shown above the slider
    private var currentTimeText: String {
        switch sliderTimeMode {
        case 0: // Elapsed time
            return formatTime(progress)

        case 1: // Remaining time (with minus sign)
            return "-" + formatTime(duration - progress)

        case 2: // Remaining time (no minus)
            return formatTime(duration - progress)

        case 3: // Total duration
            return formatTime(duration)

        default:
            return formatTime(progress)
        }
    }

    /// Formats seconds into mm:ss
    private func formatTime(_ t: Double) -> String {
        guard !t.isNaN && !t.isInfinite else { return "--:--" }
        let min = Int(abs(t)) / 60
        let sec = Int(abs(t)) % 60
        return String(format: "%d:%02d", min, sec)
    }
}
