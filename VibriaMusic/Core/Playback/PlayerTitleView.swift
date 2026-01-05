import SwiftUI

struct PlayerTitleView: View {

    /// Full filename including extension (e.g. "song.mp3")
    let filename: String

    /// Font used for the title text
    let font: Font

    /// Horizontal padding applied to both sides
    /// (ignored if `rightOnlyPadding` is enabled)
    let horizontalPadding: CGFloat

    /// If true, padding is applied only to the trailing side
    /// Used mainly for landscape layouts
    let rightOnlyPadding: Bool

    /// Returns the filename without extension
    /// Used as a clean display title for the player UI
    private var displayTitle: String {
        filename.replacingOccurrences(of: ".mp3", with: "")
    }

    var body: some View {
        HStack {
            // Marquee text is used to smoothly scroll long titles
            MarqueeText(
                text: displayTitle,
                font: font,
                duration: 7.0,
                horizontalPadding: 0 // padding is handled below
            )
            .lineLimit(1)
            .frame(height: 34)
            // Apply symmetric or trailing-only padding depending on layout
            .padding(.horizontal, rightOnlyPadding ? 0 : horizontalPadding)
            .padding(.trailing, rightOnlyPadding ? horizontalPadding : 0)
        }
        .frame(maxWidth: .infinity)
    }
}
