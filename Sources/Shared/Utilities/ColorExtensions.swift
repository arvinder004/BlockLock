import SwiftUI
import AppKit

// MARK: - Hex ↔ Color Conversions

extension Color {
    /// Initialize a SwiftUI Color from a hex string (e.g. "#007AFF" or "007AFF").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // #RRGGBB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // #AARRGGBB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255) // fallback: system blue
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Convert this Color to a hex string (e.g. "#007AFF").
    func toHex() -> String {
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else {
            return "#007AFF"
        }
        let r = Int(nsColor.redComponent * 255)
        let g = Int(nsColor.greenComponent * 255)
        let b = Int(nsColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Preset Color Palette

struct ColorPalette {
    static let presets: [(name: String, hex: String)] = [
        ("Blue",   "#007AFF"),
        ("Purple", "#AF52DE"),
        ("Pink",   "#FF2D55"),
        ("Red",    "#FF3B30"),
        ("Orange", "#FF9500"),
        ("Yellow", "#FFCC00"),
        ("Green",  "#34C759"),
        ("Teal",   "#5AC8FA"),
    ]
}
