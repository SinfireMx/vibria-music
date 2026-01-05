import SwiftUI

/// Color utilities and app-specific color palette handling.
/// Provides dynamic access to user-defined colors stored in UserDefaults
/// and helpers for HEX <-> Color conversion.
extension Color {

    /// Reference default color palette (ARGB hex values).
    /// Used as a fallback when no user-defined color is stored.
    /// Kept here for documentation and potential palette reset logic.
    // static let defaultModa: [String] = [
    //     "ff8c6854", // moda1
    //     "ffd89a84", // moda2
    //     "fff2c0ae", // moda3
    //     "ff3f1b13", // moda4
    //     "ff0c0c0c"  // moda5
    // ]

    /// Returns a color from the custom "Moda" palette.
    /// The value is loaded dynamically from UserDefaults,
    /// falling back to the default palette when missing.
    ///
    /// - Parameter idx: Palette index (1...5)
    static func modaX(_ idx: Int) -> Color {
        guard idx >= 1 && idx <= 5 else { return .black }

        let key = "userColorModa\(idx)"
        let hex = UserDefaults.standard.string(forKey: key) ?? defaultModa[idx - 1]

        return Color(hex: hex) ?? .black
    }

    /// Initializes a Color from an ARGB or RGB hex string.
    /// Accepts formats like "RRGGBB" or "AARRGGBB".
    init?(hex: String) {
        var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        // If alpha is missing, assume full opacity
        if hex.count == 6 { hex = "FF" + hex }

        guard hex.count == 8,
              let int = UInt64(hex, radix: 16) else { return nil }

        let a = Double((int & 0xFF000000) >> 24) / 255.0
        let r = Double((int & 0x00FF0000) >> 16) / 255.0
        let g = Double((int & 0x0000FF00) >> 8) / 255.0
        let b = Double(int & 0x000000FF) / 255.0

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Converts the Color to an ARGB hex string.
    /// Useful for persisting user-selected colors.
    func toHex() -> String {
        let uiColor = UIColor(self)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 1

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let rgba =
            (Int(alpha * 255) << 24) |
            (Int(red * 255) << 16) |
            (Int(green * 255) << 8) |
            Int(blue * 255)

        return String(format: "%08x", rgba)
    }
}
