import SwiftUI



struct PlayerScreen: View {
    @Binding var selectedSong: URL?
    @Binding var progress: Double
    @Binding var duration: Double
    @Binding var isPlaying: Bool
    @Binding var isShuffling: Bool
    @Binding var loopMode: LoopMode
    @ObservedObject var vm: MusicPlayerViewModel
    @ObservedObject var playlistsManager: PlaylistsManager


    @State private var seekPreview: Double? = nil
    @State private var isSeeking: Bool = false
    @State private var displayedProgress: Double = 0
    @State private var isSongTransitioning: Bool = false
    
    var onPlayPause: (() -> Void)? = nil
    var onNext: (() -> Void)? = nil
    var onPrev: (() -> Void)? = nil
    var onSeek: ((Double) -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.height > geo.size.width
            let landscapePadding: CGFloat = 100
            let sliderBinding = Binding<Double>(
                get: {
                    isSongTransitioning
                        ? 0
                        : (isSeeking || vm.isSeekInProgress
                            ? seekPreview ?? displayedProgress
                            : displayedProgress)
                },
                set: { newValue in
                    seekPreview = newValue
                }
            )
            

            if isPortrait {
                VStack(spacing: 18) {
                    // --- Tytuł + serce ---
                    HStack(spacing: 12) {
                        PlayerTitleView(
                            filename: selectedSong?.lastPathComponent ?? "",
                            font: .title3.weight(.medium),
                            horizontalPadding: 0,
                            rightOnlyPadding: false
                        )
                        Spacer(minLength: 8)
                        if let url = selectedSong {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                playlistsManager.toggleFavorite(url)
                            } label: {
                                let fav = playlistsManager.isFavorite(url)
                                Image(systemName: fav ? "heart.fill" : "heart")
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(fav ? .red : .modaX(3))
                                    .contentTransition(.symbolEffect)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Toggle favorite")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, -360)
                    Spacer(minLength: 2)

                    PlayerSliderView(
                        progress: sliderBinding,
                        duration: $duration,
                        onSeek: { time in
                            isSeeking = false
                            vm.seek(to: time)
                            displayedProgress = time
                        },
                        onEditingChanged: { editing in
                            isSeeking = editing
                        }
                    )
                    .id(selectedSong)

                    PlayerMainControlsView(
                        isPlaying: isPlaying,
                        onPrev: onPrev,
                        onPlayPause: onPlayPause,
                        onNext: onNext,
                        isLandscape: false
                    )
                    PlayerExtraControlsView(
                        isShuffling: $isShuffling,
                        loopMode: $loopMode,
                        onLoopTap: {
                            let next = (loopMode.rawValue + 1) % LoopMode.allCases.count
                            loopMode = LoopMode(rawValue: next)!
                        }
                    )
                    Spacer()
                }
                .padding(.top, 450)
            } else {
                VStack(spacing: 10) {
                    VStack {
                        HStack {
                            PlayerTitleView(
                                filename: selectedSong?.lastPathComponent ?? "",
                                font: .title3.weight(.medium),
                                horizontalPadding: landscapePadding,
                                rightOnlyPadding: true
                            )
                            Spacer()
                            if let url = selectedSong {
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    playlistsManager.toggleFavorite(url)
                                } label: {
                                    let fav = playlistsManager.isFavorite(url)
                                    Image(systemName: fav ? "heart.fill" : "heart")
                                        .font(.title2.weight(.semibold))
                                        .foregroundColor(fav ? .red : .modaX(3))
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, landscapePadding)
                            }
                        }
                        Spacer()
                    }
                    HStack(spacing: 0) {
                        VStack {
                            PlayerExtraControlsView(
                                isShuffling: $isShuffling,
                                loopMode: $loopMode,
                                onLoopTap: {
                                    let next = (loopMode.rawValue + 1) % LoopMode.allCases.count
                                    loopMode = LoopMode(rawValue: next)!
                                }
                            )
                            Spacer()
                            PlayerMainControlsView(
                                isPlaying: isPlaying,
                                onPrev: onPrev,
                                onPlayPause: onPlayPause,
                                onNext: onNext,
                                isLandscape: true
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding( .bottom, 20)

//                    .padding(.top, 50)

//                    .padding(.horizontal, 24)
                    PlayerSliderView(
                        progress: sliderBinding,
                        duration: $duration,
                        onSeek: { time in
                            isSeeking = false
                            vm.seek(to: time)
                            displayedProgress = time
                        },
                        onEditingChanged: { editing in
                            isSeeking = editing
                        }
                    )
                    .id(selectedSong)
                    .frame(maxWidth: .infinity)}
            }
        }
        .onChange(of: vm.seekCompleted) { completed in
            if completed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    seekPreview = nil
                    vm.seekCompleted = false
                }
            }
        }
        .onChange(of: selectedSong) { _ in
            isSongTransitioning = true
            seekPreview = nil
            isSeeking = false
            displayedProgress = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isSongTransitioning = false
            }
        }
        .onChange(of: progress) { newValue in
            if !isSeeking && !vm.isSeekInProgress && !isSongTransitioning {
                displayedProgress = newValue
            }
        }
    }
}
