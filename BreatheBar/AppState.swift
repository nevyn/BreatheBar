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
        // isPrimed stays false -- the scheduler will re-prime
        // when the breathing window passes (:00), preventing
        // re-triggers within the same 5-minute period.
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
        let shouldBeBreathingTime = settings.isBreathingTime(date: now)
        
        if isPrimed && shouldBeBreathingTime && !isBreathingTime {
            // Enter breathing time
            isBreathingTime = true
            isPrimed = false
        } else if !isPrimed && !shouldBeBreathingTime {
            // Breathing window has passed -- re-prime for next hour.
            // Also auto-resets if user ignored the reminder (isBreathingTime
            // was still true when the window elapsed).
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
