import SwiftData
import SwiftUI

@main
struct LeafDoctorAIApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager()
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: PlantProfile.self,
                PlantPhoto.self,
                PlantScan.self,
                CareTask.self,
                Achievement.self,
                SubscriptionState.self
            )
        } catch {
            fatalError("Could not create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .modelContainer(modelContainer)
                .environmentObject(subscriptionManager)
                .tint(.leafPrimary)
                .task {
                    await subscriptionManager.loadProducts()
                }
        }
    }
}
