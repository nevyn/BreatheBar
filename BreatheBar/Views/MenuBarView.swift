import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        if appState.isBreathingTime {
            Button("Done") {
                appState.markDone()
            }
            .keyboardShortcut("d")
            
            Divider()
        }
        
        Toggle("Primed", isOn: Binding(
            get: { appState.isPrimed },
            set: { _ in appState.togglePrimed() }
        ))
        .keyboardShortcut("p")
        
        Button("Settings...") {
            openSettings()
        }
        .keyboardShortcut(",")
        
        Divider()
        
        Button("Quit BreatheBar") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
