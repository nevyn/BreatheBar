import Foundation
import SwiftUI
import ServiceManagement

@Observable
@MainActor
final class AppState {
    var isBreathingTime: Bool = false
    var isPrimed: Bool = true
    var settings: BreathingSettings {
        didSet {
            settings.save()
            updateLaunchAtLogin()
        }
    }
    
    private var timer: Timer?
    
    init() {
        self.settings = BreathingSettings.load()
        startScheduler()
        updateLaunchAtLogin()
    }
    
    func cleanup() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Actions
    
    func markDone() {
        isBreathingTime = false
        isPrimed = true
    }
    
    func togglePrimed() {
        isPrimed.toggle()
        if !isPrimed {
            isBreathingTime = false
        }
    }
    
    // MARK: - Scheduler
    
    private func startScheduler() {
        // Check immediately
        checkBreathingTime()
        
        // Then check every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkBreathingTime()
            }
        }
    }
    
    private func checkBreathingTime() {
        let now = Date()
        
        // If we're not primed, don't trigger
        guard isPrimed else {
            return
        }
        
        // Check if it's breathing time based on settings
        let shouldBeBreathingTime = settings.isBreathingTime(date: now)
        
        if shouldBeBreathingTime && !isBreathingTime {
            // Entering breathing time
            isBreathingTime = true
            isPrimed = false  // Will be re-primed when user clicks "Done"
        } else if !shouldBeBreathingTime && isBreathingTime {
            // If we passed the hour and user didn't acknowledge, auto-reset
            // This handles the case where user ignores the reminder
            isBreathingTime = false
            isPrimed = true
        }
    }
    
    // MARK: - Launch at Login
    
    private func updateLaunchAtLogin() {
        do {
            if settings.launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently fail - user can retry in settings
            print("Failed to update launch at login: \(error)")
        }
    }
}
