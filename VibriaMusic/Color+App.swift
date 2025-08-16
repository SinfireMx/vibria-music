import SwiftUI

extension Color {
    // Definicja domyślnej palety (przyda się do resetowania!)
//    static let defaultModa: [String] = [
//        "ff8c6854", // moda1
//        "ffd89a84", // moda2
//        "fff2c0ae", // moda3
//        "ff3f1b13", // moda4
//        "ff0c0c0c"  // moda5
//    ]

    // Dynamiczny dostęp do koloru z UserDefaults (lub domyślny)
    static func modaX(_ idx: Int) -> Color {
        guard idx >= 1 && idx <= 5 else { return .black }
        let key = "userColorModa\(idx)"
        let hex = UserDefaults.standard.string(forKey: key) ?? defaultModa[idx - 1]
        return Color(hex: hex) ?? .black
    }

    // Inicjator z HEXa
    init?(hex: String) {
        var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hex.count == 6 { hex = "FF" + hex }
        guard hex.count == 8, let int = UInt64(hex, radix: 16) else { return nil }
        let a = Double((int & 0xFF000000) >> 24) / 255.0
        let r = Double((int & 0x00FF0000) >> 16) / 255.0
        let g = Double((int & 0x0000FF00) >> 8) / 255.0
        let b = Double(int & 0x000000FF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 1
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let rgba = (Int(alpha * 255) << 24) |
                   (Int(red * 255) << 16) |
                   (Int(green * 255) << 8) |
                   Int(blue * 255)
        return String(format: "%08x", rgba)
    }
}
