import SwiftUI

struct OnboardingView: View {
    @Bindable var appState: AppState
    /// Called when the user clicks "Get Started" or closes the window.
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Header
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to BreatheBar")
                        .font(.title2.bold())
                    Text("BreatheBar sits quietly in your menu bar and pulses its icon once an hour to remind you to take a short breathing break. No notifications, no interruptions — just a subtle nudge when you're ready.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()

            // MARK: - Setup form (reuses SettingsView's TimePicker)
            Form {
                Section("Work Days") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 8) {
                        ForEach(BreathingSettings.Weekday.allCases) { day in
                            Toggle(day.shortName, isOn: Binding(
                                get: { appState.settings.workDays.contains(day) },
                                set: { isOn in
                                    if isOn { appState.settings.workDays.insert(day) }
                                    else { appState.settings.workDays.remove(day) }
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
                        TimePicker(hour: $appState.settings.startHour,
                                   minute: $appState.settings.startMinute)
                    }
                    HStack {
                        Text("End")
                        Spacer()
                        TimePicker(hour: $appState.settings.endHour,
                                   minute: $appState.settings.endMinute)
                    }
                }

                Section("Options") {
                    Toggle("Launch at Login", isOn: $appState.settings.launchAtLogin)

                    Toggle("Log to Apple Health", isOn: $appState.settings.logToHealth)
                        .help("Sessions over 60 seconds are logged as Mindfulness to Apple Health.")
                }
            }
            .formStyle(.grouped)

            Divider()

            // MARK: - Footer
            HStack {
                Spacer()
                Button("Get Started") {
                    Task {
                        // Request HealthKit auth if needed, then mark onboarding complete.
                        // The system sheet floats over this window automatically.
                        await appState.requestHealthKitAuthorizationIfNeeded()
                        onComplete()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.trailing, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 440)
    }
}

#Preview {
    OnboardingView(appState: AppState()) {}
}
