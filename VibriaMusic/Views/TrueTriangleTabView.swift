import SwiftUI

// MARK: - TrueTriangleTabView
/// Main navigation container based on a rotating equilateral triangle.
/// Each vertex acts as a tab button:
/// 0 = Now Playing (PlayerScreen)
/// 1 = Songs list (DrawerSongsListScreen)
/// 2 = Settings panel (external binding)
///
/// The triangle rotates to bring the selected vertex to the active position.
/// The player UI is rendered "under the triangle" using a vertical layout stack.
struct TrueTriangleTabView: View {

    // Core playback ViewModel (shared player state)
    let playerVM: MusicPlayerViewModel

    // External UI state (controlled by parent)
    @Binding var showSongList: Bool
    @Binding var showPicker: Bool
    @Binding var showSettingsPanel: Bool

    // Playlists state manager
    @ObservedObject var playlistsManager: PlaylistsManager

    // Used by the drawer list to highlight the currently playing track
    @State private var selectedSongId: String = ""

    // Triangle UI state
    @State private var triangleAngle: Double = 0
    @State private var activeVertex: Int = 0

    // Overlays
    @State private var showPlaylistsPanel = false

    // Localization
    @EnvironmentObject var lang: Lang

    // UI assets
    let icons = ["play.circle", "music.note.list", "slider.horizontal.3"]
    let tabKeys = ["nowPlaying", "songs", "settings"]

    // Background gradients per "tab"
    let gradients = [
        [Color.modaX(3).opacity(0.5), Color.modaX(5)],         // Now Playing
        [Color.modaX(5), Color.modaX(4).opacity(0.8)],         // Songs
        [Color.modaX(5), Color.modaX(4).opacity(0.3)]          // Settings
    ]

    /// Songs currently visible/used by the list (playlist if selected, otherwise base queue).
    var activeSongs: [URL] {
        if let playlist = playlistsManager.currentPlaylist {
            return playlist.songs
        }
        return playerVM.songs
    }

    /// Background gradient based on the currently active vertex.
    var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: gradients[activeVertex]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let isPortrait = geo.size.height > geo.size.width

                // Responsive sizing for portrait vs landscape
                let triangleSide: CGFloat = isPortrait ? 240 : 200
                let buttonSize: CGFloat = isPortrait ? 56 : 60
                let iconSize: CGFloat = isPortrait ? 26 : 30

                // Geometry for an equilateral triangle
                let h = triangleSide * sqrt(3) / 2
                let A = CGPoint(x: triangleSide/2, y: 0)
                let B = CGPoint(x: 0, y: h)
                let C = CGPoint(x: triangleSide, y: h)

                // Centering the triangle via its centroid
                let centroid = CGPoint(
                    x: (A.x + B.x + C.x) / 3,
                    y: (A.y + B.y + C.y) / 3
                )
                let points = [A, B, C]
                let offsetX = triangleSide/2 - centroid.x
                let offsetY = h/2 - centroid.y

                // Screen center (used for header positioning)
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

                ZStack {
                    // Header title (portrait only)
                    if isPortrait {
                        Text(lang.t(tabKeys[activeVertex]))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .position(x: center.x, y: 10)
                    } else {
                        // Keep layout stable in landscape (header not shown)
                        VStack {
                            HStack { Spacer() }
                            Spacer()
                        }
                    }

                    ZStack {
                        // Triangle shape
                        Path { path in
                            path.move(to: CGPoint(x: A.x + offsetX, y: A.y + offsetY))
                            path.addLine(to: CGPoint(x: B.x + offsetX, y: B.y + offsetY))
                            path.addLine(to: CGPoint(x: C.x + offsetX, y: C.y + offsetY))
                            path.closeSubpath()
                        }
                        .fill(Color(red: 0.92, green: 0.92, blue: 0.94).opacity(0.2))
                        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)

                        // Vertex buttons
                        ForEach(0..<3) { i in
                            let p = points[i]

                            Button(action: {
                                // Rotate triangle to selected vertex
                                if i != activeVertex {
                                    let steps = (i - activeVertex + 3) % 3
                                    let angleIncrement = Double(steps) * 120.0
                                    withAnimation(.spring(response: 0.80, dampingFraction: 0.78)) {
                                        triangleAngle -= angleIncrement
                                        activeVertex = i
                                    }
                                }

                                // Open songs drawer
                                if i == 1 {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                                        withAnimation { showSongList = true }
                                    }
                                }

                                // Open settings panel
                                if i == 2 {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                                        withAnimation { showSettingsPanel = true }
                                    }
                                }
                            }) {
                                Circle()
                                    .fill(i == activeVertex ? Color.modaX(2) : Color.modaX(1))
                                    .frame(width: buttonSize, height: buttonSize)
                                    .overlay(
                                        Image(systemName: icons[i])
                                            .font(.system(size: iconSize, weight: .bold))
                                            .foregroundColor(.black)
                                            // Counter-rotation so icons remain upright
                                            .rotationEffect(.degrees(triangleAngle))
                                    )
                                    .shadow(radius: 4, y: 2)
                            }
                            .position(x: p.x + offsetX, y: p.y + offsetY)
                        }
                    }
                    .frame(width: triangleSide, height: h)
                    // Rotate the whole triangle (icons are counter-rotated above)
                    .rotationEffect(.degrees(-triangleAngle), anchor: .center)
                }
                // Keep a stable "currently playing id" for list highlighting
                .onAppear {
                    selectedSongId = playerVM.selectedSong?.absoluteString ?? ""
                }
                .onReceive(playerVM.songDidChangePublisher) { url in
                    selectedSongId = url?.absoluteString ?? ""
                }
                .onChange(of: playerVM.selectedSong) { url in
                    selectedSongId = url?.absoluteString ?? ""
                }
                .background(
                    backgroundGradient
                        .edgesIgnoringSafeArea(.all)
                        .animation(.easeInOut, value: activeVertex)
                )

                // Main content is placed under the triangle
                VStack {
                    Spacer()
                    currentScreen()
                        .transition(.opacity)
                    Spacer().frame(height: 40)
                }
            }

            // MARK: - Songs Drawer Overlay
            if showSongList {
                // Tap-to-dismiss background
                Color.black.opacity(0.01)
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial)
                    .opacity(0.5)
                    .onTapGesture {
                        withAnimation { showSongList = false }
                    }
                    .zIndex(1)

                DrawerSongsListScreen(
                    isPresented: $showSongList,
                    songs: bindingForCurrentSongList(),
                    playlistsManager: playlistsManager,
                    selectedSongId: selectedSongId,
                    onSelect: { url in
                        playerVM.selectSong(url)
                        selectedSongId = url.absoluteString
                    },
                    onAddSongs: { showPicker = true },
                    onManagePlaylists: { showPlaylistsPanel = true },
                    onAddToPlaylist: { url, playlist in
                        playlistsManager.addSong(url, to: playlist)
                    },
                    onRemoveFromPlaylist: { url in
                        if let playlist = playlistsManager.currentPlaylist {
                            playlistsManager.removeSong(url, from: playlist, save: true)
                        }
                    },
                    onDeleteSong: { url in
                        // Remove from all playlists + library
                        playlistsManager.removeSongFromAllPlaylists(url, save: true)
                        playerVM.allSongs.removeAll { $0 == url }
                        playerVM.songs.removeAll { $0 == url }
                    },
                    currentlyPlayingSong: binding(\.selectedSong),
                    onMoveSongs: { newSongs in
                        // Reorder playlist or library and sync with player queue
                        if let playlist = playlistsManager.currentPlaylist {
                            playlistsManager.updatePlaylistSongs(
                                playlistID: playlist.id,
                                newSongs: newSongs
                            )
                            playerVM.songs = newSongs
                            playerVM.updateShuffle()
                        } else {
                            playerVM.setAllSongs(newSongs)
                            playerVM.updateShuffle()
                        }
                    }
                )
                .transition(.move(edge: .leading))
                .zIndex(2)
            }

            // MARK: - Playlists Panel Overlay
            if showPlaylistsPanel {
                PlaylistsOverlay(
                    playlistsManager: playlistsManager,
                    isPresented: $showPlaylistsPanel,
                    showSongList: $showSongList
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
        // Animations / state synchronization
        .animation(.easeInOut(duration: 0.27), value: showPlaylistsPanel)

        // When drawers close, return triangle to "Now Playing"
        .onChange(of: showSongList) { value in
            if !value { resetToNowPlaying() }
        }
        .onChange(of: showSettingsPanel) { value in
            if !value { resetToNowPlaying() }
        }
    }

    // MARK: - Helpers

    /// Creates a Binding to a MusicPlayerViewModel reference-writable keyPath.
    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<MusicPlayerViewModel, T>) -> Binding<T> {
        Binding(
            get: { playerVM[keyPath: keyPath] },
            set: { playerVM[keyPath: keyPath] = $0 }
        )
    }

    /// Returns a Binding to the currently displayed song list:
    /// - current playlist songs (if selected)
    /// - full library (otherwise)
    private func bindingForCurrentSongList() -> Binding<[URL]> {
        if let playlist = playlistsManager.currentPlaylist {
            guard let playlistIndex = playlistsManager.playlists.firstIndex(where: { $0.id == playlist.id }) else {
                return .constant([])
            }
            return Binding<[URL]>(
                get: { playlistsManager.playlists[playlistIndex].songs },
                set: { newSongs in
                    playlistsManager.playlists[playlistIndex].songs = newSongs
                    if playlistsManager.currentPlaylist?.id == playlist.id {
                        playerVM.songs = newSongs
                    }
                }
            )
        } else {
            return Binding<[URL]>(
                get: { playerVM.allSongs },
                set: { newSongs in
                    playerVM.setAllSongs(newSongs)
                }
            )
        }
    }

    /// Returns the currently active content for the selected vertex.
    @ViewBuilder
    func currentScreen() -> some View {
        switch activeVertex {
        case 0:
            PlayerScreen(
                selectedSong: binding(\.selectedSong),
                progress: binding(\.progress),
                duration: binding(\.duration),
                isPlaying: binding(\.isPlaying),
                isShuffling: binding(\.isShuffling),
                loopMode: binding(\.loopMode),
                vm: playerVM,
                playlistsManager: playlistsManager,
                onPlayPause: { playerVM.playPause() },
                onNext: { playerVM.playNext() },
                onPrev: { playerVM.playPrev() },
                onSeek: { time in playerVM.seek(to: time) }
            )
        case 1:
            EmptyView()
        case 2:
            EmptyView()
        default:
            EmptyView()
        }
    }

    /// Rotates the triangle back to the default vertex (Now Playing).
    private func resetToNowPlaying() {
        let steps = (0 - activeVertex + 3) % 3
        let angleIncrement = Double(steps) * 120.0
        withAnimation(.spring(response: 0.80, dampingFraction: 0.78)) {
            triangleAngle -= angleIncrement
            activeVertex = 0
        }
    }
}
