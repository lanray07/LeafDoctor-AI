import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Query private var plants: [PlantProfile]
    @Query private var scans: [PlantScan]
    @Query private var tasks: [CareTask]
    @Query private var photos: [PlantPhoto]
    @Query private var achievements: [Achievement]
    @Query private var subscriptionStates: [SubscriptionState]
    @AppStorage("preferredUnits") private var preferredUnits = "Metric"
    @AppStorage("settingsReminderPreference") private var reminderPreference = ReminderPreference.balanced.rawValue
    @State private var showingPaywall = false
    @State private var showingDeleteConfirmation = false
    @State private var exportedURL: URL?
    @State private var message: String?

    var body: some View {
        Form {
            Section("Subscription") {
                HStack {
                    Label(subscriptionManager.statusText, systemImage: "sparkles")
                    Spacer()
                    Button("Manage") {
                        showingPaywall = true
                    }
                }
                Button("Restore purchases") {
                    Task { await subscriptionManager.restorePurchases() }
                }
            }

            Section("Notifications") {
                Picker("Reminder preference", selection: $reminderPreference) {
                    ForEach(ReminderPreference.allCases) { preference in
                        Text(preference.rawValue).tag(preference.rawValue)
                    }
                }

                Button("Request notification permission") {
                    Task {
                        do {
                            let allowed = try await NotificationService.shared.requestAuthorization()
                            message = allowed ? "Notifications enabled." : "Notifications were not enabled."
                        } catch {
                            message = error.localizedDescription
                        }
                    }
                }
            }

            Section("Units and data") {
                Picker("Units", selection: $preferredUnits) {
                    Text("Metric").tag("Metric")
                    Text("Imperial").tag("Imperial")
                }
                Button("Export data") {
                    exportData()
                }
                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Legal and safety") {
                NavigationLink("Privacy policy") {
                    LegalTextView(title: "Privacy policy", text: privacyText)
                }
                NavigationLink("Terms of use") {
                    LegalTextView(title: "Terms of use", text: termsText)
                }
                NavigationLink("AI disclaimer") {
                    LegalTextView(title: "AI disclaimer", text: disclaimerText)
                }
            }

            Section("Danger zone") {
                Button("Delete all data", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(item: $exportedURL) { url in
            ShareSheet(items: [url])
        }
        .confirmationDialog("Delete all local data?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete all data", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes local plants, photos, scans, reminders, achievements, and subscription state records stored by the app.")
        }
    }

    private func exportData() {
        do {
            let payload = ExportPayload(
                exportedAt: .now,
                plants: plants.map {
                    ExportPlant(
                        id: $0.id,
                        plantName: $0.plantName,
                        nickname: $0.nickname,
                        species: $0.species,
                        location: $0.location,
                        indoorOutdoor: $0.indoorOutdoor,
                        wateringFrequency: $0.wateringFrequency,
                        sunlightNeeds: $0.sunlightNeeds,
                        fertilizerSchedule: $0.fertilizerSchedule,
                        notes: $0.notes,
                        createdAt: $0.createdAt
                    )
                },
                scans: scans.map {
                    ExportScan(
                        id: $0.id,
                        plantId: $0.plantId,
                        diseaseName: $0.diseaseName,
                        diseaseCategory: $0.diseaseCategory,
                        severity: $0.severity,
                        confidence: $0.confidence,
                        symptoms: $0.symptoms,
                        treatmentSuggestions: $0.treatmentSuggestions,
                        wateringAdvice: $0.wateringAdvice,
                        sunlightAdvice: $0.sunlightAdvice,
                        createdAt: $0.createdAt
                    )
                },
                tasks: tasks.map {
                    ExportTask(
                        id: $0.id,
                        plantId: $0.plantId,
                        taskType: $0.taskType,
                        dueDate: $0.dueDate,
                        completed: $0.completed,
                        notes: $0.notes
                    )
                }
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(payload)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("LeafDoctorAI-Export.json")
            try data.write(to: url, options: [.atomic])
            exportedURL = url
        } catch {
            message = error.localizedDescription
        }
    }

    private func deleteAllData() {
        plants.forEach { modelContext.delete($0) }
        scans.forEach { modelContext.delete($0) }
        tasks.forEach { modelContext.delete($0) }
        photos.forEach { modelContext.delete($0) }
        achievements.forEach { modelContext.delete($0) }
        subscriptionStates.forEach { modelContext.delete($0) }
        message = "All local app data was deleted."
    }

    private var privacyText: String {
        """
        LeafDoctor AI stores plant profiles, photos, scan history, care reminders, achievements, and settings locally using SwiftData.

        Mock AI mode is enabled by default. Remote AI requests should be sent only through your secure backend endpoint. Never store API keys inside the iOS app.

        Camera and photo access are used only when you choose to scan or save plant photos.
        """
    }

    private var termsText: String {
        """
        LeafDoctor AI is a plant care assistant and does not provide guaranteed botanical, agricultural, medical, legal, or commercial advice.

        Subscriptions are scaffolded with StoreKit 2 placeholders. Configure product identifiers, pricing, terms, and entitlement handling in App Store Connect before release.
        """
    }

    private var disclaimerText: String {
        """
        AI results are informational only.

        Results are not guaranteed botanical diagnosis. Treatment outcomes may vary. Severe infestations, toxic exposure concerns, crop losses, or valuable greenhouse issues should be reviewed by qualified professionals.
        """
    }

    private struct ExportPayload: Encodable {
        var exportedAt: Date
        var plants: [ExportPlant]
        var scans: [ExportScan]
        var tasks: [ExportTask]
    }

    private struct ExportPlant: Encodable {
        var id: UUID
        var plantName: String
        var nickname: String
        var species: String
        var location: String
        var indoorOutdoor: String
        var wateringFrequency: String
        var sunlightNeeds: String
        var fertilizerSchedule: String
        var notes: String
        var createdAt: Date
    }

    private struct ExportScan: Encodable {
        var id: UUID
        var plantId: UUID
        var diseaseName: String
        var diseaseCategory: String
        var severity: String
        var confidence: Double
        var symptoms: [String]
        var treatmentSuggestions: [String]
        var wateringAdvice: String
        var sunlightAdvice: String
        var createdAt: Date
    }

    private struct ExportTask: Encodable {
        var id: UUID
        var plantId: UUID
        var taskType: String
        var dueDate: Date
        var completed: Bool
        var notes: String
    }
}

private struct LegalTextView: View {
    let title: String
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(title)
    }
}
