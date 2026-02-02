import AppKit

@main
final class BreatheBarApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?

    private var isAlerting = false
    private var nextAlert = ReminderModel.nextAlertDate(after: Date())

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = iconImage(t: Date().timeIntervalSinceReferenceDate, alerting: false)
        statusItem.button?.image?.isTemplate = false

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Done", action: #selector(doneTapped), keyEquivalent: "d"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitTapped), keyEquivalent: "q"))
        statusItem.menu = menu

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.tick()
        }
    }

    @objc private func doneTapped() {
        isAlerting = false
        nextAlert = ReminderModel.nextAlertDate(after: Date())
    }

    @objc private func quitTapped() {
        NSApp.terminate(nil)
    }

    private func tick() {
        let now = Date()
        if !isAlerting, now >= nextAlert {
            isAlerting = true
        }
        let t = now.timeIntervalSinceReferenceDate
        statusItem.button?.image = iconImage(t: t, alerting: isAlerting)
    }

    private func iconImage(t: TimeInterval, alerting: Bool) -> NSImage? {
        let base = NSImage(systemSymbolName: "lungs.fill", accessibilityDescription: "Breathe")
        let size: CGFloat = 16
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        let rect = NSRect(x: 0, y: 0, width: size, height: size)

        let scale: CGFloat = alerting ? (1.0 + 0.12 * CGFloat(sin(t * 3.0))) : 1.0
        let rotation = alerting ? CGFloat(sin(t * 2.0) * 0.2) : 0.0

        let color = alertColor(t: t, active: alerting)
        color.set()

        NSGraphicsContext.current?.imageInterpolation = .high
        NSGraphicsContext.saveGraphicsState()
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.translateBy(x: size / 2, y: size / 2)
        ctx.rotate(by: rotation)
        ctx.scaleBy(x: scale, y: scale)
        ctx.translateBy(x: -size / 2, y: -size / 2)
        base?.draw(in: rect)
        NSGraphicsContext.restoreGraphicsState()

        img.unlockFocus()
        return img
    }

    private func alertColor(t: TimeInterval, active: Bool) -> NSColor {
        if !active { return NSColor(white: 0.55, alpha: 1.0) }
        let r = 0.9 + 0.1 * sin(t * 2.2)
        let g = 0.35 + 0.15 * sin(t * 1.7 + 1.0)
        let b = 0.2 + 0.2 * sin(t * 2.9 + 2.0)
        return NSColor(calibratedRed: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
    }
}

enum ReminderModel {
    static func nextAlertDate(after date: Date) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = comps.minute ?? 0

        if minute >= 55 {
            comps.hour = (comps.hour ?? 0) + 1
        }
        comps.minute = 55
        comps.second = 0

        return cal.date(from: comps) ?? date.addingTimeInterval(3600)
    }
}
