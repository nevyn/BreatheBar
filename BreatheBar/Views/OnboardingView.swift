import SwiftUI

struct OnboardingView: View {
    @Bindable var appState: AppState
    /// Called when the user clicks "Get Started" or closes the window.
    let onComplete: () -> Void

    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch page {
                case 0: welcomePage
                default: settingsPage
                }
            }
            .transition(.push(from: .trailing))
            .animation(.easeInOut(duration: 0.3), value: page)

            Divider()

            // MARK: - Footer
            HStack {
                if page > 0 {
                    Button("Back") { page -= 1 }
                }
                Spacer()
                if page == 0 {
                    Button("Next") { page = 1 }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Get Started") {
                        Task {
                            await appState.requestHealthKitAuthorizationIfNeeded()
                            onComplete()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 440)
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text("Welcome to BreatheBar")
                .font(.largeTitle.bold())

            Text("A quiet companion that sits in your menu bar and pulses once an hour to remind you to breathe. No notifications, no interruptions — just a subtle nudge when you're ready.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Page 2: Settings

    private var settingsPage: some View {
        SettingsView(appState: appState)
    }
}

#Preview {
    OnboardingView(appState: AppState()) {}
}
