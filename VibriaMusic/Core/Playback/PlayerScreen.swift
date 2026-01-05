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
    @State private var isCommitSeeking: Bool = false

    var onPlayPause: (() -> Void)? = nil
    var onNext: (() -> Void)? = nil
    var onPrev: (() -> Void)? = nil
    var onSeek: ((Double) -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.height > geo.size.width
            let landscapePadding: CGFloat = 100

            // Slider binding:
            // - Keeps your original "reset to 0 during track transition" behavior
            // - Prevents the 1-tick "snap back" after releasing the slider by holding UI state
            let sliderBinding = Binding<Double>(
                get: {
                    if isSongTransitioning { return 0 }

                    // While dragging or committing a seek, always show the user's intended value
                    // (instead of being overridden by AVPlayer's periodic time observer).
                    if isSeeking || isCommitSeeking || vm.isSeekInProgress {
                        return seekPreview ?? displayedProgress
                    }

                    return displayedProgress
                },
                set: { newValue in
                    // While the user drags, store the preview value here.
                    seekPreview = newValue
                }
            )

            if isPortrait {
                VStack(spacing: 18) {
                    // Title + Favorite button (portrait)
                    HStack(spacing: 12) {
                        PlayerTitleView(
                            filename: selectedSong?.lastPathComponent ?? "",
                            font: .title3.weight(.medium),
                            horizontalPadding: 0,
                            rightOnlyPadding: false
                        )

                        Spacer(minLength: 8)

                        favoriteButtonPortrait()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, -360)

                    Spacer(minLength: 2)

                    PlayerSliderView(
                        progress: sliderBinding,
                        duration: $duration,
                        onSeek: commitSeek(_:),
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
                        onLoopTap: cycleLoopMode
                    )

                    Spacer()
                }
                // Keeps your positioning "under the triangle" in portrait
                .padding(.top, 450)

            } else {
                // Landscape layout (kept the same)
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

                            favoriteButtonLandscape(rightPadding: landscapePadding)
                        }

                        Spacer()
                    }

                    HStack(spacing: 0) {
                        VStack {
                            PlayerExtraControlsView(
                                isShuffling: $isShuffling,
                                loopMode: $loopMode,
                                onLoopTap: cycleLoopMode
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
                    .padding(.bottom, 20)

                    PlayerSliderView(
                        progress: sliderBinding,
                        duration: $duration,
                        onSeek: commitSeek(_:),
                        onEditingChanged: { editing in
                            isSeeking = editing
                        }
                    )
                    .id(selectedSong)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        // Seek sync:
        // Once AVPlayer finishes seeking, release the "commit lock"
        // and allow the periodic observer to drive the UI again.
        .onChange(of: vm.seekCompleted) { completed in
            guard completed else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isCommitSeeking = false
                seekPreview = nil
                vm.seekCompleted = false
            }
        }
        // Track change reset:
        // Clears local slider state to avoid showing stale progress during transitions.
        .onChange(of: selectedSong) { _ in
            isSongTransitioning = true
            seekPreview = nil
            isSeeking = false
            displayedProgress = 0

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isSongTransitioning = false
            }
        }
        // VM progress -> UI:
        // Only update the displayed progress when the user is not interacting
        // and no seek/transition is in progress.
        .onChange(of: progress) { newValue in
            if !isSeeking && !isCommitSeeking && !vm.isSeekInProgress && !isSongTransitioning {
                displayedProgress = newValue
            }
        }
    }

    // MARK: - Actions

    private func cycleLoopMode() {
        let next = (loopMode.rawValue + 1) % LoopMode.allCases.count
        loopMode = LoopMode(rawValue: next) ?? .off
    }

    private func commitSeek(_ time: Double) {
        // Prevent the "1-tick snap back":
        // Until AVPlayer completes the seek, do not allow timeObserver updates
        // to overwrite the UI with the old playback time.
        isCommitSeeking = true

        isSeeking = false
        seekPreview = nil
        displayedProgress = time

        vm.seek(to: time)
        onSeek?(time)
    }

    // MARK: - Favorite buttons (extracted without changing layout)

    @ViewBuilder
    private func favoriteButtonPortrait() -> some View {
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

    @ViewBuilder
    private func favoriteButtonLandscape(rightPadding: CGFloat) -> some View {
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
            .padding(.trailing, rightPadding)
        }
    }
}
