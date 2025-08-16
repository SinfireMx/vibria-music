//import SwiftUI
//
//struct PlaylistsView: View {
//    @ObservedObject var playlistsManager: PlaylistsManager
//    @Binding var isPresented: Bool
//
//    @State private var playlistToDelete: Playlist? = nil
//    @State private var showDeleteAlert = false
//    @State private var showCreatePopup = false
//
//    @State private var localPlaylists: [Playlist] = []
//    @State private var hasChanges = false
//    @Environment(\.scenePhase) private var scenePhase
//
//    static let cellHeight: CGFloat = 52
//
//    var body: some View {
//        ZStack {
//            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
//                .ignoresSafeArea()
//                .onTapGesture { isPresented = false }
//
//            VStack(spacing: 0) {
//                Header
//                Divider().padding(.horizontal, 4)
//                CreateButtonSection
//                PlaylistsList
//            }
//            .frame(width: 355)
//            .padding(.vertical, 18)
//            .background(
//                RoundedRectangle(cornerRadius: 28)
//                    .fill(Color.moda3.opacity(0.98))
//                    .shadow(radius: 18, y: 6)
//            )
//            .padding(.horizontal, 8)
//            .overlay(
//                Group {
//                    if showCreatePopup {
//                        CreatePlaylistPopup(isPresented: $showCreatePopup) { name in
//                            playlistsManager.createPlaylist(name: name)
//                            localPlaylists = playlistsManager.playlists
//                        }
//                    }
//                }
//            )
//            .alert(isPresented: $showDeleteAlert) {
//                Alert(
//                    title: Text("Usuń playlistę?"),
//                    message: Text("Tej operacji nie można cofnąć."),
//                    primaryButton: .destructive(Text("Usuń")) {
//                        if let playlist = playlistToDelete {
//                            withAnimation {
//                                playlistsManager.deletePlaylist(playlist)
//                                localPlaylists = playlistsManager.playlists
//                            }
//                        }
//                    },
//                    secondaryButton: .cancel()
//                )
//            }
//            .animation(.spring(), value: playlistsManager.playlists.count)
//        }
//        .onAppear { localPlaylists = playlistsManager.playlists }
//        .onDisappear { saveIfNeeded() }
//        .onChange(of: playlistsManager.playlists) { value in
//            localPlaylists = value // synchronizuj po każdej zmianie
//        }
//        .onChange(of: scenePhase) { newPhase in
//            if newPhase == .background || newPhase == .inactive {
//                saveIfNeeded()
//            }
//        }
//    }
//    
//    // MARK: - Header
//    private var Header: some View {
//        HStack {
//            Spacer()
//            Text("Twoje playlisty")
//                .font(.system(size: 26, weight: .black, design: .rounded))
//                .foregroundColor(.moda4)
//                .shadow(color: Color.moda1.opacity(0.07), radius: 3, y: 2)
//            Spacer()
//        }
//        .padding(.horizontal)
//        .padding(.top, 18)
//        .padding(.bottom, 4)
//    }
//
//    // MARK: - Create Button
//    private var CreateButtonSection: some View {
//        Group {
//            if playlistsManager.playlists.count < PlaylistsManager.maxPlaylists {
//                Button(action: { withAnimation { showCreatePopup = true } }) {
//                    HStack(spacing: 10) {
//                        Image(systemName: "plus.circle.fill")
//                            .font(.title)
//                            .foregroundColor(.moda2)
//                        Text("Nowa playlista")
//                            .font(.title3.weight(.bold))
//                            .foregroundColor(.moda4)
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding(15)
//                    .background(
//                        RoundedRectangle(cornerRadius: 22)
//                            .fill(Color.moda2.opacity(0.18))
//                            .shadow(color: Color.moda2.opacity(0.06), radius: 4, y: 1)
//                    )
//                }
//                .buttonStyle(.plain)
//                .padding(.horizontal, 18)
//                .padding(.vertical, 10)
//            }
//        }
//    }
//
//    // MARK: - Playlist Tiles
//    private var PlaylistsList: some View {
//        ScrollView {
//            LazyVStack(spacing: 14) {
//                ForEach(Array(localPlaylists.enumerated()), id: \.element.id) { (index, playlist) in
//                    PlaylistTile(
//                        playlist: playlist,
//                        isCurrent: playlistsManager.currentPlaylist?.id == playlist.id,
//                        songCount: playlist.songs.count,
//                        onSelect: {
//                            withAnimation(.easeOut(duration: 0.15)) {
//                                playlistsManager.select(playlist)
//                            }
//                        },
//                        onPlay: {
//                            playlistsManager.select(playlist)
//                        },
//                        onDelete: {
//                            playlistToDelete = playlist
//                            showDeleteAlert = true
//                        }
//                    )
//                }
//            }
//            .padding(.horizontal, 10)
//            .padding(.bottom, 4)
//            .padding(.top, 16)
//        }
//        .frame(maxHeight: 390)
//        .background(Color.clear)
//    }
//}
//
//// MARK: - PlaylistTile as separate view
//private struct PlaylistTile: View {
//    let playlist: Playlist
//    let isCurrent: Bool
//    let songCount: Int
//    var onSelect: () -> Void
//    var onPlay: () -> Void
//    var onDelete: () -> Void
//
//    var body: some View {
//        HStack(spacing: 16) {
//            ZStack {
//                Circle()
//                    .fill(
//                        LinearGradient(
//                            colors: [
//                                isCurrent ? Color.moda2.opacity(0.8) : Color.moda2.opacity(0.39),
//                                Color.moda3.opacity(0.51)
//                            ],
//                            startPoint: .topLeading, endPoint: .bottomTrailing
//                        )
//                    )
//                    .frame(width: 48, height: 48)
//                    .shadow(color: isCurrent ? Color.moda2.opacity(0.25) : .clear, radius: 7, y: 2)
//                Image(systemName: "music.note.list")
//                    .font(.title2.weight(.bold))
//                    .foregroundColor(.moda4)
//            }
//            VStack(alignment: .leading, spacing: 2) {
//                Text(playlist.name)
//                    .font(.system(size: 18, weight: .semibold, design: .rounded))
//                    .foregroundColor(.moda4)
//                    .lineLimit(1)
//                Text("\(songCount) utwor\(songCount == 1 ? "" : "y")")
//                    .font(.caption2)
//                    .foregroundColor(.moda1)
//                    .opacity(0.62)
//            }
//            Spacer()
//            Button(action: { onPlay() }) {
//                Image(systemName: "play.circle.fill")
//                    .font(.title2)
//                    .foregroundColor(.moda2)
//                    .padding(10)
//            }
//            .buttonStyle(.plain)
//            .contentShape(Rectangle())
//            Button(action: { onDelete() }) {
//                Image(systemName: "trash")
//                    .font(.title2)
//                    .foregroundColor(.red)
//                    .padding(10)
//            }
//            .buttonStyle(.plain)
//            .contentShape(Rectangle())
//        }
//        .padding(.vertical, 7)
//        .padding(.horizontal, 10)
//        .background(
//            RoundedRectangle(cornerRadius: 18)
//                .fill(isCurrent ? Color.moda2.opacity(0.19) : Color.moda3.opacity(0.70)) // <--- najważniejsze
//                .shadow(color: isCurrent ? Color.moda2.opacity(0.17) : Color.moda1.opacity(0.06), radius: 7, y: 2)
//        )
//        .onTapGesture { onSelect() }
//    }
//}
//
//
//// MARK: - Save helper
//extension PlaylistsView {
//    private func saveIfNeeded() {
//        if hasChanges {
//            playlistsManager.playlists = localPlaylists
//            playlistsManager.savePlaylists() // lub saveToDisk() w zależności od Twojej metody!
//            hasChanges = false
//        }
//    }
//}
