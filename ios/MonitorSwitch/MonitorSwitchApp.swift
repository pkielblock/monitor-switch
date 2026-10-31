import SwiftUI

@main
struct MonitorSwitchApp: App {
    // English unless the user picks another language in Settings, whatever the phone's locale.
    @AppStorage("language") private var language = "en"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: language))
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}
