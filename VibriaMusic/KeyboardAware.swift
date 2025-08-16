//import SwiftUI
//import Combine
//
///// ViewModifier, który podnosi widok, gdy pojawia się klawiatura.
///// Wysokość jest animowana, uwzględnia bezpieczny dół (home indicator).
//struct KeyboardAware: ViewModifier {
//    @State private var keyboardHeight: CGFloat = 0
//    @State private var cancellables: Set<AnyCancellable> = []
//
//    func body(content: Content) -> some View {
//        content
//            // „podniesienie” treści nad klawiaturę
//            .padding(.bottom, keyboardHeight)
//            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: keyboardHeight)
//            // pozwól zawartości wejść pod safe-area klawiatury (żeby padding zadziałał)
//            .ignoresSafeArea(.keyboard, edges: .bottom)
//            .onAppear(perform: subscribeToKeyboard)
//            .onDisappear { cancellables.removeAll() }
//    }
//
//    private func subscribeToKeyboard() {
//        let willChange = NotificationCenter.default
//            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
//        let willHide = NotificationCenter.default
//            .publisher(for: UIResponder.keyboardWillHideNotification)
//
//        willChange.merge(with: willHide)
//            .receive(on: RunLoop.main)
//            .sink { notification in
//                guard let userInfo = notification.userInfo else { return }
//                let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
//                let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
//                let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt) ?? 7
//                let isHidden = endFrame.origin.y >= UIScreen.main.bounds.height
//
//                let bottomSafe = UIApplication.shared.connectedScenes
//                    .compactMap { $0 as? UIWindowScene }
//                    .first?.windows.first?.safeAreaInsets.bottom ?? 0
//
//                let target = isHidden ? 0 : max(0, endFrame.height - bottomSafe)
//
//                // Zsynchronizuj z czasem animacji klawiatury
//                UIView.animate(withDuration: duration,
//                               delay: 0,
//                               options: UIView.AnimationOptions(rawValue: curveRaw << 16),
//                               animations: {
//                    self.keyboardHeight = target
//                }, completion: nil)
//            }
//            .store(in: &cancellables)
//    }
//}
//
//extension View {
//    /// Łatwy skrót: .keyboardAware()
//    func keyboardAware() -> some View { self.modifier(KeyboardAware()) }
//}
//
///// Pomocnicze — schowanie klawiatury po tapnięciu tła
//func endEditing() {
//    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//}
