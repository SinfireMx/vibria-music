import SwiftUI

/// Modal popup used to add a selected track to an existing playlist.
/// Presented as an overlay: tap outside the card to dismiss.
struct AddToPlaylistPopup: View {
    /// Source of truth for available playlists.
    @ObservedObject var playlistsManager: PlaylistsManager

    /// Track (file URL) being added.
    let song: URL

    /// Controls presentation/dismissal from the parent view.
    @Binding var isPresented: Bool

    /// Callback fired when the user picks a playlist.
    /// Parent decides what "add" means (e.g. append + persist).
    var onAdd: (Playlist) -> Void

    /// Localization provider.
    @EnvironmentObject var lang: Lang

    /// Card background style (glass-like material + subtle border).
    private var popupBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.modaX(2).opacity(0.13), lineWidth: 1.1)
            )
            .shadow(radius: 20, y: 8)
    }

    var body: some View {
        ZStack {
            // Dimmed background. Tap outside the card dismisses the popup.
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { isPresented = false } }

            // Popup card (width capped to keep a "modal sheet" feel).
            VStack(spacing: 0) {
                header
                Divider().background(Color.modaX(3).opacity(0.16))
                playlistsList
                Divider().background(Color.modaX(3).opacity(0.14))
                cancelButton
            }
            .frame(maxWidth: 380)
            .background(popupBackground)
            .padding(.horizontal, 18)
        }
        // Smooth overlay appearance/disappearance.
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
        .zIndex(200)
    }

    // MARK: - UI Parts

    /// Title + icon header.
    private var header: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.modaX(2).opacity(0.44), Color.modaX(3).opacity(0.55)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: "text.badge.plus")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.modaX(4))
            }
            .padding(.top, 18)

            Text(lang.t("addToPlaylist"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.93))
                .padding(.bottom, 10)
        }
        .padding(.horizontal, 16)
    }

    /// Scrollable list of playlists. Displays a checkmark if the song is already inside.
    private var playlistsList: some View {
        ScrollView {
            VStack(spacing: 11) {
                ForEach(playlistsManager.playlists) { playlist in
                    let isIn = playlist.songs.contains(song)

                    Button {
                        onAdd(playlist)
                        withAnimation { isPresented = false }
                    } label: {
                        HStack {
                            Image(systemName: "music.note.list")
                                .foregroundColor(.modaX(3))
                                .opacity(isIn ? 1 : 0.76)

                            Text(playlist.name)
                                .foregroundColor(isIn ? .white : .modaX(3))
                                .fontWeight(isIn ? .bold : .regular)
                                .lineLimit(1)

                            Spacer()

                            if isIn {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.modaX(2))
                            }
                        }
                        .font(.system(size: 15.5, weight: .medium, design: .rounded))
                        .padding(.vertical, 9)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(isIn ? Color.modaX(2).opacity(0.12) : Color.modaX(3).opacity(0.09))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
        }
        // Cap height so the popup remains compact on large screens.
        .frame(maxHeight: 360)
    }

    /// Dismiss action button.
    private var cancelButton: some View {
        Button { withAnimation { isPresented = false } } label: {
            Text(lang.t("cancel"))
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.modaX(3))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Color.modaX(5).opacity(0.20))
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cancel")
    }
}
