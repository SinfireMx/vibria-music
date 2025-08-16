import SwiftUI

struct PlayerTitleView: View {
    
    let filename: String
    let font: Font
    let horizontalPadding: CGFloat
    let rightOnlyPadding: Bool

    // Zwraca nazwę pliku bez rozszerzenia
    private var displayTitle: String {
        filename.replacingOccurrences(of: ".mp3", with: "")
    }

    var body: some View {
        HStack {
            MarqueeText(
                text: displayTitle,
                font: font,
                duration: 7.0,
                horizontalPadding: 0 // padding ustawiamy poniżej
            )
            .lineLimit(1)
            .frame(height: 34)
            .padding(.horizontal, rightOnlyPadding ? 0 : horizontalPadding)
            .padding(.trailing, rightOnlyPadding ? horizontalPadding : 0)
        }
        .frame(maxWidth: .infinity)
    }
}
