import AppKit

@MainActor
final class BreatheBarApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?

    private var isAlerting = false
    private var nextAlert = ReminderModel.nextAlertDate(after: Date())

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        // Make it unmissable during debugging: always ensure either image or title is set.
        statusItem.button?.title = ""
        setIdleAppearance()

        let menu = NSMenu()

        let done = NSMenuItem(title: "Done", action: #selector(doneTapped), keyEquivalent: "d")
        done.target = self
        menu.addItem(done)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit", action: #selector(quitTapped), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu

        // Drive state + animation.
        timer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    @objc private func doneTapped() {
        isAlerting = false
        nextAlert = ReminderModel.nextAlertDate(after: Date())
        setIdleAppearance(flash: true)
    }

    @objc private func quitTapped() {
        NSApp.terminate(nil)
    }

    private func tick() {
        let now = Date()
        if !isAlerting, now >= nextAlert {
            isAlerting = true
        }

        if isAlerting {
            setAlertAppearance(now: now)
        } else {
            setIdleAppearance()
        }
    }

    private func setIdleAppearance(flash: Bool = false) {
        let symbol = flash ? "sparkles" : "lungs"
        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Breathe")
        statusItem.button?.image?.isTemplate = true
        statusItem.button?.contentTintColor = NSColor(white: flash ? 0.85 : 0.55, alpha: 1.0)
        statusItem.button?.toolTip = "BreatheBar"
    }

    private func setAlertAppearance(now: Date) {
        let t = now.timeIntervalSinceReferenceDate

        // Three-axis noise: alternate symbol, jitter tint, and occasional sparkles.
        let phase = Int((t * 3.0).rounded(.down)) % 3
        let symbol: String
        switch phase {
        case 0: symbol = "lungs.fill"
        case 1: symbol = "wind"
        default: symbol = "sparkles"
        }

        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Breathe reminder")
        statusItem.button?.image?.isTemplate = true

        // Warm flicker.
        let r = 0.95 + 0.05 * sin(t * 2.2)
        let g = 0.35 + 0.25 * sin(t * 1.7 + 1.0)
        let b = 0.20 + 0.20 * sin(t * 2.9 + 2.0)
        statusItem.button?.contentTintColor = NSColor(calibratedRed: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)

        statusItem.button?.toolTip = "Breathe. Then click Done."
    }
}

enum ReminderModel {
    static func nextAlertDate(after date: Date) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = comps.minute ?? 0

        // Start idle on launch. Only trigger once we *reach* :55.
        if minute >= 55 {
            comps.hour = (comps.hour ?? 0) + 1
        }
        comps.minute = 55
        comps.second = 0

        return cal.date(from: comps) ?? date.addingTimeInterval(3600)
    }
}

@main
enum Main {
    static func main() {
        let app = NSApplication.shared
        let delegate = BreatheBarApp()
        app.delegate = delegate

        // Menu bar only, no Dock icon.
        app.setActivationPolicy(.accessory)

        app.run()
    }
}
