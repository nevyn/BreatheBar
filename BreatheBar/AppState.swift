import Foundation
import SwiftUI
import ServiceManagement

@Observable
@MainActor
final class AppState {
    /// Is it currently time for the user to take a breathing break?
    var isBreathingTime: Bool = false
    /// Whether we have already breathed this hour. Don't reactivate if the user does their breathing break before the hour has ended.
    var breathingTimeTriggeredThisHour: Bool = false
    
    /// Is the user interested in getting breathing reminders?
    var isPrimed: Bool = true
    /// Have we already auto-(un)-primed based on schedule this day? Then don't override user's settings
    var hasAutoPrimedDay: Int? = nil
    var hasAutoUnprimedDay: Int? = nil
    
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
        print("Done breathing.")
        isBreathingTime = false
    }
    
    func togglePrimed() {
        isPrimed.toggle()
        if !isPrimed {
            print("Unpriming...")
            isBreathingTime = false
            hasAutoPrimedDay = Calendar.current.component(.day, from: Date())
        } else {
            print("Priming...")
            hasAutoUnprimedDay = Calendar.current.component(.day, from: Date())
        }
    }
    
    // MARK: - Scheduler
    
    private func startScheduler() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.checkPrimedWithinWorkingHours()
                // Only check for breathing time if we're active
                if self.isPrimed {
                    self.checkBreathingTime()
                }
            }
        }
    }
    
    private func checkPrimedWithinWorkingHours()
    {
        let now = Date()
        let day = Calendar.current.component(.day, from: now)
        let withinWorkingHours = settings.isWithinWorkHours(date: now)
        if !withinWorkingHours && isPrimed && hasAutoUnprimedDay != day {
            print("Workday ended. Unpriming.")
            isPrimed = false
            hasAutoUnprimedDay = day
        } else if withinWorkingHours && !isPrimed && hasAutoPrimedDay != day {
            print("Workday started. Priming.")
            isPrimed = true
            hasAutoPrimedDay = day
        }
    }
    
    private func checkBreathingTime() {
        let now = Date()
        let shouldBeBreathingTime = settings.isBreathingTime(date: now)
        if shouldBeBreathingTime && !isBreathingTime && !breathingTimeTriggeredThisHour {
            print("Time to breathe!")
            isBreathingTime = true
            breathingTimeTriggeredThisHour = true
        } else if breathingTimeTriggeredThisHour && !shouldBeBreathingTime {
            print("Getting ready to remind about breathing again.")
            // Breathing window has passed -- re-prime for next hour.
            breathingTimeTriggeredThisHour = false
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
