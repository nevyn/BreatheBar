import SwiftUI
import AppKit

@main
struct BreatheBarApp: App {
    @State private var appState = AppState()
    
    init() {
        // Hide dock icon - make this a menu bar only app
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appState)
        } label: {
            AnimatedIcon(isActive: appState.isBreathingTime)
        }
        .menuBarExtraStyle(.menu)
        
        Settings {
            SettingsView(appState: appState)
        }
    }
}
