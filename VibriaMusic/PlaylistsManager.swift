import Foundation

// MARK: - Model
struct Playlist: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var songs: [URL]

    init(name: String, songs: [URL]) {
        self.id = UUID()
        self.name = name
        self.songs = songs
    }
}

// MARK: - Manager
final class PlaylistsManager: ObservableObject {
    // Public
    @Published var playlists: [Playlist] = []
    @Published var currentPlaylist: Playlist? = nil
    @Published var isSaving: Bool = false

    static let maxPlaylists = 10

    // Private
    private var saveWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 0.6

    private let favoritesIDKey = "vibria_favorites_playlist_id"
    private let favoritesDefaultName = "❤️ Ulubione"
    private let playlistsKey = "vibria_playlists"
    // PlaylistsManager.swift (prywatne klucze)
    private let lastPlaylistKey = "vibria_last_playlist_id"

    // MARK: - Init
    init() {
        loadPlaylists()
        // jeśli użytkownik włączył opcję
        if UserDefaults.standard.bool(forKey: "resumeLastPlaylist"),
           let s = UserDefaults.standard.string(forKey: lastPlaylistKey),
           let id = UUID(uuidString: s),
           let idx = playlists.firstIndex(where: { $0.id == id })
        {
            currentPlaylist = playlists[idx]
        }

    }

    // MARK: - Favorites resolution (ID + fallback po nazwie)
    private func resolveFavoritesID() -> UUID? {
        // 1) spróbuj z UserDefaults
        if let s = UserDefaults.standard.string(forKey: favoritesIDKey),
           let id = UUID(uuidString: s),
           playlists.contains(where: { $0.id == id }) {
            return id
        }
        // 2) fallback po nazwie — jeśli jest lista o nazwie „❤️ Ulubione”, zapisz jej ID
        if let idx = playlists.firstIndex(where: { $0.name == favoritesDefaultName }) {
            let id = playlists[idx].id
            UserDefaults.standard.set(id.uuidString, forKey: favoritesIDKey)
            return id
        }
        return nil
    }

    private var favoritesID: UUID? { resolveFavoritesID() }

    // Public helper – zwraca pełny obiekt „Ulubionych”, jeśli istnieje
    var favoritesPlaylist: Playlist? {
        if let fid = resolveFavoritesID(),
           let idx = playlists.firstIndex(where: { $0.id == fid }) {
            return playlists[idx]
        }
        return nil
    }

    var favoritesCount: Int {
        favoritesPlaylist?.songs.count ?? 0
    }

    // MARK: - Favorites API
    func isFavorite(_ url: URL) -> Bool {
        favoritesPlaylist?.songs.contains(url) ?? false
    }

    @discardableResult
    func ensureFavoritesExists() -> Playlist {
        if let fav = favoritesPlaylist { return fav }
        var new = Playlist(name: favoritesDefaultName, songs: [])
        playlists.append(new)
        // zapisz ID aby nie opierać się na nazwie w przyszłości
        UserDefaults.standard.set(new.id.uuidString, forKey: favoritesIDKey)
        savePlaylistsDebounced()
        return new
    }

    func addToFavorites(_ url: URL) {
        var fav = ensureFavoritesExists()
        if !fav.songs.contains(url) {
            fav.songs.append(url)
            if let idx = playlists.firstIndex(where: { $0.id == fav.id }) {
                playlists[idx] = fav
                savePlaylistsDebounced()
            }
        }
    }

    func removeFromFavorites(_ url: URL) {
        guard var fav = favoritesPlaylist else { return }
        fav.songs.removeAll { $0 == url }
        if let idx = playlists.firstIndex(where: { $0.id == fav.id }) {
            playlists[idx] = fav
            savePlaylistsDebounced()
        }
    }

    func toggleFavorite(_ url: URL) {
        isFavorite(url) ? removeFromFavorites(url) : addToFavorites(url)
    }

    func selectFavorites() {
        let fav = ensureFavoritesExists()   // gwarantuje istnienie listy
        select(fav)                         // <-- to zapisze vibria_last_playlist_id
    }
    
    // MARK: - Persistence
    func savePlaylists() {
        // Oddziel Ulubione od reszty (po ID — z fallbackiem)
        let favID = resolveFavoritesID()
        var fav: Playlist? = nil
        var userLists: [Playlist] = []

        for p in playlists {
            if let fid = favID, p.id == fid {
                fav = p
            } else {
                userLists.append(p)
            }
        }

        // Rotacja tylko na listach użytkownika
        if userLists.count > PlaylistsManager.maxPlaylists {
            userLists = Array(userLists.suffix(PlaylistsManager.maxPlaylists))
        }

        // Sklej z powrotem (Ulubione na początek, jeśli istnieją)
        playlists = (fav != nil) ? [fav!] + userLists : userLists

        do {
            let data = try JSONEncoder().encode(playlists)
            UserDefaults.standard.set(data, forKey: playlistsKey)
        } catch {
            print("Błąd zapisu playlist: \(error)")
        }
    }

    func savePlaylistsAsync() {
        let playlistsCopy = playlists
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(playlistsCopy)
                UserDefaults.standard.set(data, forKey: self.playlistsKey)
                DispatchQueue.main.async {
                    GlobalOverlayManager.shared.hide()
                    self.isSaving = false
                }
            } catch {
                print("Błąd zapisu playlist: \(error)")
                DispatchQueue.main.async {
                    GlobalOverlayManager.shared.hide()
                    self.isSaving = false
                }
            }
        }
    }


    func savePlaylistsDebounced() {
        // show tylko na początku „serii” zmian
        if saveWorkItem == nil && !isSaving {
            GlobalOverlayManager.shared.show()
            isSaving = true
        }
        // rescheduling bez kolejnych show()
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.saveWorkItem = nil          // <— zwolnij, by następna seria znów mogła wywołać show()
            self.savePlaylistsAsync()
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }

    func flushPendingSavesSynchronously() {
        saveWorkItem?.cancel()
        saveWorkItem = nil

        do {
            let data = try JSONEncoder().encode(playlists)
            UserDefaults.standard.set(data, forKey: playlistsKey)
        } catch {
            print("Błąd zapisu playlist (flush): \(error)")
        }

        GlobalOverlayManager.shared.hide()
        isSaving = false
    }


    
    private func loadPlaylists() {
        if let data = UserDefaults.standard.data(forKey: playlistsKey) {
            do {
                playlists = try JSONDecoder().decode([Playlist].self, from: data)
            } catch {
                print("Błąd odczytu playlist: \(error)")
                playlists = []
            }
        }
    }

    // MARK: - CRUD (playlists)
    /// Tworzy nową playlistę użytkownika. Limit jest liczony **bez** „Ulubionych”.
    @MainActor
    @discardableResult
    func createPlaylist(name raw: String) -> Playlist? {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        guard userPlaylistsCount < PlaylistsManager.maxPlaylists else {
            print("🚫 Limit playlist osiągnięty (bez Ulubionych).")
            return nil
        }

        let exists = playlists.contains { $0.name.lowercased() == name.lowercased() }
        guard !exists else {
            print("🚫 Playlista o tej nazwie już istnieje.")
            return nil
        }

        let new = Playlist(name: name, songs: [])
        playlists.append(new)
        savePlaylistsDebounced()
        return new
    }


    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        if currentPlaylist?.id == playlist.id {
            currentPlaylist = nil
        }
        savePlaylistsDebounced()
    }

    func select(_ playlist: Playlist?) {
        currentPlaylist = playlist

        if UserDefaults.standard.bool(forKey: "resumeLastPlaylist") {
            if let p = playlist {
                UserDefaults.standard.set(p.id.uuidString, forKey: lastPlaylistKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastPlaylistKey)
            }
        }
    }


    // MARK: - CRUD (songs)
    func addSong(_ url: URL, to playlist: Playlist) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        if !playlists[idx].songs.contains(url) {
            playlists[idx].songs.append(url)
            savePlaylistsDebounced()
        }
    }

    func removeSong(_ url: URL, from playlist: Playlist, save: Bool = true) {
        if let idx = playlists.firstIndex(where: { $0.id == playlist.id }),
           let songIdx = playlists[idx].songs.firstIndex(of: url) {
            playlists[idx].songs.remove(at: songIdx)
            if currentPlaylist?.id == playlist.id {
                currentPlaylist = playlists[idx]
            }
            if save { savePlaylistsDebounced() }
        }
    }

    func removeSongFromAllPlaylists(_ url: URL, save: Bool = true) {
        for idx in playlists.indices {
            playlists[idx].songs.removeAll { $0 == url }
        }
        if save { savePlaylistsDebounced() }
    }

    func removeSongsFromAllPlaylists(_ urls: [URL], save: Bool = true) {
        for idx in playlists.indices {
            playlists[idx].songs.removeAll { urls.contains($0) }
        }
        if save { savePlaylistsDebounced() }
    }

    func moveSong(in playlist: inout Playlist, from source: IndexSet, to destination: Int) {
        playlist.songs.move(fromOffsets: source, toOffset: destination)
        if let idx = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[idx] = playlist
            savePlaylistsDebounced()
        }
    }

    func updatePlaylistSongs(playlistID: UUID, newSongs: [URL]) {
        if let idx = playlists.firstIndex(where: { $0.id == playlistID }) {
            var updated = playlists[idx]
            updated.songs = newSongs
            playlists[idx] = updated
            savePlaylistsDebounced()
            if currentPlaylist?.id == playlistID {
                currentPlaylist = playlists[idx]
            }
        }
    }

    // MARK: - Liczenie „user lists”
    /// Ile playlist użytkownika (bez „Ulubionych” – wycinamy po ID i dla pewności po nazwie).
    private var userPlaylistsCount: Int {
        let fid = resolveFavoritesID()
        return playlists.filter { $0.id != fid && $0.name != favoritesDefaultName }.count
    }
}

// MARK: - Nawigacja po playlistach
extension PlaylistsManager {
    func selectNextPlaylist() {
        guard !playlists.isEmpty else { return }
        if let current = currentPlaylist,
           let idx = playlists.firstIndex(where: { $0.id == current.id }) {
            let nextIdx = (idx + 1) % playlists.count
            currentPlaylist = playlists[nextIdx]
        } else {
            currentPlaylist = playlists.first
        }
    }

    func selectPrevPlaylist() {
        guard !playlists.isEmpty else { return }
        if let current = currentPlaylist,
           let idx = playlists.firstIndex(where: { $0.id == current.id }) {
            let prevIdx = (idx - 1 + playlists.count) % playlists.count
            currentPlaylist = playlists[prevIdx]
        } else {
            currentPlaylist = playlists.first
        }
    }
}
