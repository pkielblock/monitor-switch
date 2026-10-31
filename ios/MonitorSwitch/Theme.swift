import SwiftUI

/// T3 Black, same tokens as the web UI (public/style.css): black background,
/// white overlays for surfaces, one accent.
enum Theme {
    static let bg = Color.black
    static let surface = Color.white.opacity(0.04)
    static let chip = Color.white.opacity(0.06)
    static let raised = Color.white.opacity(0.08)
    static let line = Color.white.opacity(0.08)
    static let toast = Color(white: 0x11 / 255)
    static let accent = Color(red: 0x34 / 255, green: 0x6B / 255, blue: 0xF1 / 255)
    static let bad = Color(red: 240 / 255, green: 92 / 255, blue: 92 / 255)

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
