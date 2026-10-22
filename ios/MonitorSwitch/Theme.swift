import SwiftUI

/// Rosé Pine (https://rosepinetheme.com), same palette and panels as the web UI (public/style.css).
enum Theme {
    static let base = Color(hex: 0x191724)
    static let surface = Color(hex: 0x1F1D2E)
    static let overlay = Color(hex: 0x26233A)
    static let text = Color(hex: 0xE0DEF4)
    static let muted = Color(hex: 0x908CAA)
    static let love = Color(hex: 0xEB6F92)
    // foam, rose, iris, gold, pine, love
    static let accents: [Color] = [0x9CCFD8, 0xEBBCBA, 0xC4A7E7, 0xF6C177, 0x31748F, 0xEB6F92].map { Color(hex: $0) }

    static func symbol(for icon: String?) -> String {
        switch icon {
        case "laptop": "laptopcomputer"
        case "server": "server.rack"
        case "tv": "tv"
        case "console": "gamecontroller"
        default: "desktopcomputer"
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension View {
    /// The web UI's `.panel`: surface fill, overlay border, soft shadow.
    func panel<S: InsettableShape>(_ shape: S) -> some View {
        background(Theme.surface, in: shape)
            .overlay(shape.strokeBorder(Theme.overlay))
            .shadow(color: .black.opacity(0.25), radius: 15, y: 8)
    }
}
