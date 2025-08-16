import SwiftUI

// 1A) Helper do warunkowego nakładania modifierów
extension View {
    @ViewBuilder
    func applyIf<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

struct DrawerSongsListScreen: View {
    @Binding var isPresented: Bool
    @Binding var songs: [URL]
    @ObservedObject var playlistsManager: PlaylistsManager
    var selectedSongId: String // tylko ID

    var onSelect: (URL) -> Void
    var onAddSongs: () -> Void
    var onManagePlaylists: () -> Void

    var onAddToPlaylist: (URL, Playlist) -> Void
    var onRemoveFromPlaylist: (URL) -> Void
    var onDeleteSong: (URL) -> Void
    var currentlyPlayingSong: Binding<URL?>
    var onMoveSongs: (_ newSongs: [URL]) -> Void

    @EnvironmentObject var lang: Lang

    // Info / stan
    @State private var didScrollToCurrentSong = false
    @State private var totalDuration: Double = 0

    // Alerty / popupy single
    @State private var songToDelete: URL? = nil
    @State private var showDeleteDialog: Bool = false
    @State private var showDeleteEverywhereAlert: Bool = false
    @State private var showDeleteFromPlaylistAlert: Bool = false
    @State private var showSearchBar = false
    @State private var searchText = ""
    @State private var showAddToPlaylistPopup = false
    @State private var songToAdd: URL? = nil

    // Tryb edycji / multiselect / batch
    @State private var isEditing: Bool = false
    @State private var selectedSongs: Set<URL> = []
    @State private var showBatchDeleteAlert: Bool = false
    @State private var showBatchDeleteEverywhereAlert: Bool = false
    @State private var showBatchAddPanel: Bool = false

    // Ustawienia
    @AppStorage("swipeActionsEnabled") private var swipeActionsEnabled: Bool = false
    @AppStorage("drawerAnimationsEnabled") private var drawerAnimEnabled: Bool = true

    @AppStorage("windowedListEnabled") private var windowedListEnabled: Bool = false
    @AppStorage("windowedListChunk") private var windowedListChunk: Int = 100

    // Okno widocznych wierszy
    @State private var visibleRange: Range<Int>? = nil
    private let prefetchThreshold = 10 // ile wierszy od krawędzi zaczynamy dociągać

    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.height > geo.size.width

            ZStack {
                backgroundView()

                VStack(spacing: 0) {
                    toolbarView()

                    if playlistsManager.currentPlaylist != nil {
                        backToAllSongsButton()
                    }
                    if showSearchBar {
                        searchBarView()
                    }

                    // Pasek info (liczba & czas)
                    counterBar()

                    if isEditing {
                        editActionsBar(isPortrait: isPortrait)
                            .applyIf(drawerAnimEnabled) { view in
                                view.transition(.move(edge: .top).combined(with: .opacity))
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                    }

                    songsListView(isPortrait: isPortrait)

                    Spacer(minLength: 2)
                    nowPlayingBar()
                }

                // === OVERLAY: Batch Add pełnoekranowo
                if showBatchAddPanel {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            if drawerAnimEnabled { withAnimation { showBatchAddPanel = false } }
                            else { showBatchAddPanel = false }
                        }

                    VStack {
                        BatchAddPanel(
                            playlistsManager: playlistsManager,
                            selectedSongs: Array(selectedSongs),
                            onPick: { playlist in
                                let chosen = Array(selectedSongs)
                                chosen.forEach { onAddToPlaylist($0, playlist) }
                                if drawerAnimEnabled { withAnimation { showBatchAddPanel = false } }
                                else { showBatchAddPanel = false }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            },
                            onClose: {
                                if drawerAnimEnabled { withAnimation { showBatchAddPanel = false } }
                                else { showBatchAddPanel = false }
                            }
                        )
                        .frame(maxWidth: 360)
                        .padding(.horizontal, 20)
                    }
                    .applyIf(drawerAnimEnabled) { view in
                        view.transition(.scale.combined(with: .opacity))
                    }
                    .zIndex(300)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.top, 28)
            .shadow(radius: 28, y: 18)
            // 2A) Transition tylko jeśli włączone animacje
            .applyIf(drawerAnimEnabled) { view in
                view.transition(.move(edge: .bottom))
            }
            // 2B) Sterowanie animacją show/hide
            .animation(drawerAnimEnabled ? .easeInOut(duration: 0.26) : nil, value: isPresented)
            // 2C) Globalnie wyłącz implicitzne animacje w tym poddrzewie, gdy flaga OFF
            .transaction { txn in
                if !drawerAnimEnabled { txn.animation = nil }
            }

            // --- Alerty SINGLE ---
            .alert(lang.t("deleteSongConfirm"), isPresented: $showDeleteDialog) {
                Button(lang.t("delete"), role: .destructive) {
                    if let url = songToDelete {
                        onDeleteSong(url)
                        songToDelete = nil
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    }
                }
                Button(lang.t("cancel"), role: .cancel) { songToDelete = nil }
            } message: { Text(lang.t("deleteSongNote")) }

            .alert(lang.t("deleteSongEverywhere"), isPresented: $showDeleteEverywhereAlert) {
                Button(lang.t("delete"), role: .destructive) {
                    if let url = songToDelete {
                        deleteEverywhere([url])
                        songToDelete = nil
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    }
                }
                Button(lang.t("cancel"), role: .cancel) { songToDelete = nil }
            } message: { Text(lang.t("deleteSongNote")) }

            .alert(lang.t("deleteSongFromPlaylistConfirm"), isPresented: $showDeleteFromPlaylistAlert) {
                Button(lang.t("delete"), role: .destructive) {
                    if let url = songToDelete {
                        onRemoveFromPlaylist(url)
                        songToDelete = nil
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    }
                }
                Button(lang.t("cancel"), role: .cancel) { songToDelete = nil }
            }

            // --- Alerty BATCH ---
            .alert(lang.t("delete"), isPresented: $showBatchDeleteAlert) {
                Button(lang.t("delete"), role: .destructive) {
                    selectedSongs.forEach { onDeleteSong($0) }
                    selectedSongs.removeAll()
                    isEditing = false
                }
                Button(lang.t("cancel"), role: .cancel) { }
            } message: { Text(lang.t("deleteSongNote")) }

            .alert(lang.t("deleteSongEverywhere"), isPresented: $showBatchDeleteEverywhereAlert) {
                Button(lang.t("delete"), role: .destructive) {
                    deleteEverywhere(Array(selectedSongs))
                    selectedSongs.removeAll()
                    isEditing = false
                }
                Button(lang.t("cancel"), role: .cancel) { }
            } message: { Text(lang.t("deleteSongNote")) }

            // --- Overlay: single add do playlisty
            .overlay(
                Group {
                    if showAddToPlaylistPopup, let song = songToAdd {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()
                            .onTapGesture { showAddToPlaylistPopup = false }
                            .zIndex(200)

                        AddToPlaylistPopup(
                            playlistsManager: playlistsManager,
                            song: song,
                            isPresented: $showAddToPlaylistPopup,
                            onAdd: { playlist in onAddToPlaylist(song, playlist) }
                        )
                        .frame(maxWidth: 320)
                        .zIndex(201)
                    }
                }
            )

            // Auto-off edycji na wyjście
            .onDisappear {
                playlistsManager.savePlaylistsDebounced()
                isEditing = false
                selectedSongs.removeAll()
            }
            .task(id: songs) { await recalcTotal() }
        }
    }

    // MARK: - Tło
    @ViewBuilder
    private func backgroundView() -> some View {
        VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
            .ignoresSafeArea()
            .saturation(0.50)
        Color.modaX(5).opacity(0.6).ignoresSafeArea()
        LinearGradient(
            gradient: Gradient(colors: [ Color.modaX(5).opacity(0.5), Color.modaX(4).opacity(0.5) ]),
            startPoint: .top, endPoint: .bottom
        ).ignoresSafeArea()
    }

    // MARK: - Pasek licznika
    @ViewBuilder
    private func counterBar() -> some View {
        let count: Int = songs.count
        let countLabel: String = (lang.current == "pl") ? "utworów" : "songs"
        HStack {
            Text("\(count) \(countLabel) • \(totalDuration.hmsString)")
                .font(.footnote)
                .foregroundColor(.modaX(3).opacity(0.78))
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(Color.modaX(5).opacity(0.06))
                .cornerRadius(8)
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.bottom, 2)
    }

    // MARK: - Toolbar
    @ViewBuilder
    private func toolbarView() -> some View {
        HStack(spacing: 12) {
            Button(action: { showSearchBar.toggle() }) {
                Image(systemName: "magnifyingglass").font(.title3).padding(8)
            }
            Button(action: onAddSongs) {
                Image(systemName: "plus.circle").font(.title3).padding(8)
            }
            Button(action: onManagePlaylists) {
                Image(systemName: "text.badge.plus").font(.title3).padding(8)
            }
            if playlistsManager.favoritesCount > 0 {
                Button {
                    playlistsManager.selectFavorites()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "heart.fill").font(.title3).padding(8)
                }
            }
            Spacer()
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if drawerAnimEnabled {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isEditing.toggle()
                        selectedSongs.removeAll()
                    }
                } else {
                    isEditing.toggle()
                    selectedSongs.removeAll()
                }
            }) {
                Image(systemName: isEditing ? "checkmark.circle" : "square.and.pencil")
                    .font(.title3)
                    .padding(8)
            }
            Button(action: {
                if drawerAnimEnabled { withAnimation { isPresented = false } }
                else { isPresented = false }
                isEditing = false
                selectedSongs.removeAll()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .padding(8)
            }
        }
        .foregroundColor(.modaX(2))
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 2)
    }

    // MARK: - Back
    @ViewBuilder
    private func backToAllSongsButton() -> some View {
        Button(action: {
            withAnimation {
                playlistsManager.select(nil)
                isEditing = false
                selectedSongs.removeAll()
            }
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text(lang.t("allSongs")).font(.headline)
            }
            .foregroundColor(.modaX(2))
            .padding(.vertical, 6)
            .padding(.leading, 12)
        }
    }

    // MARK: - Search
    @ViewBuilder
    private func searchBarView() -> some View {
        HStack {
            TextField(lang.t("searchSong"), text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
            Button(action: { showSearchBar = false; searchText = "" }) {
                Image(systemName: "xmark").foregroundColor(.modaX(3).opacity(0.5))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    // MARK: - Edit actions bar
    @ViewBuilder
    private func editActionsBar(isPortrait: Bool) -> some View {
        HStack(spacing: 10) {
            Button {
                if selectedSongs.count == filteredSongs.count {
                    selectedSongs.removeAll()
                } else {
                    selectedSongs = Set(filteredSongs)
                }
            } label: {
                if isPortrait {
                    Image(systemName: selectedSongs.count == filteredSongs.count ? "xmark.circle" : "checkmark.circle")
                } else {
                    Label(
                        selectedSongs.count == filteredSongs.count ? lang.t("clear") : lang.t("selectAll"),
                        systemImage: selectedSongs.count == filteredSongs.count ? "xmark.circle" : "checkmark.circle"
                    )
                }
            }
            .buttonStyle(.bordered)
            .tint(.modaX(2))

            Button {
                guard !selectedSongs.isEmpty else { return }
                handleBatchDeleteCheck()
            } label: {
                if isPortrait { Image(systemName: "trash") }
                else { Label(lang.t("delete"), systemImage: "trash") }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red.opacity(0.92))

            Button {
                guard !selectedSongs.isEmpty else { return }
                withAnimation { showBatchAddPanel = true }
            } label: {
                if isPortrait { Image(systemName: "text.badge.plus") }
                else { Label(lang.t("addToPlaylist"), systemImage: "text.badge.plus") }
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text(lang.t("reorder"))
            }
            .foregroundColor(.modaX(3).opacity(0.8))
            .font(.footnote.weight(.semibold))
        }
    }

    // MARK: - Wyliczenia listy
    private var displaySongs: [URL] {
        // Wyszukiwanie lub edycja → wyłącz okno, pokazuj całość filtrowaną
        if !windowedListEnabled || isEditing || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return filteredSongs
        }
        guard let r = visibleRange, !filteredSongs.isEmpty else {
            return filteredSongs
        }
        // Zabezpieczenie gdy filteredSongs się zmieniły
        let safeR = clampRange(r.lowerBound, min(r.upperBound, filteredSongs.count))
        if safeR.isEmpty { return filteredSongs }
        return Array(filteredSongs[safeR])
    }

    private var baseListCount: Int { filteredSongs.count }

    private func clampRange(_ lower: Int, _ upper: Int) -> Range<Int> {
        let lo = max(0, min(lower, baseListCount))
        let up = max(0, min(upper, baseListCount))
        return lo..<max(lo, up)
    }

    private func centerWindow(around idx: Int) {
        let radius = max(1, windowedListChunk / 2)
        var lower = idx - radius
        var upper = idx + radius
        // podstawowe okno
        var r = clampRange(lower, upper)
        // zagwarantuj pełny rozmiar (o ile mamy dane)
        if r.count < windowedListChunk {
            let deficit = windowedListChunk - r.count
            lower = max(0, r.lowerBound - (deficit/2))
            upper = min(baseListCount, r.upperBound + (deficit - (deficit/2)))
            r = clampRange(lower, upper)
        }
        visibleRange = r
    }

    private func ensureInitialWindow() {
        guard windowedListEnabled, visibleRange == nil else { return }
        // kotwica = aktualnie odtwarzany
        if let current = currentlyPlayingSong.wrappedValue,
           let i = filteredSongs.firstIndex(of: current) {
            centerWindow(around: i)
        } else {
            // brak aktualnego — start od początku
            let up = min(baseListCount, windowedListChunk)
            visibleRange = 0..<up
        }
    }

    private func extendForwardIfNeeded(index: Int) {
        guard windowedListEnabled, let r = visibleRange else { return }
        guard index >= r.upperBound - prefetchThreshold else { return }

        let targetUpper = min(baseListCount, r.upperBound + max(20, windowedListChunk/2))
        var newLower = r.lowerBound
        if targetUpper - newLower > windowedListChunk {
            newLower = targetUpper - windowedListChunk
        }
        visibleRange = clampRange(newLower, targetUpper)
    }

    private func extendBackwardIfNeeded(index: Int) {
        guard windowedListEnabled, let r = visibleRange else { return }
        guard index <= r.lowerBound + prefetchThreshold else { return }

        let targetLower = max(0, r.lowerBound - max(20, windowedListChunk/2))
        var newUpper = r.upperBound
        if newUpper - targetLower > windowedListChunk {
            newUpper = targetLower + windowedListChunk
        }
        visibleRange = clampRange(targetLower, newUpper)
    }

    // MARK: - Lista
    @ViewBuilder
    private func songsListView(isPortrait: Bool) -> some View {
        ScrollViewReader { scrollProxy in
            List {
                ForEach(displaySongs, id: \.self) { song in
                    let globalIndex = filteredSongs.firstIndex(of: song) ?? 0  // pozycja w bazie
                    HStack(spacing: 10) {
                        // Checkbox w trybie edycji
                        if isEditing {
                            Button {
                                toggleSelect(song)
                            } label: {
                                Image(systemName: selectedSongs.contains(song) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedSongs.contains(song) ? .accentColor : .modaX(3))
                            }
                            .buttonStyle(.plain)
                        }

                        songRow(for: song)
                            .contentShape(Rectangle())
                            .onTapGesture { onSelect(song) }
                            .onLongPressGesture(minimumDuration: 0.4) {
                                guard !isEditing else { return }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.18)) { isEditing = true }
                            }
                    }
                    .id(song)
                    .onAppear {
                        // dociąganie przy krawędziach
                        extendForwardIfNeeded(index: globalIndex)
                        extendBackwardIfNeeded(index: globalIndex)
                    }
                    .listRowBackground(
                        (song == currentlyPlayingSong.wrappedValue) ? Color.modaX(2).opacity(0.18) : Color.clear
                    )
                }
                .onMove { indices, newOffset in
                    guard isEditing, searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    songs.move(fromOffsets: indices, toOffset: newOffset)
                    onMoveSongs(songs)
                }
                .moveDisabled(windowedListEnabled || !isEditing || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .padding(.top, 2)
            .padding(.bottom, 12)
            .onAppear {
                // najpierw ustaw okno, żeby bieżący utwór był w displaySongs
                ensureInitialWindow()

                if !didScrollToCurrentSong,
                   let current = currentlyPlayingSong.wrappedValue,
                   displaySongs.contains(current) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        if drawerAnimEnabled {
                            withAnimation { scrollProxy.scrollTo(current, anchor: .center) }
                        } else {
                            scrollProxy.scrollTo(current, anchor: .center)
                        }
                        didScrollToCurrentSong = true
                    }
                }
            }
            .onDisappear {
                didScrollToCurrentSong = false
                playlistsManager.savePlaylistsDebounced()
            }
        }
        .onAppear {
            ensureInitialWindow()
        }
        .onChange(of: songs) { _ in
            // baza się zmieniła — przelicz okno
            visibleRange = nil
            ensureInitialWindow()
        }
        .onChange(of: currentlyPlayingSong.wrappedValue) { _ in
            guard windowedListEnabled else { return }
            if let current = currentlyPlayingSong.wrappedValue,
               let i = filteredSongs.firstIndex(of: current) {
                // Jeśli wyszedłeś poza okno – przesuń okno, ale nie skacz bez potrzeby
                if let r = visibleRange, !r.contains(i) {
                    centerWindow(around: i)
                }
            }
        }
        .onChange(of: searchText) { _ in
            // search OFF -> wróć do okna; search ON -> pokaż całość
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ensureInitialWindow()
            }
        }
        .onChange(of: windowedListEnabled) { enabled in
            visibleRange = nil
            if enabled { ensureInitialWindow() }
        }
        .onChange(of: windowedListChunk) { _ in
            if let current = currentlyPlayingSong.wrappedValue,
               let i = filteredSongs.firstIndex(of: current) {
                centerWindow(around: i)
            } else {
                visibleRange = nil
                ensureInitialWindow()
            }
        }
    }

    // MARK: - Pojedynczy wiersz
    @ViewBuilder
    private func songRow(for song: URL) -> some View {
        let isPlaying = song.absoluteString == selectedSongId
        HStack {
            Text(song.lastPathComponent.replacingOccurrences(of: "\\.[^.]+$", with: "", options: .regularExpression))
                .foregroundColor(isPlaying ? .white : .modaX(3))
                .fontWeight(isPlaying ? .bold : .regular)
                .lineLimit(1)
                .truncationMode(.middle)
                .font(.system(size: 12, weight: .medium))
                .padding(.vertical, 5)
            Spacer(minLength: 8)
            if isPlaying {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.modaX(2))
            }
        }
        .applyIf(swipeActionsEnabled) { view in
            view.swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if !isEditing {
                    Button(role: .destructive) {
                        songToDelete = song
                        if playlistsManager.currentPlaylist != nil {
                            showDeleteFromPlaylistAlert = true
                        } else if playlistsManager.playlists.contains(where: { $0.songs.contains(song) }) {
                            showDeleteEverywhereAlert = true
                        } else {
                            showDeleteDialog = true
                        }
                    } label: { Label(lang.t("delete"), systemImage: "trash") }
                }
            }
        }
        .applyIf(swipeActionsEnabled) { view in
            view.swipeActions(edge: .leading, allowsFullSwipe: false) {
                if !isEditing {
                    Button {
                        songToAdd = song
                        showAddToPlaylistPopup = true
                    } label: { Label(lang.t("addToPlaylist"), systemImage: "text.badge.plus") }
                    .tint(.accentColor)
                }
            }
        }
    }

    // MARK: - Mini player
    @ViewBuilder
    private func nowPlayingBar() -> some View {
        if let s = currentlyPlayingSong.wrappedValue {
            MiniPlayerBar(songTitle: s.lastPathComponent) {
                if drawerAnimEnabled { withAnimation { isPresented = false } }
                else { isPresented = false }
                isEditing = false
                selectedSongs.removeAll()
            }
        }
    }

    // MARK: - Helpers
    private func toggleSelect(_ song: URL) {
        if selectedSongs.contains(song) { selectedSongs.remove(song) }
        else { selectedSongs.insert(song) }
    }

    private func handleBatchDeleteCheck() {
        let anyInPlaylists = playlistsManager.playlists.contains { !selectedSongs.isDisjoint(with: $0.songs) }
        if anyInPlaylists {
            showBatchDeleteEverywhereAlert = true
        } else {
            showBatchDeleteAlert = true
        }
    }

    private func deleteEverywhere(_ urls: [URL]) {
        for url in urls {
            onDeleteSong(url)
            playlistsManager.playlists.indices.forEach { idx in
                playlistsManager.playlists[idx].songs.removeAll { $0 == url }
            }
        }
        playlistsManager.savePlaylists()
    }

    @MainActor
    private func recalcTotal() async {
        let value = await AudioDurationCache.shared.totalDuration(for: songs)
        self.totalDuration = value
    }

    // Filtrowanie
    var filteredSongs: [URL] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return songs }
        return songs.filter { $0.lastPathComponent.lowercased().contains(q) }
    }
}

// MARK: - Batch Add Panel
private struct BatchAddPanel: View {
    @ObservedObject var playlistsManager: PlaylistsManager
    let selectedSongs: [URL]
    let onPick: (Playlist) -> Void
    let onClose: () -> Void

    private func allSelectedAreIn(_ playlist: Playlist) -> Bool {
        Set(selectedSongs).isSubset(of: Set(playlist.songs))
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Dodaj zaznaczone do playlisty")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 8)

            Divider().opacity(0.15)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(playlistsManager.playlists) { pl in
                        Button {
                            onPick(pl)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "music.note.list")
                                    .imageScale(.large)
                                    .opacity(0.9)
                                Text(pl.name)
                                    .font(.body.weight(.semibold))
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                                Spacer()
                                if allSelectedAreIn(pl) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .imageScale(.large)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.modaX(5).opacity(0.35))
                            )
                        }
                    }
                }
                .padding(14)
            }
            .frame(maxHeight: 380)

            HStack {
                Button(role: .cancel, action: onClose) {
                    Text("Zamknij").fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .tint(.modaX(3))
            }
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.modaX(2).opacity(0.15), lineWidth: 1)
                )
                .shadow(radius: 18, y: 8)
        )
    }
}

// MARK: - Mini-player
struct MiniPlayerBar: View {
    let songTitle: String
    let onTap: () -> Void
    @AppStorage("drawerAnimationsEnabled") private var drawerAnimEnabled: Bool = true

    @State private var textHeight: CGFloat = 0
    private let maskHeight: CGFloat = 27

    @State private var offset: CGFloat = 0
    @State private var cycle: Int = 0

    private func scrollDuration(distance: CGFloat) -> Double {
        max(Double(distance) / 10, 3.0)
    }
    private let pause: Double = 1.3

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.modaX(2))
                    .padding(.leading, 8)

                ZStack(alignment: .topLeading) {
                    Text(songTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(
                            GeometryReader { tGeo in
                                Color.clear
                                    .onAppear { textHeight = tGeo.size.height }
                                    .onChange(of: tGeo.size.height) { newValue in textHeight = newValue }
                            }
                        )
                        .offset(y: offset)
                }
                .frame(height: maskHeight, alignment: .top)
                .clipped()
                .padding(.trailing, 4)
                .onAppear { resetAnimation() }
                .onChange(of: songTitle) { _ in resetAnimation() }

                Spacer()

                Image(systemName: "chevron.up")
                    .foregroundColor(.modaX(3))
                    .padding(.trailing, 12)
            }
            .frame(height: 54)
            .background(
                VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                    .background(Color.modaX(5).opacity(0.95))
            )
            .cornerRadius(19)
            .shadow(radius: 10, y: -1)
            .padding([.horizontal, .bottom], 14)
            .applyIf(drawerAnimEnabled) { view in
                view.transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func resetAnimation() {
        offset = 0
        cycle += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            runAnimationIfNeeded()
        }
    }

    private func runAnimationIfNeeded() {
        guard textHeight > maskHeight else { return }
        let scrollDist = -(textHeight - maskHeight)
        let duration = scrollDuration(distance: abs(scrollDist))
        let currentCycle = cycle

        DispatchQueue.main.asyncAfter(deadline: .now() + pause) {
            guard currentCycle == cycle else { return }
            withAnimation(.linear(duration: duration)) { offset = scrollDist }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + pause) {
                guard currentCycle == cycle else { return }
                withAnimation(.linear(duration: 0.25)) { offset = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    guard currentCycle == cycle else { return }
                    runAnimationIfNeeded()
                }
            }
        }
    }
}
