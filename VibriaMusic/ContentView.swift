import SwiftUI
import AVFoundation   // albo: import AVFAudio (iOS 14+)
import UIKit

private func mergeUnique(_ a: [URL], _ b: [URL]) -> [URL] {
    var seen = Set<String>()
    let all = (a + b).filter { url in
        let key = url.standardizedFileURL.path
        if seen.contains(key) { return false }
        seen.insert(key)
        return true
    }
    return all
}

struct ContentView: View {
    @StateObject private var playerVM = MusicPlayerViewModel.shared
    @State private var showSongList = false
    @State private var showPicker = false
    @StateObject var playlistsManager = PlaylistsManager()
    @StateObject var lang = Lang.shared
    @State private var showSettingsPanel = false
    @Environment(\.scenePhase) private var scenePhase

    
    @AppStorage("resumeLastPlaylist") var resumeLastPlaylist: Bool = true
    @AppStorage("resumePlayback") var resumePlayback: Bool = true

    var body: some View {
        ZStack {
            TrueTriangleTabView(
                playerVM: playerVM,
                showSongList: $showSongList,
                showPicker: $showPicker,
                playlistsManager: playlistsManager,
                showSettingsPanel: $showSettingsPanel
            )
            .environmentObject(lang)

            .sheet(isPresented: $showSettingsPanel) {
                SettingsScreen(isPresented: $showSettingsPanel, playlistsManager: playlistsManager)
                    .environmentObject(lang)
            }

            .sheet(isPresented: $showPicker) {
                DocumentPicker { urls in
                    // 1) scal z biblioteką (bez duplikatów)
                    let merged = playerVM.allSongs + urls.filter { !playerVM.allSongs.contains($0) }
                    playerVM.setAllSongs(merged)

                    // 2) jeśli jesteś w jakiejkolwiek playliście – dodaj też tam
                    if let current = playlistsManager.currentPlaylist {
                        // Ulubione mają własne API
                        if let fav = playlistsManager.favoritesPlaylist, fav.id == current.id {
                            urls.forEach { playlistsManager.addToFavorites($0) }
                        } else {
                            urls.forEach { playlistsManager.addSong($0, to: current) }
                        }
                    }

                    showPicker = false
                }
            }

            .onAppear {
                let start = Date()
                print("⏳ Start ładowania ContentView")

                playerVM.bindToPlaylistsManager(playlistsManager)

                // Na czas boota nie zapisuj pustej biblioteki
                playerVM.suppressEmptySavesDuringBoot = true

                // 1) Wczytaj bibliotekę (jeśli jest)
                let urls = BookmarkManager.load()
                if !urls.isEmpty {
                    playerVM.setAllSongs(urls)
                } else {
                    // NIE wywołujemy setAllSongs([]) – nie nadpisujemy pustką
                    print("⏳ Brak zapisanych zakładek – nie nadpisujemy pustą tablicą.")
                }

                // 2) Ustal aktywną listę przy starcie
                let initialList: [URL]
                if resumeLastPlaylist,
                   let pl = playlistsManager.currentPlaylist,
                   !pl.songs.isEmpty {
                    playerVM.setActiveSongs(from: pl)
                    initialList = pl.songs
                } else {
                    playerVM.setActiveSongs(from: nil)
                    initialList = playerVM.allSongs
                }

                // 3) Odtwórz ostatnio słuchany utwór (jeśli jest w initialList)
                let (lastURL, lastTime) = LastPlayedManager.load()
                if resumePlayback,
                   let url = lastURL,
                   initialList.contains(where: { $0.lastPathComponent == url.lastPathComponent }) {
                    playerVM.selectSongWithoutPlaying(url, at: lastTime)
                } else if let first = initialList.first {
                    playerVM.selectSongWithoutPlaying(first, at: 0)
                } else {
                    playerVM.selectedSong = nil
                    playerVM.isPlaying = false
                }

                // Koniec boota – od teraz można zapisać pustą bibliotekę, jeśli user faktycznie ją wyczyści
                playerVM.suppressEmptySavesDuringBoot = false

                print("⏳ KONIEC .onAppear = \(Date().timeIntervalSince(start)) s")
            }

            .ignoresSafeArea(.keyboard)

            GlobalOverlayView() // overlay „zapisywanie listy”
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                // nic nie trzeba; sesja i tak jest .playback
                break
            case .inactive, .background:
                // tylko domknij zapisy (playlisty + biblioteka)
                playlistsManager.flushPendingSavesSynchronously()
                playerVM.flushAllSongsSynchronously()
            @unknown default:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
            MusicPlayerViewModel.shared.hardStopAndSilence()
            playerVM.stop()
            do {
                try AVAudioSession.sharedInstance()
                    .setActive(false, options: [.notifyOthersOnDeactivation])
            } catch {
                print("AudioSession deactivate error: \(error)")
            }
        }
    }
}
