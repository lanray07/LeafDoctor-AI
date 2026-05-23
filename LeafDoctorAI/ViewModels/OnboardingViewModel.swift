import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var experienceLevel: ExperienceLevel = .beginner
    @Published var plantEnvironment: PlantEnvironment = .indoor
    @Published var reminderPreference: ReminderPreference = .balanced
    @Published var wantsNotifications = true
    @Published var notificationError: String?

    func requestNotificationsIfNeeded() async {
        guard wantsNotifications else { return }

        do {
            _ = try await NotificationService.shared.requestAuthorization()
        } catch {
            notificationError = error.localizedDescription
        }
    }
}
