import Foundation

struct BreathingSettings: Codable, Equatable {
    var startHour: Int = 8
    var startMinute: Int = 0
    var endHour: Int = 17
    var endMinute: Int = 0
    var workDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    var launchAtLogin: Bool = false
    
    enum Weekday: Int, Codable, CaseIterable, Identifiable {
        case monday = 1
        case tuesday = 2
        case wednesday = 3
        case thursday = 4
        case friday = 5
        case saturday = 6
        case sunday = 7
        
        var id: Int { rawValue }
        
        var shortName: String {
            switch self {
            case .monday: "Mon"
            case .tuesday: "Tue"
            case .wednesday: "Wed"
            case .thursday: "Thu"
            case .friday: "Fri"
            case .saturday: "Sat"
            case .sunday: "Sun"
            }
        }
        
        var fullName: String {
            switch self {
            case .sunday: "Sunday"
            case .monday: "Monday"
            case .tuesday: "Tuesday"
            case .wednesday: "Wednesday"
            case .thursday: "Thursday"
            case .friday: "Friday"
            case .saturday: "Saturday"
            }
        }
    }
    
    func isWithinWorkHours(date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .weekday], from: date)
        
        guard let hour = components.hour,
              let minute = components.minute,
              let weekdayValue = components.weekday,
              let weekday = Weekday(rawValue: weekdayValue) else {
            return false
        }
        
        // Check if it's a work day
        guard workDays.contains(weekday) else {
            return false
        }
        
        // Convert to minutes since midnight for easier comparison
        let currentMinutes = hour * 60 + minute
        let startMinutes = startHour * 60 + self.startMinute
        let endMinutes = endHour * 60 + self.endMinute
        
        return currentMinutes >= startMinutes && currentMinutes < endMinutes
    }
    
    func isBreathingTime(date: Date = Date()) -> Bool {
        guard isWithinWorkHours(date: date) else {
            return false
        }
        
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        
        // Trigger at 55-59 minutes (5 minutes before the hour)
        return minute >= 55
    }
}

// MARK: - UserDefaults Storage

extension BreathingSettings {
    private static let storageKey = "breathingSettings"
    
    static func load() -> BreathingSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(BreathingSettings.self, from: data) else {
            return BreathingSettings()
        }
        return settings
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
