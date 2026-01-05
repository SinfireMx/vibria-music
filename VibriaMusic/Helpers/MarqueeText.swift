import SwiftUI

/// A marquee (scrolling) single-line text view.
/// - Auto-enables scrolling only when the text is wider than its container.
/// - Uses a fade mask on both edges for a polished look.
/// - Supports manual drag to scrub the position (pauses and resumes animation).
struct MarqueeText: View {
    let text: String
    let font: Font
    let duration: Double
    let horizontalPadding: CGFloat

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0

    /// Temporary drag offset applied on top of `offset`.
    @State private var dragOffset: CGFloat = 0

    /// Indicates user interaction; pauses the marquee while dragging.
    @State private var isDragging = false

    /// Internal animation state.
    @State private var animating = false

    /// Direction toggle for the ping-pong behavior.
    @State private var goingForward = true

    /// Scroll only when content does not fit.
    var shouldAnimate: Bool {
        textWidth > containerWidth
    }

    /// Bounds for manual scrubbing and animation limits.
    var minOffset: CGFloat { -(textWidth - containerWidth) }
    var maxOffset: CGFloat { 0 }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {

                // Hidden measuring text used to capture the intrinsic width via PreferenceKey.
                Text(text)
                    .font(font)
                    .fixedSize()
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: TextWidthKey.self, value: proxy.size.width)
                        }
                    )
                    .hidden()

                Group {
                    if shouldAnimate {
                        Text(text)
                            .font(font)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .offset(x: offset + dragOffset)
                            .frame(width: geo.size.width, alignment: .leading)
                            .clipped()

                            // Fade edges to make the marquee less “cut off”.
                            .mask(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .clear, location: 0.0),
                                        .init(color: .black, location: 0.06),
                                        .init(color: .black, location: 0.94),
                                        .init(color: .clear, location: 1.0)
                                    ]),
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )

                            // Manual scrubbing: pause animation while dragging, clamp offset to bounds.
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if !isDragging {
                                            isDragging = true
                                            stopAnimation()
                                        }
                                        let total = offset + value.translation.width
                                        dragOffset = min(max(total, minOffset), maxOffset) - offset
                                    }
                                    .onEnded { _ in
                                        offset = min(max(offset + dragOffset, minOffset), maxOffset)
                                        dragOffset = 0
                                        isDragging = false
                                        restartAnimationWithDelay()
                                    }
                            )
                    } else {
                        // When text fits, keep it centered and avoid unnecessary animation work.
                        Text(text)
                            .font(font)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(width: geo.size.width, alignment: .center)
                    }
                }
            }
            .frame(height: 32)
            .padding(.horizontal, horizontalPadding)

            // Update measured text width and (re)start marquee if needed.
            .onPreferenceChange(TextWidthKey.self) { width in
                textWidth = width
                startIfNeeded()
            }

            // Capture container width and keep marquee in sync with size changes.
            .onAppear {
                containerWidth = geo.size.width
                startIfNeeded()
            }
            .onChange(of: geo.size.width) { newWidth in
                containerWidth = newWidth
                startIfNeeded()
            }
        }

        // Reset state on text change to avoid jumping and stale animation cycles.
        .onChange(of: text) { _ in
            offset = 0
            dragOffset = 0
            isDragging = false
            animating = false
            goingForward = true
            startIfNeeded()
        }
    }

    private func startIfNeeded() {
        guard shouldAnimate else {
            offset = 0
            animating = false
            return
        }
        if !animating && !isDragging {
            offset = 0
            goingForward = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                pingPongAnimation()
            }
        }
    }

    private func stopAnimation() {
        animating = false
    }

    private func restartAnimationWithDelay() {
        guard shouldAnimate else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !isDragging {
                pingPongAnimation()
            }
        }
    }

    /// Ping-pong marquee: scrolls to the end, pauses, returns to start, pauses, repeats.
    private func pingPongAnimation() {
        guard shouldAnimate, !isDragging else { return }
        animating = true
        let travel = textWidth - containerWidth

        if goingForward {
            withAnimation(Animation.linear(duration: duration)) {
                offset = -travel
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if !isDragging {
                    goingForward = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        pingPongAnimation()
                    }
                }
            }
        } else {
            withAnimation(Animation.linear(duration: duration)) {
                offset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if !isDragging {
                    goingForward = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        pingPongAnimation()
                    }
                }
            }
        }
    }

    /// PreferenceKey used to pass measured text width up the view tree.
    struct TextWidthKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
}
