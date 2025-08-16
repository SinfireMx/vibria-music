import SwiftUI

struct SettingsScreen: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var lang: Lang

    @AppStorage("userColorModa1") var userColorModa1: String = Color.defaultModa[0]
    @AppStorage("userColorModa2") var userColorModa2: String = Color.defaultModa[1]
    @AppStorage("userColorModa3") var userColorModa3: String = Color.defaultModa[2]
    @AppStorage("userColorModa4") var userColorModa4: String = Color.defaultModa[3]
    @AppStorage("userColorModa5") var userColorModa5: String = Color.defaultModa[4]

    @AppStorage("resumePlayback") var resumePlayback: Bool = true
    
    @AppStorage("rememberSliderTimeMode") var rememberSliderTimeMode: Bool = true

    @AppStorage("swipeActionsEnabled") var swipeActionsEnabled: Bool = false
    @AppStorage("drawerAnimationsEnabled") var drawerAnimationsEnabled: Bool = true
    // SettingsScreen.swift (góra pliku, razem z innymi @AppStorage)
    @AppStorage("resumeLastPlaylist") var resumeLastPlaylist: Bool = true

    @AppStorage("windowedListEnabled") var windowedListEnabled: Bool = false
    @AppStorage("windowedListChunk") var windowedListChunk: Int = 100

    @State private var showDeleteAllSongsAlert = false

    @ObservedObject var playlistsManager: PlaylistsManager

    @State private var selectedLanguage: String = Lang.shared.current
    @State private var showResetAlert = false
    @State private var showColorsPanel = false
    @State private var showShareSheet = false

    @State private var colorModa1: Color = .moda1
    @State private var colorModa2: Color = .moda2
    @State private var colorModa3: Color = .moda3
    @State private var colorModa4: Color = .moda4
    @State private var colorModa5: Color = .moda5

    func deleteAllSongs() {
        let vm = MusicPlayerViewModel.shared

        // 1) Wyczyść stan odtwarzacza i listy
        vm.stop()
        vm.selectedSong = nil
        vm.isPlaying = false
        vm.allSongs.removeAll()
        vm.songs.removeAll()

        // 2) Persist – commit pustej biblioteki
        BookmarkManager.clear()   // (nie musisz wołać save([]) – to robi to samo)

        // 3) Wyczyść playlisty
        playlistsManager.playlists.indices.forEach { idx in
            playlistsManager.playlists[idx].songs.removeAll()
        }
        playlistsManager.savePlaylists()

        // 4) (opcjonalnie) zamknij panel ustawień po akcji
        withAnimation { isPresented = false }
    }

    
    var body: some View {
        ZStack {
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                .ignoresSafeArea()
            Color.modaX(5).opacity(0.45).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text(lang.t("settings"))
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { withAnimation { isPresented = false } }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.moda3)
                            .padding(.trailing, 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 2)
                Divider().background(Color.modaX(3).opacity(0.15))
                Button(action: { showShareSheet = true }) {
                    Label(lang.t("shareApp"), systemImage: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(Color.modaX(5).opacity(0.09))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .sheet(isPresented: $showShareSheet) {
                    ActivityView(activityItems: [
                        URL(string: "https://apps.apple.com/app/idXXXXXXXXX")!,
                        "Sprawdź aplikację muzyczną Vibria Music! 🎵"
                    ])
                }
                ScrollView {
                    VStack(spacing: 24) {
                        // Picker języka
                        
                        let codes = lang.languageNames.keys.sorted()
                        HStack {
                            Text("\(lang.t("language")):")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(minWidth: 90, alignment: .leading)
                                .padding(.leading, 10)
                            Picker("", selection: $selectedLanguage) {
                                ForEach(codes, id: \.self) { code in
                                    Text(lang.displayName(for: code)).tag(code)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onChange(of: selectedLanguage) { code in
                                lang.setLanguage(code)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                        .background(Color.modaX(5).opacity(0.11))
                        .cornerRadius(12)
                        
                    Section(header: Text("Funkcjonalność aplikacji")) {

                        Toggle(isOn: $resumePlayback) {
                            Label(
                                lang.t("resumePlaybackOption"),
                                systemImage: "gobackward"
                            )
                        }
                        .padding(.horizontal)
                        Toggle(isOn: $resumeLastPlaylist) {
                            Label(lang.t("Wznów odtwarzanie ostatniej listy po uruchomieniu aplikacji"), systemImage: "music.note.list")
                        }
                        .onChange(of: resumeLastPlaylist) { on in
                            if !on {
                                UserDefaults.standard.removeObject(forKey: "vibria_last_playlist_id")
                            }
                        }
                        .padding(.horizontal)
                        Toggle(isOn: $rememberSliderTimeMode) {
                            Label(lang.t("rememberSliderTimeMode"), systemImage: "clock.arrow.circlepath")
                        }
                        .padding(.horizontal)
                    }

                        Section(header: Text("Wydajność listy")) {
                            Toggle("Gesty przesuwania na liście utworów", isOn: $swipeActionsEnabled)
                            Text("Wyłączenie może przyspieszyć otwieranie bardzo długiej listy (1000+ pozycji).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            Toggle("Animacje wysuwanego panelu (lista utworów)", isOn: $drawerAnimationsEnabled)
                            Text("Wyłączenie może poprawić płynność na bardzo długich listach.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Toggle("Ogranicz widoczne utwory do okna", isOn: $windowedListEnabled)
                            if windowedListEnabled {
                                Stepper(value: $windowedListChunk, in: 50...500, step: 50) {
                                    Text("Rozmiar okna: \(windowedListChunk)")
                                }
                                Text("Renderuje tylko \(windowedListChunk) utworów wokół aktualnie odtwarzanego. Przewijanie dociąga kolejne paczki.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        
                        DisclosureGroup(
                            isExpanded: $showColorsPanel,
                            content: {
                                VStack(spacing: 10) {
                                    colorPickerRow(title: "\(lang.t("color")) 1", color: $colorModa1, key: $userColorModa1, def: Color.defaultModa[0])
                                    colorPickerRow(title: "\(lang.t("color")) 2", color: $colorModa2, key: $userColorModa2, def: Color.defaultModa[1])
                                    colorPickerRow(title: "\(lang.t("color")) 3", color: $colorModa3, key: $userColorModa3, def: Color.defaultModa[2])
                                    colorPickerRow(title: "\(lang.t("color")) 4", color: $colorModa4, key: $userColorModa4, def: Color.defaultModa[3])
                                    colorPickerRow(title: "\(lang.t("color")) 5", color: $colorModa5, key: $userColorModa5, def: Color.defaultModa[4])
                                    Button(action: {
                                        userColorModa1 = Color.defaultModa[0]
                                        userColorModa2 = Color.defaultModa[1]
                                        userColorModa3 = Color.defaultModa[2]
                                        userColorModa4 = Color.defaultModa[3]
                                        userColorModa5 = Color.defaultModa[4]
                                        colorModa1 = .moda1
                                        colorModa2 = .moda2
                                        colorModa3 = .moda3
                                        colorModa4 = .moda4
                                        colorModa5 = .moda5
                                    }) {
                                        Text("\(lang.t("reset colors"))")
                                    }
                                    .foregroundColor(.accentColor)
                                    .padding(.vertical, 8)
                                }
                                .padding(.vertical, 8)
                            },
                            label: {
                                HStack {
                                    Image(systemName: "paintpalette")
                                        .foregroundColor(.moda3)
                                    Text(lang.t("AppColors"))
                                        .foregroundColor(.white.opacity(0.92))
                                        .font(.system(size: 17, weight: .medium))
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Circle().fill(colorModa1).frame(width: 14, height: 14)
                                        Circle().fill(colorModa2).frame(width: 14, height: 14)
                                        Circle().fill(colorModa3).frame(width: 14, height: 14)
                                        Circle().fill(colorModa4).frame(width: 14, height: 14)
                                        Circle().fill(colorModa5).frame(width: 14, height: 14)
                                    }
                                }
                                .padding(.vertical, 7)
                                .padding(.leading, 3)
                                .padding(.trailing, 8)
                                .background(Color.modaX(5).opacity(0.09))
                                .cornerRadius(9)
                            }
                        )

                        Button(role: .destructive) {
                            showDeleteAllSongsAlert = true
                        } label: {
                            Label(lang.t("deleteAllSongs"), systemImage: "trash")
                        }
                        .padding(.horizontal)
                        .alert(lang.t("deleteAllSongsConfirm"), isPresented: $showDeleteAllSongsAlert) {
                            Button(lang.t("delete"), role: .destructive) {
                                // Tutaj wywołaj usuwanie utworów (patrz następny punkt)
                                deleteAllSongs()
                            }
                            Button(lang.t("cancel"), role: .cancel) { }
                        }

                        .padding(.horizontal)
                        .background(Color.modaX(5).opacity(0.12))
                        .cornerRadius(12)
                    }
                    .padding(.top, 18)
                }
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.modaX(5).opacity(0.15))
                    .shadow(radius: 18, y: 8)
            )
            .padding(.horizontal, 8)
            .frame(maxWidth: 430)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        // Synchronizacja: AppStorage <-> State
        .onAppear {
            colorModa1 = Color(hex: userColorModa1) ?? .moda1
            colorModa2 = Color(hex: userColorModa2) ?? .moda2
            colorModa3 = Color(hex: userColorModa3) ?? .moda3
            colorModa4 = Color(hex: userColorModa4) ?? .moda4
            colorModa5 = Color(hex: userColorModa5) ?? .moda5
        }
        .onChange(of: userColorModa1) { colorModa1 = Color(hex: userColorModa1) ?? .moda1 }
        .onChange(of: userColorModa2) { colorModa2 = Color(hex: userColorModa2) ?? .moda2 }
        .onChange(of: userColorModa3) { colorModa3 = Color(hex: userColorModa3) ?? .moda3 }
        .onChange(of: userColorModa4) { colorModa4 = Color(hex: userColorModa4) ?? .moda4 }
        .onChange(of: userColorModa5) { colorModa5 = Color(hex: userColorModa5) ?? .moda5 }
        .onChange(of: colorModa1) { userColorModa1 = colorModa1.toHex() }
        .onChange(of: colorModa2) { userColorModa2 = colorModa2.toHex() }
        .onChange(of: colorModa3) { userColorModa3 = colorModa3.toHex() }
        .onChange(of: colorModa4) { userColorModa4 = colorModa4.toHex() }
        .onChange(of: colorModa5) { userColorModa5 = colorModa5.toHex() }
    }

    func colorPickerRow(title: String, color: Binding<Color>, key: Binding<String>, def: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .frame(minWidth: 90, alignment: .leading)
            ColorPicker("", selection: color)
                .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .background(Color.modaX(5).opacity(0.07))
        .cornerRadius(10)
    }

    func resetApp() {
        // Czyść kolejno:
        playlistsManager.playlists.removeAll()
        playlistsManager.currentPlaylist = nil
        playlistsManager.savePlaylists()
        
        BookmarkManager.clear()
        ProgressManager.shared.clearAllProgress()
        UserDefaults.standard.removeObject(forKey: "selectedLanguage")
        UserDefaults.standard.removeObject(forKey: "vibria_isShuffling")
        UserDefaults.standard.removeObject(forKey: "vibria_loopMode")
        // TODO: wyczyść LastPlayedManager (gdy plik w projekcie)
        // po usunięciu wszystkich z pamięci (songs = [])

    }
}





// Rozszerzenie Color:
extension Color {
    static let defaultModa = [
        "ff8c6854", // moda1
        "ffd89a84", // moda2
        "fff2c0ae", // moda3
        "ff3f1b13", // moda4
        "ff0c0c0c"  // moda5
    ]
    static let moda1 = Color(hex: defaultModa[0])!
    static let moda2 = Color(hex: defaultModa[1])!
    static let moda3 = Color(hex: defaultModa[2])!
    static let moda4 = Color(hex: defaultModa[3])!
    static let moda5 = Color(hex: defaultModa[4])!
}
