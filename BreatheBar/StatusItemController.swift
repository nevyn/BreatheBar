import AppKit
import SwiftUI

@MainActor
final class StatusItemController {
    private var statusItem: NSStatusItem?
    private var animationTimer: Timer?
    private var animationStartTime: Date?
    private let appState: AppState
    private let settingsWindowController: SettingsWindowController
    
    // Fixed icon size to prevent jumping
    private let iconSize: CGFloat = 22
    
    init(appState: AppState) {
        self.appState = appState
        self.settingsWindowController = SettingsWindowController(appState: appState)
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        // Use fixed length to prevent jumping during animation
        statusItem = NSStatusBar.system.statusItem(withLength: 24)
        
        updateIcon(animated: false)
        
        // Build menu
        let menu = NSMenu()
        
        // Done item (initially hidden)
        let doneItem = NSMenuItem(title: "Done", action: #selector(doneClicked), keyEquivalent: "d")
        doneItem.target = self
        doneItem.tag = 1
        doneItem.isHidden = true
        menu.addItem(doneItem)
        
        let separator1 = NSMenuItem.separator()
        separator1.tag = 2
        separator1.isHidden = true
        menu.addItem(separator1)
        
        // Primed toggle
        let primedItem = NSMenuItem(title: "Remind me to Breathe", action: #selector(togglePrimed), keyEquivalent: "r")
        primedItem.target = self
        primedItem.tag = 3
        primedItem.state = appState.isPrimed ? .on : .off
        menu.addItem(primedItem)
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // About
        let aboutItem = NSMenuItem(title: "About BreatheBar", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        #if DEBUG
        let testItem = NSMenuItem(title: "Test Animation", action: #selector(testAnimation), keyEquivalent: "t")
        testItem.target = self
        testItem.tag = 100
        menu.addItem(testItem)
        #endif
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit BreatheBar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    func update() {
        // Update menu items based on state
        if let menu = statusItem?.menu {
            if let doneItem = menu.item(withTag: 1) {
                doneItem.isHidden = !appState.isBreathingTime
            }
            if let separator = menu.item(withTag: 2) {
                separator.isHidden = !appState.isBreathingTime
            }
            if let primedItem = menu.item(withTag: 3) {
                primedItem.state = appState.isPrimed ? .on : .off
            }
            #if DEBUG
            if let testItem = menu.item(withTag: 100) {
                testItem.title = appState.isBreathingTime ? "Stop Test Animation" : "Test Animation"
            }
            #endif
        }
        
        // Handle animation state
        if appState.isBreathingTime && animationTimer == nil {
            startAnimation()
        } else if !appState.isBreathingTime && animationTimer != nil {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        animationStartTime = Date()
        updateIcon(animated: true)
        
        // 30fps for smooth animation
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateIcon(animated: true)
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        animationStartTime = nil
        updateIcon(animated: false)
    }
    
    private func updateIcon(animated: Bool) {
        guard let button = statusItem?.button else { return }
        button.image = makeIcon(animated: animated)
    }
    
    private func makeIcon(animated: Bool) -> NSImage {
        // Calculate animation values
        var rotation: CGFloat = 0
        var scaleAmount: CGFloat = 1.0
        var colorAmount: CGFloat = 0  // 0 = template/grayscale, 1 = full green
        
        if animated, let startTime = animationStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            
            // Smooth sine-based animation
            rotation = 10 * sin(elapsed * 2.5)
            scaleAmount = 1.0 + 0.12 * sin(elapsed * 3.0 + 0.5)
            
            // Color: fade in over first 0.8s, then pulse subtly
            let fadeIn = min(1.0, elapsed / 0.8)
            let colorPulse = 0.85 + 0.15 * sin(elapsed * 2.0)
            colorAmount = fadeIn * colorPulse
        }
        
        // Use drawing handler which automatically handles retina
        let image = NSImage(size: NSSize(width: iconSize, height: iconSize), flipped: false) { [self] rect in
            self.drawIcon(in: rect, rotation: rotation, scale: scaleAmount, colorAmount: colorAmount)
            return true
        }
        
        // Only use template mode when fully grayscale
        image.isTemplate = (colorAmount == 0)
        
        return image
    }
    
    private func drawIcon(in rect: NSRect, rotation: CGFloat, scale: CGFloat, colorAmount: CGFloat) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Get the SF Symbol
        let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        guard let symbolImage = NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: "BreatheBar")?
            .withSymbolConfiguration(config) else { return }
        
        let symbolSize = symbolImage.size
        let centerX = rect.midX
        let centerY = rect.midY
        
        // Calculate draw rect (centered)
        let drawRect = NSRect(
            x: centerX - symbolSize.width / 2,
            y: centerY - symbolSize.height / 2,
            width: symbolSize.width,
            height: symbolSize.height
        )
        
        context.saveGState()
        
        // Apply transforms around center
        context.translateBy(x: centerX, y: centerY)
        context.rotate(by: rotation * .pi / 180)
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -centerX, y: -centerY)
        
        if colorAmount > 0 {
            // Detect menu bar appearance - check if we're in dark mode
            let menuBarColor = menuBarIconColor()
            
            // Draw grayscale version first (matching menu bar appearance)
            if colorAmount < 1.0 {
                let grayColor = menuBarColor.withAlphaComponent(1.0 - colorAmount)
                drawTintedSymbol(symbolImage, in: drawRect, tint: grayColor)
            }
            
            // Draw green version on top
            let greenColor = NSColor(calibratedRed: 0.3, green: 0.75, blue: 0.4, alpha: colorAmount)
            drawTintedSymbol(symbolImage, in: drawRect, tint: greenColor)
        } else {
            // Fully grayscale - draw in menu bar color (template mode will override anyway)
            drawTintedSymbol(symbolImage, in: drawRect, tint: menuBarIconColor())
        }
        
        context.restoreGState()
    }
    
    private func menuBarIconColor() -> NSColor {
        // Check the effective appearance of the status bar button
        if let button = statusItem?.button {
            let appearance = button.effectiveAppearance
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? .white : .black
        }
        // Fallback: check system appearance
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return isDark ? .white : .black
    }
    
    private func drawTintedSymbol(_ symbol: NSImage, in rect: NSRect, tint: NSColor) {
        // Draw symbol and apply tint using compositing
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Draw the symbol
        symbol.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
        
        // Apply tint color using sourceAtop blend mode
        context.saveGState()
        context.setBlendMode(.sourceAtop)
        tint.setFill()
        context.fill(rect.insetBy(dx: -5, dy: -5)) // Slightly larger to catch edges
        context.restoreGState()
    }
    
    // MARK: - Actions
    
    @objc private func doneClicked() {
        appState.markDone()
        update()
    }
    
    @objc private func togglePrimed() {
        appState.togglePrimed()
        update()
    }
    
    @objc private func openSettings() {
        settingsWindowController.showSettings()
    }
    
    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        let url = URL(string: "https://nevyn.dev/breathebar")!
        let credits = NSMutableAttributedString(string: "Read more: ")
        credits.append(NSAttributedString(string: "nevyn.dev/breathebar", attributes: [
            .link: url,
            .foregroundColor: NSColor.linkColor,
        ]))
        NSApp.orderFrontStandardAboutPanel(options: [
            NSApplication.AboutPanelOptionKey.credits: credits,
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2026 Nevyn Bengtsson, hello@nevyn.dev",
        ])
    }
    
    @objc private func testAnimation() {
        appState.isBreathingTime.toggle()
        update()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
