import SwiftUI

/// Global top banner shown while background persistence is in progress.
/// Visibility is controlled by `GlobalOverlayManager`.
struct GlobalOverlayView: View {
    @ObservedObject var manager = GlobalOverlayManager.shared
    @EnvironmentObject var lang: Lang

    /// Used to drive the subtle pulsing opacity animation.
    @State private var animate = false

    var body: some View {
        if manager.visible {
            VStack {
                HStack {
                    Spacer()
                    Text(lang.t("savingList"))
                        .font(.subheadline)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                        .background(Color.modaX(5).opacity(0.75))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.top, 28)
                        .opacity(animate ? 0.4 : 1)

                        // Start a lightweight pulsing animation while the overlay is visible.
                        .onAppear {
                            withAnimation(
                                Animation.easeInOut(duration: 0.4)
                                    .repeatForever(autoreverses: true)
                            ) {
                                animate = true
                            }
                        }

                        // Reset animation state when the overlay disappears.
                        .onDisappear {
                            animate = false
                        }
                    Spacer()
                }
                Spacer()
            }
            // Keep the overlay above all other views.
            .transition(.opacity)
            .zIndex(9999)
        }
    }
}
