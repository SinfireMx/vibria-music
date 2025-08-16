import SwiftUI

// Uwaga: tutaj używam NAZWY TYPU jak wcześniej: PlaylistsOverlay.
// Jeśli gdzieś indziej używasz PlayListOverlay – zmień tam wywołanie albo
// zmień tu nazwę structa na PlayListOverlay.
struct PlaylistsOverlay: View {
    @ObservedObject var playlistsManager: PlaylistsManager
    @Binding var isPresented: Bool
    @Binding var showSongList: Bool
    @EnvironmentObject var lang: Lang

    // Stan
    @State private var playlistToDelete: Playlist?
    @State private var showDeleteAlert = false
    @State private var showCreatePopup = false
    @State private var localPlaylists: [Playlist] = []
    @State private var searchText: String = ""
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Computed
    private var favoritesID: UUID? { playlistsManager.favoritesPlaylist?.id }

    private var userPlaylistsOnly: [Playlist] {
        let favID = favoritesID
        return localPlaylists.filter { $0.id != favID }
    }

    private var filtered: [Playlist] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return userPlaylistsOnly }
        return userPlaylistsOnly.filter { $0.name.lowercased().contains(q) }
    }

    // Lżejsze dla kompilatora – rozbite podwidoki i jawne typy
    private var backgroundBlur: some View {
        VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
            .ignoresSafeArea()
            .saturation(0.75)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.modaX(5).opacity(0.65), Color.modaX(4).opacity(0.45)],
            startPoint: .top, endPoint: .bottom
        )
    }

    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.title2.weight(.bold))
                .foregroundColor(.modaX(2))
                .padding(8)
                .background(Circle().fill(Color.modaX(5).opacity(0.15)))

            Text(lang.t("yourPlaylists"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(radius: 1, y: 1)

            Spacer()

            Button {
                withAnimation { isPresented = false }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.modaX(3))
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                TextField(lang.t("searchSong"), text: $searchText)
                    .textInputAutocapitalization(.never)
                    .disabled(showCreatePopup) // nie łap fokusu pod popupem
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.modaX(3))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.modaX(5).opacity(0.15))
            )

            if userPlaylistsOnly.count < PlaylistsManager.maxPlaylists {
                Button {
                    endEditing() // zgaś stare first-respondery (szczególnie search)
                    withAnimation { showCreatePopup = true }
                } label: {
                    Label(lang.t("newPlaylist"), systemImage: "plus.circle.fill")
                        .font(.system(size: 15.5, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.modaX(5).opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
                .disabled(showCreatePopup)
            }
        }
        .foregroundColor(.modaX(2))
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    private var gridView: some View {
        GeometryReader { _ in
            let columns: [GridItem] = [
                GridItem(.adaptive(minimum: 160), spacing: 12, alignment: .top)
            ]
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filtered) { playlist in
                        PlaylistCard(
                            playlist: playlist,
                            isCurrent: playlistsManager.currentPlaylist?.id == playlist.id,
                            lang: lang,
                            onSelect: {
                                withAnimation(.easeOut(duration: 0.17)) {
                                    playlistsManager.select(playlist)
                                    showSongList = true
                                    isPresented = false
                                }
                            },
                            onDelete: {
                                playlistToDelete = playlist
                                showDeleteAlert = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
            }
        }
    }

    var body: some View {
        ZStack {
            backgroundBlur
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                searchBar
                Divider().background(Color.modaX(3).opacity(0.15))
                gridView
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.modaX(5).opacity(0.12))
                    .shadow(color: .black.opacity(0.3), radius: 18, y: 10)
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .ignoresSafeArea(.container, edges: .bottom)
            .disabled(showCreatePopup) // spód wyłączony gdy popup otwarty
            .zIndex(1)

            // POPUP
            if showCreatePopup {
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            showCreatePopup = false
                        }
                    }
                    .zIndex(9)

                CreatePlaylistPopup(isPresented: $showCreatePopup) { name in
                    endEditing()   // zgaś klawiaturę zanim dotkniemy modelu
                    searchText = ""
                    withTransaction(Transaction(animation: nil)) {
                        if let _ = playlistsManager.createPlaylist(name: name) {
                            localPlaylists = playlistsManager.playlists
                        } else {
                            print("⚠️ Nie utworzono playlisty – limit lub duplikat nazwy.")
                        }
                    }
                }
                .frame(maxWidth: 360)
                .zIndex(10)
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text(lang.t("deletePlaylistQ")),
                message: Text(lang.t("deletePlaylistDesc")),
                primaryButton: .destructive(Text(lang.t("delete"))) {
                    if let playlist = playlistToDelete {
                        withAnimation {
                            playlistsManager.deletePlaylist(playlist)
                            localPlaylists = playlistsManager.playlists
                        }
                    }
                },
                secondaryButton: .cancel(Text(lang.t("cancel")))
            )
        }
        .onAppear { localPlaylists = playlistsManager.playlists }
        .onChange(of: playlistsManager.playlists) { newVal in
            localPlaylists = newVal
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive {
                playlistsManager.savePlaylists()
            }
        }
        .onChange(of: showCreatePopup) { open in
            if open { endEditing() }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.22), value: isPresented)
        .animation(showCreatePopup ? nil : .easeInOut(duration: 0.22), value: localPlaylists)
    }
}

// MARK: - Karta playlisty
private struct PlaylistCard: View {
    let playlist: Playlist
    let isCurrent: Bool
    let lang: Lang
    var onSelect: () -> Void
    var onDelete: () -> Void

    @State private var total: Double = 0

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(isCurrent ? Color.modaX(2) : Color.modaX(1))
                            .frame(width: 42, height: 42)
                        Image(systemName: "music.note.list")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.red.opacity(0.9))
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.modaX(5).opacity(0.10))
                            )
                    }
                    .buttonStyle(.plain)
                }

                Text(playlist.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Label("\(playlist.songs.count)", systemImage: "music.note.list")
                    Label(total.hmsString, systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.modaX(3).opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.modaX(5).opacity(0.10))
                )

                Spacer(minLength: 2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isCurrent ? Color.modaX(2).opacity(0.16) : Color.modaX(5).opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.modaX(3).opacity(isCurrent ? 0.25 : 0.14), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
            )
        }
        .buttonStyle(.plain)
        .task(id: playlist.songs) {
            await calcTotal()
        }
        .contextMenu {
            Button(role: .destructive) { onDelete() } label: {
                Label(lang.t("delete"), systemImage: "trash")
            }
        }
    }

    @MainActor
    private func calcTotal() async {
        let sum = await AudioDurationCache.shared.totalDuration(for: playlist.songs)
        self.total = sum
    }
}
