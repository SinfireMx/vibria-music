import SwiftUI
import Combine
import UIKit

// MARK: - KeyboardAware
/// Simple keyboard avoidance modifier (prevents double-shifting issues).
/// Adds bottom padding equal to keyboard overlap with an optional gap.
struct KeyboardAware: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    @State private var cancellables: Set<AnyCancellable> = []
    let gap: CGFloat

    init(gap: CGFloat = 8) { self.gap = gap }

    func body(content: Content) -> some View {
        content
            // Apply only bottom padding (no extra offsets) to avoid over-compensation.
            .padding(.bottom, keyboardHeight)
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: keyboardHeight)
            .onAppear(perform: subscribeToKeyboard)
            .onDisappear { cancellables.removeAll() }
    }

    private func subscribeToKeyboard() {
        let willChange = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        let willHide   = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

        willChange.merge(with: willHide)
            .receive(on: RunLoop.main)
            .sink { notification in
                guard let userInfo = notification.userInfo else { return }

                let endFrameScreen = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
                let duration       = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
                let curveRaw       = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt) ?? 7

                guard
                    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                    let window = windowScene.windows.first(where: { $0.isKeyWindow })
                else { self.keyboardHeight = 0; return }

                // Calculate real overlap of the keyboard with the key window.
                let endInWindow = window.convert(endFrameScreen, from: nil)
                let overlap = max(0, window.bounds.maxY - endInWindow.minY)
                let target  = overlap > 0 ? max(0, overlap - gap) : 0

                // Animate keyboard height with the same timing/curve as the system keyboard.
                UIView.animate(withDuration: duration,
                               delay: 0,
                               options: UIView.AnimationOptions(rawValue: curveRaw << 16),
                               animations: { self.keyboardHeight = target },
                               completion: nil)
            }
            .store(in: &cancellables)
    }
}

extension View {
    /// Applies keyboard avoidance with an optional gap above the keyboard.
    func keyboardAware(gap: CGFloat = 8) -> some View { modifier(KeyboardAware(gap: gap)) }
}

/// Dismisses the current first responder (closes keyboard).
func endEditing() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// MARK: - CreatePlaylistPopup
/// Modal popup for creating a new playlist.
/// Handles focus/keyboard behavior and basic input validation.
struct CreatePlaylistPopup: View {
    @Binding var isPresented: Bool
    @State private var playlistName: String = ""
    var onCreate: (String) -> Void

    @FocusState private var focused: Bool
    @EnvironmentObject var lang: Lang

    @State private var shakeToken: CGFloat = 0
    @State private var isDismissing: Bool = false

    /// True when trimmed playlist name is non-empty.
    var canCreate: Bool { !playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var popupBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.modaX(2).opacity(0.15), lineWidth: 1))
            .shadow(radius: 18, y: 6)
    }

    var body: some View {
        ZStack {
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                .ignoresSafeArea()
                .opacity(0.92)

            // Tap outside to either dismiss keyboard or close the popup.
            Color.black.opacity(0.15)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { backdropTap() }

            VStack(spacing: 24) {
                // Header icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.modaX(2).opacity(0.44), Color.modaX(3).opacity(0.58)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 54, height: 54)
                        .shadow(color: Color.modaX(2).opacity(0.12), radius: 9, y: 2)
                    Image(systemName: "music.note.list")
                        .font(.system(size: 29, weight: .bold))
                        .foregroundColor(.modaX(4))
                }
                .padding(.bottom, 2)

                Text(lang.t("newPlaylist"))
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.06), radius: 1, y: 1)

                // TextField configured to minimize auto-corrections and avoid unexpected capitalization.
                TextField(lang.t("playlistName"), text: $playlistName)
                    .keyboardType(.default)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .textContentType(.name)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
                    .background(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 17).stroke(Color.modaX(2).opacity(0.25), lineWidth: 1.3))
                    .cornerRadius(17)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit { handleSubmit() }
                    .modifier(ShakeEffect(animatableData: shakeToken))
                    // Force a fresh TextField identity so focus works reliably after each presentation.
                    .id(isPresented)

                HStack(spacing: 18) {
                    Button(action: { dismissSmooth() }) {
                        Text(lang.t("cancel"))
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.modaX(3))
                            .frame(minWidth: 75)
                            .padding(.vertical, 9)
                            .background(RoundedRectangle(cornerRadius: 13).fill(Color.modaX(5).opacity(0.07)))
                    }
                    .buttonStyle(.plain)

                    Button(action: { createIfPossible() }) {
                        Text(lang.t("create"))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(canCreate ? .white : .gray)
                            .frame(minWidth: 78)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 13).fill(
                                    canCreate
                                    ? AnyShapeStyle(LinearGradient(colors: [Color.modaX(2).opacity(0.86), Color.modaX(3).opacity(0.84)],
                                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                    : AnyShapeStyle(LinearGradient(colors: [Color.gray.opacity(0.27), Color.gray.opacity(0.17)],
                                                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                                )
                            )
                            .shadow(radius: canCreate ? 3 : 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canCreate)
                }
                .padding(.top, 6)
            }
            .padding(.vertical, 36)
            .padding(.horizontal, 26)
            .background(popupBackground)
            .frame(maxWidth: 350)
            .padding(.horizontal, 16)
            .keyboardAware(gap: 8)
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity).animation(.spring(response: 0.37, dampingFraction: 0.85)),
            removal: .opacity
        ))
        .zIndex(100)
        .task(id: isPresented) {
            if isPresented {
                // Clear any existing focus before assigning focus to this TextField.
                endEditing()
                try? await Task.sleep(nanoseconds: 150_000_000)
                focused = true
            } else {
                focused = false
            }
        }
        .onDisappear {
            // Reset transient state after dismissal.
            focused = false
            playlistName = ""
        }
    }

    private func handleSubmit() {
        if canCreate {
            createIfPossible()
        } else {
            // Provide feedback on invalid input.
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeOut(duration: 0.18)) { shakeToken += 1 }
            focused = true
        }
    }

    private func createIfPossible() {
        let trimmed = playlistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onCreate(trimmed)
        dismissSmooth()
    }

    private func dismissSmooth() {
        // Prevent double-dismiss during animations / multiple taps.
        guard !isDismissing else { return }
        isDismissing = true
        focused = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.18)) { isPresented = false }
        }
    }

    private func backdropTap() {
        // First tap dismisses keyboard, second tap dismisses the popup.
        if focused { focused = false } else { dismissSmooth() }
    }
}

// MARK: - ShakeEffect
/// Simple shake animation used for invalid input feedback.
private struct ShakeEffect: GeometryEffect {
    var amplitude: CGFloat = 6
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        let x = amplitude * sin(animatableData * .pi * 2)
        return ProjectionTransform(CGAffineTransform(translationX: x, y: 0))
    }
}
