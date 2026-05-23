import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    preferences
                    DisclaimerBox()
                    notificationPrompt

                    Button {
                        Task {
                            await viewModel.requestNotificationsIfNeeded()
                            hasCompletedOnboarding = true
                        }
                    } label: {
                        Label("Start caring for plants", systemImage: "leaf.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
            }
            .background(.leafMint.opacity(0.18))
            .navigationTitle("LeafDoctor AI")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [.leafDeep, .leafTeal], startPoint: .topLeading, endPoint: .bottomTrailing))
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "camera.macro")
                        .font(.system(size: 42))
                        .foregroundStyle(.white)
                    Text("Plant diagnosis and care routines in one calm place.")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Scan leaves, track watering, monitor recovery, and build better care habits with mock AI enabled by default.")
                        .foregroundStyle(.white.opacity(0.82))
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 310)
        }
    }

    private var preferences: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personalise guidance")
                .font(.title2.weight(.bold))

            Picker("Experience level", selection: $viewModel.experienceLevel) {
                ForEach(ExperienceLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }

            Picker("Primary plant type", selection: $viewModel.plantEnvironment) {
                ForEach(PlantEnvironment.allCases) { environment in
                    Text(environment.rawValue).tag(environment)
                }
            }

            Picker("Reminder style", selection: $viewModel.reminderPreference) {
                ForEach(ReminderPreference.allCases) { preference in
                    Text(preference.rawValue).tag(preference)
                }
            }
        }
        .pickerStyle(.navigationLink)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var notificationPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $viewModel.wantsNotifications) {
                Label("Watering and care reminders", systemImage: "bell.badge.fill")
            }

            Text("You can change notification and reminder preferences later in Settings.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let notificationError = viewModel.notificationError {
                Text(notificationError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
