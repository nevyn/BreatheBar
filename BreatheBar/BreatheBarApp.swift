import AppKit
import SwiftUI

extension Notification.Name {
    static let openBreatheBarSettings = Notification.Name("openBreatheBarSettings")
    static let settingsWindowClosed = Notification.Name("settingsWindowClosed")
}

// Hidden window provides SwiftUI context for openSettings. Must be first so the environment is ready.
private struct SettingsBridgeView: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 100, height: 100)
            .onReceive(NotificationCenter.default.publisher(for: .openBreatheBarSettings)) { _ in
                Task { @MainActor in
                    NSApp.setActivationPolicy(.regular)
                    try? await Task.sleep(for: .milliseconds(100))
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                    try? await Task.sleep(for: .milliseconds(200))
                    if let win = findSettingsWindow() {
                        win.makeKeyAndOrderFront(nil)
                        win.orderFrontRegardless()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .settingsWindowClosed)) { _ in
                NSApp.setActivationPolicy(.accessory)
            }
    }

    private func findSettingsWindow() -> NSWindow? {
        NSApp.windows.first { win in
            if win.identifier?.rawValue == "com.apple.SwiftUI.Settings" { return true }
            if win.isVisible, win.styleMask.contains(.titled),
               win.title.localizedCaseInsensitiveContains("settings") || win.title.localizedCaseInsensitiveContains("preferences") {
                return true
            }
            if let vc = win.contentViewController, String(describing: type(of: vc)).contains("Settings") {
                return true
            }
            return false
        }
    }
}

@main
struct BreatheBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("Hidden", id: "settingsBridge") {
            SettingsBridgeView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 100, height: 100)
        .defaultPosition(UnitPoint(x: -1, y: -1))

        Settings {
            SettingsView(appState: appDelegate.appState)
                .onDisappear {
                    NotificationCenter.default.post(name: .settingsWindowClosed, object: nil)
                }
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
