import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Bindable var appState: AppState
    
    var body: some View {
        Form {
            Section("Work Days") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 8) {
                    ForEach(BreathingSettings.Weekday.allCases) { day in
                        Toggle(day.shortName, isOn: Binding(
                            get: { appState.settings.workDays.contains(day) },
                            set: { isOn in
                                if isOn {
                                    appState.settings.workDays.insert(day)
                                } else {
                                    appState.settings.workDays.remove(day)
                                }
                            }
                        ))
                        .toggleStyle(.button)
                    }
                }
            }
            
            Section("Work Hours") {
                HStack {
                    Text("Start")
                    Spacer()
                    TimePicker(hour: $appState.settings.startHour, minute: $appState.settings.startMinute)
                }
                
                HStack {
                    Text("End")
                    Spacer()
                    TimePicker(hour: $appState.settings.endHour, minute: $appState.settings.endMinute)
                }
            }
            

            
            Section("Startup") {
                Toggle("Launch at Login", isOn: $appState.settings.launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .navigationTitle("BreatheBar Settings")
    }
}

// MARK: - Time Picker

struct TimePicker: View {
    @Binding var hour: Int
    @Binding var minute: Int
    
    var body: some View {
        HStack(spacing: 2) {
            Picker("", selection: $hour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                }
            }
            .labelsHidden()
            .frame(width: 60)
            
            Text(":")
            
            Picker("", selection: $minute) {
                ForEach([0, 15, 30, 45], id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
            .labelsHidden()
            .frame(width: 60)
        }
    }
}

#Preview {
    SettingsView(appState: AppState())
}
