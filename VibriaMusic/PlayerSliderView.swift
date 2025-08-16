import SwiftUI

struct PlayerSliderView: View {
    @Binding var progress: Double
    @Binding var duration: Double
    var onSeek: ((Double) -> Void)?
    var onEditingChanged: ((Bool) -> Void)?

    // 0: Czas miniony, 1: Do końca, 2: Od końca (bez minusa), 3: Całkowity czas
    @AppStorage("sliderTimeMode") var sliderTimeMode: Int = 0
    @AppStorage("rememberSliderTimeMode") var rememberSliderTimeMode: Bool = true

    @State private var lastDraggedValue: Double = 0.0

    var body: some View {
        VStack(spacing: 2) {
            // CZAS NAD SLIDEREM — PREMIUM
            HStack {
                Spacer()
                Text(currentTimeText)
                    .font(.system(size: 21, weight: .semibold, design: .serif))
                    .foregroundColor(.modaX(3))
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                    .padding(.bottom, 4)
                    .onTapGesture {
                        sliderTimeMode = (sliderTimeMode + 1) % 4
                    }
                Spacer()
            }
            // SLIDER
            Slider(
                value: $progress,
                in: 0...duration,
                onEditingChanged: { editing in
                    onEditingChanged?(editing)
                    if !editing {
                        onSeek?(lastDraggedValue)
                    }
                }
            )
            .onChange(of: progress) { newValue in
                lastDraggedValue = newValue
            }
            .accentColor(.modaX(3))
            .frame(height: 28)
            // (jeśli chcesz dodać tekst pod suwakiem – np. całkowity czas – możesz dodać tu HStack jak wyżej)
        }
        .padding(.horizontal, 24)
//        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .onAppear {
            if !rememberSliderTimeMode {
                sliderTimeMode = 0
            }
        }
    }


    // Funkcja do wyboru co wyświetlać pod suwakiem
    private var currentTimeText: String {
        switch sliderTimeMode {
        case 0: // Czas miniony
            return formatTime(progress)
        case 1: // Czas do końca (z minusem)
            return "-" + formatTime(duration - progress)
        case 2: // Od końca (bez minusa)
            return formatTime(duration - progress)
        case 3: // Całkowity czas
            return formatTime(duration)
        default:
            return formatTime(progress)
        }
    }

    private func formatTime(_ t: Double) -> String {
        guard !t.isNaN && !t.isInfinite else { return "--:--" }
        let min = Int(abs(t)) / 60
        let sec = Int(abs(t)) % 60
        return String(format: "%d:%02d", min, sec)
    }
}
