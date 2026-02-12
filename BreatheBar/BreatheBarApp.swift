import SwiftUI

@main
struct BreatheBarApp: App {
    @State private var appState = AppState()
    
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
