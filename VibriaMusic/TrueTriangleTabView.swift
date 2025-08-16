import SwiftUI

// MARK: - Kolory stylu
//extension Color {
//    static let moda1 = Color(red: 140/255, green: 104/255, blue: 84/255)
//    static let moda2 = Color(red: 216/255, green: 154/255, blue: 132/255)
//    static let moda3 = Color(red: 242/255, green: 192/255, blue: 174/255)
//    static let moda4 = Color(red: 63/255, green: 27/255, blue: 19/255)
//    static let moda5 = Color(red: 12/255, green: 12/255, blue: 12/255)
//}

// MARK: - TrueTriangleTabView
struct TrueTriangleTabView: View {
    let playerVM: MusicPlayerViewModel
    
    @Binding var showSongList: Bool
    @Binding var showPicker: Bool
    @ObservedObject var playlistsManager: PlaylistsManager
    
//    @State private var selectedSong: URL? // <-- nowy lokalny state
    @State private var selectedSongId: String = ""

    @State private var triangleAngle: Double = 0
    @State private var activeVertex: Int = 0
    @State private var showPlaylistsPanel = false
    @EnvironmentObject var lang: Lang
    @Binding var showSettingsPanel: Bool
    
    let icons = ["play.circle", "music.note.list", "slider.horizontal.3"]
    let tabKeys = ["nowPlaying", "songs", "settings"]
    
    let gradients = [
        [Color.modaX(3).opacity(0.5), Color.modaX(5)], // Teraz gra
        [Color.modaX(5), Color.modaX(4).opacity(0.8)], // Lista utworów
        [Color.modaX(5), Color.modaX(4).opacity(0.3)]  // Ustawienia
    ]
    
    var activeSongs: [URL] {
        if let playlist = playlistsManager.currentPlaylist {
            return playlist.songs
        }
        return playerVM.songs
    }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: gradients[activeVertex]),
            startPoint: .top, endPoint: .bottom
        )
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                let isPortrait = geo.size.height > geo.size.width
                let triangleSide: CGFloat = isPortrait ? 240 : 200  // <- Rozmiar trójkąta!
                let buttonSize: CGFloat = isPortrait ? 56 : 60      // <- Rozmiar przycisków!
                let iconSize: CGFloat = isPortrait ? 26 : 30
                let h = triangleSide * sqrt(3) / 2
                let A = CGPoint(x: triangleSide/2, y: 0)
                let B = CGPoint(x: 0, y: h)
                let C = CGPoint(x: triangleSide, y: h)
                let centroid = CGPoint(x: (A.x + B.x + C.x) / 3, y: (A.y + B.y + C.y) / 3)
                let points = [A, B, C]
                let offsetX = triangleSide/2 - centroid.x
                let offsetY = h/2 - centroid.y
                let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                
                ZStack {
                    if isPortrait {
                        Text(lang.t(tabKeys[activeVertex]))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
//                            .padding(.top, 40)
                            .position(x: center.x, y: 10)
                    } else {
                        VStack {
                            HStack {
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                    ZStack {
                        // TRÓJKĄT
                        Path { path in
                            path.move(to: CGPoint(x: A.x + offsetX, y: A.y + offsetY))
                            path.addLine(to: CGPoint(x: B.x + offsetX, y: B.y + offsetY))
                            path.addLine(to: CGPoint(x: C.x + offsetX, y: C.y + offsetY))
                            path.closeSubpath()
                        }
                        .fill(Color(red: 0.92, green: 0.92, blue: 0.94).opacity(0.2))
                        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
                        
                        // PRZYCISKI NA WIERZCHOŁKACH
                        ForEach(0..<3) { i in
                            let p = points[i]
                            Button(action: {
                                if i != activeVertex {
                                    let steps = (i - activeVertex + 3) % 3
                                    let angleIncrement = Double(steps) * 120.0
                                    withAnimation(.spring(response: 0.80, dampingFraction: 0.78)) {
                                        triangleAngle -= angleIncrement
                                        activeVertex = i
                                    }
                                }
                                if i == 1 {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                                        
                                        withAnimation { showSongList = true }
                                    }
                                }
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
                                            .rotationEffect(.degrees(triangleAngle))
                                    )
                                    .shadow(radius: 4, y: 2)
                            }
                            .position(x: p.x + offsetX, y: p.y + offsetY)
                        }
                    }
                    .frame(width: triangleSide, height: h)
                    .rotationEffect(.degrees(-triangleAngle), anchor: .center)
                }
                .onAppear {
                    selectedSongId = playerVM.selectedSong?.absoluteString ?? ""
                }
                .onReceive(playerVM.songDidChangePublisher) { url in
                    selectedSongId = url?.absoluteString ?? ""
                }
                .onChange(of: playerVM.selectedSong) { url in
                    selectedSongId = url?.absoluteString ?? ""
                }
                
//                .alert(isPresented: $playerVM.showUnsupportedAlert) {
//                    Alert(
//                        title: Text(lang.t("unsupportedFilesTitle")),
//                        message: Text(playerVM.unsupportedFiles.map { $0.lastPathComponent }.joined(separator: "\n")),
//                        dismissButton: .default(Text("OK"))
//                    )
//                }
                .background(
                    backgroundGradient
                        .edgesIgnoringSafeArea(.all)
                        .animation(.easeInOut, value: activeVertex)
                )
                
                VStack {
                    Spacer()
                    currentScreen()
                        .transition(.opacity)
                    Spacer().frame(height: 40)
                }
            }
            
            if showSongList {
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
                        selectedSongId = url.absoluteString // lub Twój unikalny identyfikator utworu!
                    },
                    onAddSongs: { showPicker = true },
                    onManagePlaylists: { showPlaylistsPanel = true },
                    onAddToPlaylist: { url, playlist in playlistsManager.addSong(url, to: playlist) },
                    onRemoveFromPlaylist: { url in
                        if let playlist = playlistsManager.currentPlaylist {
                            playlistsManager.removeSong(url, from: playlist, save: true) // <— tu zmiana
                        }
                    },
                    onDeleteSong: { url in
                        playlistsManager.removeSongFromAllPlaylists(url, save: true)     // <— tu zmiana
                        playerVM.allSongs.removeAll { $0 == url }
                        playerVM.songs.removeAll { $0 == url }
                    },
                    currentlyPlayingSong: binding(\.selectedSong),
                    onMoveSongs: { newSongs in
                        if let playlist = playlistsManager.currentPlaylist {
                            playlistsManager.updatePlaylistSongs(playlistID: playlist.id, newSongs: newSongs)
                            playerVM.songs = newSongs
                            playerVM.updateShuffle()
                        } else {
                            playerVM.setAllSongs(newSongs)
                            playerVM.updateShuffle()
                        }
                    }
                )
//                .id(selectedSong) // wymusi ponowne wyrenderowanie listy

                .transition(.move(edge: .leading))
                .zIndex(2)
            }
            
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
        .animation(.easeInOut(duration: 0.27), value: showPlaylistsPanel)
        .onChange(of: showSongList) { value in
            if !value {
                let steps = (0 - activeVertex + 3) % 3
                let angleIncrement = Double(steps) * 120.0
                withAnimation(.spring(response: 0.80, dampingFraction: 0.78)) {
                    triangleAngle -= angleIncrement
                    activeVertex = 0
                }
            }
        }
        .onChange(of: showSettingsPanel) { value in
            if !value {
                let steps = (0 - activeVertex + 3) % 3
                let angleIncrement = Double(steps) * 120.0
                withAnimation(.spring(response: 0.80, dampingFraction: 0.78)) {
                    triangleAngle -= angleIncrement
                    activeVertex = 0
                }
            }
        }
    }
    
    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<MusicPlayerViewModel, T>) -> Binding<T> {
        Binding(
            get: { playerVM[keyPath: keyPath] },
            set: { playerVM[keyPath: keyPath] = $0 }
        )
    }
    
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
                playlistsManager: playlistsManager,      // ⬅️ NOWE
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
    
}


