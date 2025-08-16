import SwiftUI

struct GlobalOverlayView: View {
    @ObservedObject var manager = GlobalOverlayManager.shared
    @EnvironmentObject var lang: Lang

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
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                                animate = true
                            }
                        }
                        .onDisappear {
                            animate = false
                        }
                    Spacer()
                }
                Spacer()
            }
            .transition(.opacity)
            .zIndex(9999)
        }
    }
}
