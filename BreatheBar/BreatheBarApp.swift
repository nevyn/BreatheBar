import SwiftUI

@main
struct BreatheBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView(appState: appDelegate.appState)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    var statusItemController: StatusItemController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController(appState: appState)
        setupObservation()
    }
    
    private func setupObservation() {
        withObservationTracking {
            _ = appState.isBreathingTime
            _ = appState.isPrimed
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.statusItemController?.update()
                self?.setupObservation()
            }
        }
    }
}
