import Foundation

// MARK: - Model

/// Playlist model stored in UserDefaults (Codable).
/// Contains an id, a display name, and an ordered list of audio file URLs.
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

/// Manages user playlists + Favorites:
/// - CRUD for playlists and songs
/// - Persistence to UserDefaults (debounced / async)
/// - Optional "resume last playlist" behavior
final class PlaylistsManager: ObservableObject {

    // MARK: Published (Public)

    @Published var playlists: [Playlist] = []
    @Published var currentPlaylist: Playlist? = nil
    @Published var isSaving: Bool = false

    static let maxPlaylists = 10

    // MARK: Private (Debounce / Storage Keys)

    private var saveWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 0.6

    private let favoritesIDKey = "vibria_favorites_playlist_id"
    private let favoritesDefaultName = "❤️ Ulubione"
    private let playlistsKey = "vibria_playlists"

    /// Stores the last selected playlist id (used only if the user enables resume).
    private let lastPlaylistKey = "vibria_last_playlist_id"

    // MARK: - Init

    init() {
        loadPlaylists()

        // Restore last selected playlist if the user enabled this option.
        if UserDefaults.standard.bool(forKey: "resumeLastPlaylist"),
           let s = UserDefaults.standard.string(forKey: lastPlaylistKey),
           let id = UUID(uuidString: s),
           let idx = playlists.firstIndex(where: { $0.id == id }) {
            currentPlaylist = playlists[idx]
        }
    }

    // MARK: - Favorites resolution (ID first, name fallback)

    /// Resolves Favorites playlist id using:
    /// 1) persisted id in UserDefaults
    /// 2) fallback to a playlist with the default Favorites name (then persists its id)
    private func resolveFavoritesID() -> UUID? {
        // 1) Try stored id.
        if let s = UserDefaults.standard.string(forKey: favoritesIDKey),
           let id = UUID(uuidString: s),
           playlists.contains(where: { $0.id == id }) {
            return id
        }

        // 2) Fallback by name: if a playlist named "❤️ Ulubione" exists, persist its id.
        if let idx = playlists.firstIndex(where: { $0.name == favoritesDefaultName }) {
            let id = playlists[idx].id
            UserDefaults.standard.set(id.uuidString, forKey: favoritesIDKey)
            return id
        }

        return nil
    }

    private var favoritesID: UUID? { resolveFavoritesID() }

    /// Returns the Favorites playlist object (if it exists).
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

    /// Ensures Favorites exists. If missing, creates it and stores its id.
    @discardableResult
    func ensureFavoritesExists() -> Playlist {
        if let fav = favoritesPlaylist { return fav }

        let new = Playlist(name: favoritesDefaultName, songs: [])
        playlists.append(new)

        // Persist id so we don't have to rely on the name later.
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

    /// Selects Favorites and also persists last playlist id (if resume is enabled).
    func selectFavorites() {
        let fav = ensureFavoritesExists()
        select(fav)
    }

    // MARK: - Persistence

    /// Synchronous save (also enforces max user playlists count).
    func savePlaylists() {
        // Separate Favorites from user playlists (by id, with fallback).
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

        // Apply cap only to user playlists.
        if userLists.count > PlaylistsManager.maxPlaylists {
            userLists = Array(userLists.suffix(PlaylistsManager.maxPlaylists))
        }

        // Rebuild final list (Favorites first if present).
        playlists = (fav != nil) ? [fav!] + userLists : userLists

        do {
            let data = try JSONEncoder().encode(playlists)
            UserDefaults.standard.set(data, forKey: playlistsKey)
        } catch {
            print("Failed to save playlists: \(error)")
        }
    }

    /// Async save used by debounced saving flow.
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
                print("Failed to save playlists: \(error)")
                DispatchQueue.main.async {
                    GlobalOverlayManager.shared.hide()
                    self.isSaving = false
                }
            }
        }
    }

    /// Debounced save:
    /// - Shows the global overlay only once per "burst" of changes
    /// - Reschedules the write until changes stop for `debounceInterval`
    func savePlaylistsDebounced() {
        // Show only at the beginning of a burst.
        if saveWorkItem == nil && !isSaving {
            GlobalOverlayManager.shared.show()
            isSaving = true
        }

        saveWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.saveWorkItem = nil
            self.savePlaylistsAsync()
        }

        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }

    /// Flushes any pending debounced save immediately (synchronous write).
    func flushPendingSavesSynchronously() {
        saveWorkItem?.cancel()
        saveWorkItem = nil

        do {
            let data = try JSONEncoder().encode(playlists)
            UserDefaults.standard.set(data, forKey: playlistsKey)
        } catch {
            print("Failed to flush playlists (sync): \(error)")
        }

        GlobalOverlayManager.shared.hide()
        isSaving = false
    }

    private func loadPlaylists() {
        if let data = UserDefaults.standard.data(forKey: playlistsKey) {
            do {
                playlists = try JSONDecoder().decode([Playlist].self, from: data)
            } catch {
                print("Failed to load playlists: \(error)")
                playlists = []
            }
        }
    }

    // MARK: - CRUD (Playlists)

    /// Creates a new user playlist.
    /// The max limit is counted **excluding** Favorites.
    @MainActor
    @discardableResult
    func createPlaylist(name raw: String) -> Playlist? {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        guard userPlaylistsCount < PlaylistsManager.maxPlaylists else {
            print("🚫 Playlist limit reached (Favorites excluded).")
            return nil
        }

        let exists = playlists.contains { $0.name.lowercased() == name.lowercased() }
        guard !exists else {
            print("🚫 Playlist with this name already exists.")
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

    /// Updates `currentPlaylist` and optionally persists it as the "last playlist".
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

    // MARK: - CRUD (Songs)

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

            // Keep currentPlaylist in sync.
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

            // Keep currentPlaylist in sync.
            if currentPlaylist?.id == playlistID {
                currentPlaylist = playlists[idx]
            }
        }
    }

    // MARK: - User playlist counting

    /// Number of user playlists (Favorites excluded).
    /// Filters by resolved Favorites id and also by name as an extra safety net.
    private var userPlaylistsCount: Int {
        let fid = resolveFavoritesID()
        return playlists
            .filter { $0.id != fid && $0.name != favoritesDefaultName }
            .count
    }
}

// MARK: - Playlist navigation

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
