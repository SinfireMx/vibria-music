import SwiftUI

// MARK: - MarqueeText
struct MarqueeText: View {
    let text: String
    let font: Font
    let duration: Double
    let horizontalPadding: CGFloat

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var animating = false
    @State private var goingForward = true

    var shouldAnimate: Bool {
        textWidth > containerWidth
    }

    var minOffset: CGFloat { -(textWidth - containerWidth) }
    var maxOffset: CGFloat { 0 }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Ukryty tekst do pomiaru szerokości
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
            .onPreferenceChange(TextWidthKey.self) { width in
                textWidth = width
                startIfNeeded()
            }
            .onAppear {
                containerWidth = geo.size.width
                startIfNeeded()
            }
            .onChange(of: geo.size.width) { newWidth in
                containerWidth = newWidth
                startIfNeeded()
            }
        }
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

    struct TextWidthKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
}
