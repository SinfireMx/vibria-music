//import SwiftUI
//
//struct EditablePlaylistView: View {
//    @ObservedObject var playlistsManager: PlaylistsManager
//    let playlistID: UUID
//    var onSelect: (URL) -> Void
//    @ObservedObject var playerVM: MusicPlayerViewModel
//    
//    @State private var localSongs: [URL] = []
//    @State private var hasChanges: Bool = false
//    @State private var editMode: EditMode = .inactive
//    
//    private var playlist: Playlist? {
//        playlistsManager.playlists.first(where: { $0.id == playlistID })
//    }
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // Nagłówek
//            HStack {
//                Text(playlist?.name ?? "Nowa playlista")
//                    .font(.title3.weight(.bold))
//                    .foregroundColor(.primary)
//                Spacer()
//                Button("Gotowe") {
//                    saveIfNeeded()
//                }
//                .font(.callout.bold())
//            }
//            .padding()
//            .background(Color.modaX(5).opacity(0.1))
//            
//            Divider()
//            
//            // Lista utworów - LazyVStack
//            ScrollView {
//                LazyVStack(spacing: 0) {
//                    ForEach(localSongs, id: \.self) { song in
//                        HStack {
//                            Text(song.lastPathComponent)
//                                .lineLimit(1)
//                                .font(.callout)
//                                .foregroundColor(song == playerVM.selectedSong ? .accentColor : .primary)
//                                .padding(.vertical, 8)
//                            
//                            Spacer()
//                            
//                            Image(systemName: "line.horizontal.3")
//                                .foregroundColor(.secondary)
//                                .opacity(editMode == .active ? 1 : 0)
//                        }
//                        .padding(.horizontal)
//                        .background(Color.modaX(5).opacity(0.05))
//                        .contentShape(Rectangle())
//                        .onTapGesture {
//                            if editMode != .active {
//                                onSelect(song)
//                            }
//                        }
//                    }
//                    .onMove(perform: onMove)
//                }
//                .animation(.default, value: localSongs)
//            }
//            .environment(\.editMode, $editMode)
//        }
//        .onAppear {
//            localSongs = playlist?.songs ?? []
//            // Opóźnione wejście w tryb edycji
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                editMode = .active
//            }
//        }
//    }
//    
//    // MARK: - Operacje na liście
//    private func onMove(from source: IndexSet, to destination: Int) {
//        localSongs.move(fromOffsets: source, toOffset: destination)
//        hasChanges = true
//    }
//    
//    private func saveIfNeeded() {
//        guard hasChanges, let idx = playlistsManager.playlists.firstIndex(where: { $0.id == playlistID }) else { return }
//        playlistsManager.playlists[idx].songs = localSongs
//        hasChanges = false
//        
//        // Zapis w tle
//        DispatchQueue.global(qos: .background).async {
//            playlistsManager.savePlaylists()
//        }
//    }
//}
