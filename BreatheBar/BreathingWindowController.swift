import AppKit
import SwiftUI

@MainActor
final class BreathingWindowController {
    private var panel: NSPanel?
    private var globalClickMonitor: Any?
    private var localKeyMonitor: Any?
    private var isDismissing = false

    /// Called after the window finishes dismissing (fade-out complete).
    var onDismiss: (() -> Void)?

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    // MARK: - Show

    func show(below statusItemButton: NSStatusBarButton?, cadence: Double) {
        // Clean up any leftover panel (creates fresh animation each time)
        if let existing = panel {
            existing.orderOut(nil)
            panel = nil
        }
        removeMonitors()
        isDismissing = false

        // Build the SwiftUI view with a fresh start time
        let breathingView = BreathingSessionView(startDate: Date(), cadence: cadence) { [weak self] in
            Task { @MainActor [weak self] in
                self?.dismiss()
            }
        }
        let hostingView = NSHostingView(rootView: breathingView)
        let size = hostingView.fittingSize

        // Create the panel
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.fullScreenAuxiliary, .transient]

        // Position below the status item, centered horizontally
        if let buttonWindow = statusItemButton?.window {
            let buttonFrame = buttonWindow.frame
            let x = buttonFrame.midX - size.width / 2
            let y = buttonFrame.minY - size.height - 2
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else if let screen = NSScreen.main {
            // Fallback: top-center of screen
            let visibleFrame = screen.visibleFrame
            let x = visibleFrame.midX - size.width / 2
            let y = visibleFrame.maxY - size.height - 8
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.panel = panel

        // Fade in
        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.25
        NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: .easeOut)
        panel.animator().alphaValue = 1.0
        NSAnimationContext.endGrouping()

        // Click outside → dismiss
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.dismiss()
            }
        }

        // Escape key → dismiss
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                Task { @MainActor [weak self] in
                    self?.dismiss()
                }
                return nil
            }
            return event
        }
    }

    // MARK: - Dismiss

    func dismiss() {
        guard !isDismissing, let panel, panel.isVisible else { return }
        isDismissing = true

        removeMonitors()

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.2
        NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: .easeIn)
        NSAnimationContext.current.completionHandler = { [weak self] in
            Task { @MainActor [weak self] in
                self?.finishDismiss()
            }
        }
        panel.animator().alphaValue = 0
        NSAnimationContext.endGrouping()
    }

    // MARK: - Private

    private func finishDismiss() {
        panel?.orderOut(nil)
        panel = nil
        isDismissing = false
        onDismiss?()
    }

    private func removeMonitors() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
    }
}
