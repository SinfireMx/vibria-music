import Foundation
import AVFoundation
import Combine
import MediaPlayer
import CoreMedia

let supportedAudioExtensions: [String] = ["mp3", "m4a", "aac", "wav", "aiff", "aif", "caf"]

enum LoopMode: Int, CaseIterable {
    case off = 0
    case single = 1
    case all = 2
}

extension MusicPlayerViewModel {
    /// Bezwzględne ucięcie dźwięku (na terminację procesu).
    func hardStopAndSilence() {
        // 1) posprzątaj playera
        if let token = timeObserverToken { player?.removeTimeObserver(token); timeObserverToken = nil }
        if let endObs = endObserver { NotificationCenter.default.removeObserver(endObs); endObserver = nil }
        player?.pause()
        player?.replaceCurrentItem(with: nil)   // odpinamy źródło
        player = nil
        isPlaying = false
        progress = 0
        duration = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

        // 2) twarde ucięcie sesji: szybki „flip” na kategorię bez-background
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.soloAmbient, mode: .default, options: []) // kategoria, która nie gra w tle
            try session.setActive(true)   // aktywuj na moment -> pipeline się ucina natychmiast
            try session.setActive(false)  // i od razu wyłącz
        } catch {
            print("hardStopAndSilence() session error: \(error)")
            // awaryjnie – przynajmniej wyłącz
            try? session.setActive(false)
        }
    }
}

class MusicPlayerViewModel: NSObject, ObservableObject {
    let songDidChangePublisher = PassthroughSubject<URL?, Never>()

    var selectedSong: URL? {
        didSet { songDidChangePublisher.send(selectedSong) }
    }

    static let shared = MusicPlayerViewModel()

    /// Trzymamy security-scope, dopóki trwa playback.
    private var securityScopedURL: URL?

    @Published var songs: [URL] = [] {
        didSet {
            updateShuffle()
            updateCurrentIndexAfterSongsChange()
        }
    }
    @Published var progress: Double = 0
    @Published var duration: Double = 1
    @Published var isPlaying: Bool = false
    @Published var allSongs: [URL] = []
    @Published var activeSongs: [URL] = []
    @Published var isShuffling: Bool = false {
        didSet {
            updateShuffle()
            UserDefaults.standard.set(isShuffling, forKey: shuffleKey)
        }
    }
    @Published var loopMode: LoopMode = .off {
        didSet {
            UserDefaults.standard.set(loopMode.rawValue, forKey: loopModeKey)
        }
    }
    @Published var unsupportedFiles: [URL] = []
    @Published var showUnsupportedAlert: Bool = false

    // Seek-state
    @Published var isSeekInProgress: Bool = false
    @Published var seekCompleted: Bool = false

    private let shuffleKey = "vibria_isShuffling"
    private let loopModeKey = "vibria_loopMode"

    private var cancellables: Set<AnyCancellable> = []
    private var shuffledSongs: [URL] = []

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var endObserver: NSObjectProtocol?

    /// Flaga: w trakcie bootu nie zapisuj pustej biblioteki (chroni przed
    /// nadpisaniem, gdy load() zwróci tymczasowo [])
    var suppressEmptySavesDuringBoot: Bool = false

    // Aktywna kolejka (z shuffle)
    var activeList: [URL] { isShuffling ? shuffledSongs : songs }

    // Indeks aktualnego utworu w kolejce
    private var currentIndex: Int? {
        guard let selected = selectedSong else { return nil }
        return activeList.firstIndex(of: selected)
    }

    override init() {
        super.init()
        
        // Persist bookmarks „allSongs” (de-bounce + overlay + blokada pustki przy starcie)
        $allSongs
            .removeDuplicates()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.global(qos: .background))
            .sink { [weak self] urls in
                guard let self = self else { return }
                
                // Nie zapisuj pustej listy podczas rozruchu
                if urls.isEmpty, self.suppressEmptySavesDuringBoot {
                    return
                }
                
                DispatchQueue.main.async {
                    GlobalOverlayManager.shared.show()
                }
                
                // Zapis powinien być SYNCHRONICZNY (albo zapewnij flush przy wychodzeniu)
                BookmarkManager.save(urls: urls)
                
                DispatchQueue.main.async {
                    GlobalOverlayManager.shared.hide()
                }
            }
            .store(in: &cancellables)
        
        setupRemoteTransportControls()
        
        if UserDefaults.standard.object(forKey: shuffleKey) != nil {
            self.isShuffling = UserDefaults.standard.bool(forKey: shuffleKey)
        }
        if let loopValue = UserDefaults.standard.object(forKey: loopModeKey) as? Int,
           let mode = LoopMode(rawValue: loopValue) {
            self.loopMode = mode
        }
    }

    deinit {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
        }
        if let endObserver = endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }

    // MARK: - Remote commands
    func setupRemoteTransportControls() {
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.addTarget { [weak self] _ in self?.play(); return .success }
        cc.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
        cc.nextTrackCommand.addTarget { [weak self] _ in self?.playNext(); return .success }
        cc.previousTrackCommand.addTarget { [weak self] _ in self?.playPrev(); return .success }
        cc.changePlaybackPositionCommand.isEnabled = true
        cc.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.seek(to: e.positionTime)
            return .success
        }
    }

    // MARK: - Public API
    func updateNowPlayingInfo(for song: URL) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = song.lastPathComponent
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progress
        info[MPMediaItemPropertyPlaybackDuration] = duration
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func setSongs(_ urls: [URL]) {
        let (supported, unsupported) = urls.reduce(into: ([URL](), [URL]())) { acc, url in
            if supportedAudioExtensions.contains(url.pathExtension.lowercased()) { acc.0.append(url) }
            else { acc.1.append(url) }
        }
        self.songs = supported
        updateShuffle()
        if !unsupported.isEmpty {
            unsupportedFiles = unsupported
            showUnsupportedAlert = true
        }
    }

    func updateShuffle() {
        shuffledSongs = isShuffling ? songs.shuffled() : []
    }

    func selectSong(_ url: URL) {
        // (A) Security-scoped access – jeśli używasz bookmarków
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

        // (B) Zamiast kasować – nie usuwaj, tylko zignoruj tap,
        //     ewentualnie pokaż własny alert o niedostępnym pliku.
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        guard exists && !isDir.boolValue else {
            // TODO: pokaż alert: "Nie mogę odtworzyć pliku (brak dostępu / przeniesiony)"
            return
        }

        selectedSong = url
        progress = 0
        duration = 1
        updateNowPlayingInfo(for: url)
        startPlayback(url: url)
    }

    func play() {
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func playPause() {
        if player == nil, let song = selectedSong {
            startPlayback(url: song)
            return
        }
        isPlaying ? pause() : play()
    }

    func playNext() {
        guard !activeList.isEmpty, let idx = currentIndex else { return }
        let nextIdx = (idx + 1) % activeList.count
        selectSong(activeList[nextIdx])
    }

    func playPrev() {
        guard !activeList.isEmpty, let idx = currentIndex else { return }
        let prevIdx = (idx - 1 + activeList.count) % activeList.count
        selectSong(activeList[prevIdx])
    }

    func seek(to time: Double) {
        isSeekInProgress = true
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600)) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.progress = time
                self.isSeekInProgress = false
                self.seekCompleted = true
            }
        }
    }

    func stop() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        if let endObserver = endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        player?.pause()
        player = nil
        isPlaying = false
        progress = 0
        duration = 0

        // ⬅️ DOMKNIJ security-scope
        if let u = securityScopedURL {
            u.stopAccessingSecurityScopedResource()
            securityScopedURL = nil
        }
    }


    func removeSong(_ url: URL) {
        songs.removeAll { $0 == url }
        allSongs.removeAll { $0 == url }
        shuffledSongs.removeAll { $0 == url }
        if selectedSong == url {
            stop()
            selectedSong = songs.first
            isPlaying = false
        }
    }

    func selectSongWithoutPlaying(_ url: URL, at time: Double) {
        selectedSong = url
        startPlayback(url: url, at: time, shouldPlay: false)
        isPlaying = false
    }

    // MARK: - Private
    private func startPlayback(url: URL, at time: Double? = nil, shouldPlay: Bool = true) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        progress = 0
        duration = 1
        updateNowPlayingInfo(for: url)

        // Usuń obserwatorów starego playera
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        if let endObs = endObserver {
            NotificationCenter.default.removeObserver(endObs)
            self.endObserver = nil
        }

        // Zatrzymaj starego playera
        player?.pause()
        player = nil

        // ⬅️ ZAMKNIJ scope poprzedniego URL
        if let old = securityScopedURL {
            old.stopAccessingSecurityScopedResource()
            securityScopedURL = nil
        }

        // ⬅️ OTWÓRZ scope dla nowego URL (i trzymaj go)
        let needs = url.startAccessingSecurityScopedResource()
        if needs { securityScopedURL = url }

        // Twórz item najlepiej przez AVURLAsset (by uniknąć leniwych niespodzianek)
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)

        configureAudioSession()

        // Daj klatkę na ustabilizowanie stanu
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            guard let self = self else { return }

            if let t = time {
                self.player?.seek(to: CMTime(seconds: t, preferredTimescale: 600)) { _ in
                    DispatchQueue.main.async {
                        self.progress = t
                        self.objectWillChange.send()
                    }
                }
            }

            self.timeObserverToken = self.player?.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
                queue: .main
            ) { [weak self] time in
                guard let self = self, let item = self.player?.currentItem else { return }
                if !self.isSeekInProgress {
                    self.progress = time.seconds
                    if let songID = self.selectedSong?.lastPathComponent,
                       let songURL = self.selectedSong {
                        ProgressManager.shared.saveProgressIfNeeded(for: songID, position: self.progress)
                        LastPlayedManager.save(url: songURL, time: self.progress)
                    }
                }
                let raw = item.duration.seconds
                self.duration = (raw.isFinite && raw > 0) ? raw : 0.001
                if !self.isSeekInProgress { self.progress = min(self.progress, self.duration) }
                self.isPlaying = self.player?.rate != 0
                self.updateNowPlayingInfo(for: url)
            }

            if shouldPlay { self.player?.play(); self.isPlaying = true } else { self.isPlaying = false }

            self.endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak self] _ in
                self?.handleSongFinished()
            }
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Błąd konfiguracji AudioSession: \(error)")
        }
    }

    func setActiveSongs(from playlist: Playlist?) {
        if let playlist = playlist {
            songs = playlist.songs           // aktywna lista = playlista
        } else {
            songs = allSongs                 // aktywna lista = cała biblioteka
        }
        updateShuffle()
        if let current = selectedSong, !songs.contains(current) {
            selectedSong = songs.first
            if let url = selectedSong { startPlayback(url: url, shouldPlay: false) }
        }
    }

    func setAllSongs(_ urls: [URL]) {
        allSongs = urls
        songs = urls
        setActiveSongs(from: nil)
        if let current = selectedSong, !urls.contains(current) {
            selectedSong = nil
            isPlaying = false
        }
    }

    func flushAllSongsSynchronously() {
        GlobalOverlayManager.shared.show()
        BookmarkManager.save(urls: allSongs)  // synchroniczny zapis
        GlobalOverlayManager.shared.hide()
    }

    private func handleSongFinished() {
        switch loopMode {
        case .off:
            if let idx = currentIndex, idx < activeList.count - 1 {
                selectSong(activeList[idx + 1])
            } else {
                isPlaying = false
            }
        case .single:
            if let url = selectedSong {
                ProgressManager.shared.clearProgress(for: url.lastPathComponent)
                startPlayback(url: url, at: 0, shouldPlay: true)
            }
        case .all:
            playNext()
        }
    }

    // Powiązanie z PlaylistsManager (Combine)
    func bindToPlaylistsManager(_ playlistsManager: PlaylistsManager) {
        playlistsManager.$currentPlaylist
            .sink { [weak self] playlist in
                if let playlist = playlist {
                    self?.songs = playlist.songs
                } else {
                    self?.songs = self?.allSongs ?? []
                }
            }
            .store(in: &cancellables)

        playlistsManager.$playlists
            .sink { [weak self, weak playlistsManager] playlists in
                guard
                    let self = self,
                    let current = playlistsManager?.currentPlaylist,
                    let idx = playlists.firstIndex(where: { $0.id == current.id })
                else { return }
                self.songs = playlists[idx].songs
            }
            .store(in: &cancellables)
    }

    private func updateCurrentIndexAfterSongsChange() {
        if let selected = selectedSong, activeList.firstIndex(of: selected) != nil {
            // OK — nic nie robimy
        } else if let first = activeList.first {
            selectedSong = first
            startPlayback(url: first, shouldPlay: false)
            isPlaying = false
        } else {
            selectedSong = nil
            isPlaying = false
            stop()
        }
    }

    func syncPlayerQueueWithCurrentPlaylist(playlistsManager: PlaylistsManager) {
        if let playlist = playlistsManager.currentPlaylist {
            songs = playlist.songs
        } else {
            songs = allSongs
        }
        updateShuffle()

        if let selected = selectedSong, activeList.contains(selected) {
            startPlayback(url: selected)
        } else if let first = activeList.first {
            startPlayback(url: first)
        } else {
            stop()
            selectedSong = nil
        }
    }
}

// MARK: - Async AudioDurationCache (aktor — zgodny z Drawer)
actor AudioDurationCache {
    static let shared = AudioDurationCache()
    private var cache: [URL: Double] = [:]

    func duration(for url: URL) async -> Double {
        if let d = cache[url] { return d }
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

        let asset = AVURLAsset(url: url)
        do {
            let dur = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(dur)
            let value = seconds.isFinite ? seconds : 0
            cache[url] = value
            return value
        } catch {
            cache[url] = 0
            return 0
        }
    }

    func totalDuration(for urls: [URL]) async -> Double {
        if urls.isEmpty { return 0 }
        var sum: Double = 0
        for u in urls {
            sum += await duration(for: u)
        }
        return sum
    }
}
