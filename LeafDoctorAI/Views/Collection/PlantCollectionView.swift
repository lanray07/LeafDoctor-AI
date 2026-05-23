import SwiftData
import SwiftUI
import UIKit

struct PlantCollectionView: View {
    @Query(sort: \PlantProfile.createdAt, order: .reverse) private var plants: [PlantProfile]
    @Query(sort: \PlantScan.createdAt, order: .reverse) private var scans: [PlantScan]
    @State private var showingEditor = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if plants.isEmpty {
                    EmptyStateView(
                        systemImage: "leaf",
                        title: "Your collection is empty",
                        message: "Add plant profiles to track watering, diagnosis history, and recovery reports."
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(plants) { plant in
                        NavigationLink {
                            PlantDetailView(plant: plant)
                        } label: {
                            PlantCard(plant: plant, latestScan: scans.first(where: { $0.plantId == plant.id }))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(.leafMint.opacity(0.12))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    AIAssistantView()
                } label: {
                    Image(systemName: "sparkles")
                }
                .accessibilityLabel("AI Plant Care Assistant")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add plant")
            }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                PlantEditorView()
            }
        }
    }
}

struct PlantEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    var plant: PlantProfile?

    @State private var plantName: String
    @State private var nickname: String
    @State private var species: String
    @State private var location: String
    @State private var indoorOutdoor: PlantEnvironment
    @State private var wateringFrequency: String
    @State private var sunlightNeeds: String
    @State private var fertilizerSchedule: String
    @State private var notes: String
    @State private var createDefaultSchedule = true

    init(plant: PlantProfile? = nil) {
        self.plant = plant
        _plantName = State(initialValue: plant?.plantName ?? "")
        _nickname = State(initialValue: plant?.nickname ?? "")
        _species = State(initialValue: plant?.species ?? "")
        _location = State(initialValue: plant?.location ?? "")
        _indoorOutdoor = State(initialValue: PlantEnvironment(rawValue: plant?.indoorOutdoor ?? "") ?? .indoor)
        _wateringFrequency = State(initialValue: plant?.wateringFrequency ?? "Every 7 days")
        _sunlightNeeds = State(initialValue: plant?.sunlightNeeds ?? "Bright indirect light")
        _fertilizerSchedule = State(initialValue: plant?.fertilizerSchedule ?? "Monthly during growing season")
        _notes = State(initialValue: plant?.notes ?? "")
    }

    var body: some View {
        Form {
            Section("Plant profile") {
                TextField("Plant name", text: $plantName)
                TextField("Nickname", text: $nickname)
                TextField("Species", text: $species)
                TextField("Location", text: $location)
                Picker("Indoor/outdoor", selection: $indoorOutdoor) {
                    ForEach(PlantEnvironment.allCases) { environment in
                        Text(environment.rawValue).tag(environment)
                    }
                }
            }

            Section("Care needs") {
                TextField("Watering frequency", text: $wateringFrequency)
                TextField("Sunlight needs", text: $sunlightNeeds)
                TextField("Fertiliser schedule", text: $fertilizerSchedule)
                if plant == nil {
                    Toggle("Create starter care schedule", isOn: $createDefaultSchedule)
                }
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 110)
            }
        }
        .navigationTitle(plant == nil ? "Add Plant" : "Edit Plant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(plantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func save() {
        if let plant {
            plant.plantName = plantName
            plant.nickname = nickname
            plant.species = species
            plant.location = location
            plant.indoorOutdoor = indoorOutdoor.rawValue
            plant.wateringFrequency = wateringFrequency
            plant.sunlightNeeds = sunlightNeeds
            plant.fertilizerSchedule = fertilizerSchedule
            plant.notes = notes
        } else {
            let newPlant = PlantProfile(
                plantName: plantName,
                nickname: nickname,
                species: species,
                location: location,
                indoorOutdoor: indoorOutdoor.rawValue,
                wateringFrequency: wateringFrequency,
                sunlightNeeds: sunlightNeeds,
                fertilizerSchedule: fertilizerSchedule,
                notes: notes
            )
            modelContext.insert(newPlant)
            if createDefaultSchedule {
                addStarterSchedule(for: newPlant)
            }
        }
        dismiss()
    }

    private func addStarterSchedule(for plant: PlantProfile) {
        let drafts = [
            CareTask(
                plantId: plant.id,
                taskType: CareTaskType.watering.rawValue,
                dueDate: .now.addingTimeInterval(86_400),
                repeatIntervalDays: 7,
                notes: "Check soil moisture before watering."
            ),
            CareTask(
                plantId: plant.id,
                taskType: CareTaskType.pestCheck.rawValue,
                dueDate: .now.addingTimeInterval(259_200),
                repeatIntervalDays: 14,
                notes: "Inspect leaves, stems, and soil surface."
            )
        ]
        drafts.forEach { task in
            modelContext.insert(task)
        }
    }
}

struct PlantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let plant: PlantProfile
    @Query private var scans: [PlantScan]
    @Query private var tasks: [CareTask]
    @Query private var photos: [PlantPhoto]
    @State private var showingEditor = false
    @State private var reportURL: URL?
    @State private var reportError: String?

    init(plant: PlantProfile) {
        self.plant = plant
        let plantID = plant.id
        _scans = Query(filter: #Predicate<PlantScan> { scan in
            scan.plantId == plantID
        }, sort: \PlantScan.createdAt, order: .reverse)
        _tasks = Query(filter: #Predicate<CareTask> { task in
            task.plantId == plantID
        }, sort: \CareTask.dueDate, order: .forward)
        _photos = Query(filter: #Predicate<PlantPhoto> { photo in
            photo.plantId == plantID
        }, sort: \PlantPhoto.createdAt, order: .reverse)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                profileHeader
                photoStrip
                careSummary
                latestDiagnosis
                TreatmentPlanCard(
                    title: "Current care basics",
                    steps: [
                        "Watering: \(plant.wateringFrequency)",
                        "Sunlight: \(plant.sunlightNeeds)",
                        "Fertiliser: \(plant.fertilizerSchedule)"
                    ]
                )
                timelineSection

                if let reportError {
                    Text(reportError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .background(.leafMint.opacity(0.12))
        .navigationTitle(plant.nickname.isEmpty ? plant.plantName : plant.nickname)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    createReport()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Export PDF report")

                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel("Edit plant")
            }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                PlantEditorView(plant: plant)
            }
        }
        .sheet(item: $reportURL) { url in
            ShareSheet(items: [url])
        }
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(plant.plantName)
                        .font(.largeTitle.weight(.bold))
                    Text(plant.species.isEmpty ? "Species not specified" : plant.species)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HealthStatusBadge(severity: scans.first?.severityValue ?? .healthy)
            }
            Label(plant.location.isEmpty ? plant.indoorOutdoor : "\(plant.location) - \(plant.indoorOutdoor)", systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !plant.notes.isEmpty {
                Text(plant.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var photoStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.headline)
            if photos.isEmpty {
                EmptyStateView(systemImage: "photo", title: "No photos yet", message: "Scan this plant to save progress photos.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(photos.prefix(10)) { photo in
                            if let data = photo.imageData, let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 128, height: 128)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(alignment: .bottomLeading) {
                                        Text(photo.category)
                                            .font(.caption2.weight(.semibold))
                                            .padding(6)
                                            .background(.ultraThinMaterial, in: Capsule())
                                            .padding(6)
                                    }
                            }
                        }
                    }
                }
            }
        }
    }

    private var careSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming care")
                .font(.headline)
            let upcoming = tasks.filter { !$0.completed }.prefix(3)
            if upcoming.isEmpty {
                EmptyStateView(systemImage: "calendar", title: "No upcoming tasks", message: "Add reminders from the Care tab.")
            } else {
                ForEach(Array(upcoming)) { task in
                    HStack {
                        Label(task.taskType, systemImage: task.taskTypeValue.systemImage)
                        Spacer()
                        Text(task.dueDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private var latestDiagnosis: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest diagnosis")
                .font(.headline)
            if let scan = scans.first {
                PlantScanCard(scan: scan)
            } else {
                EmptyStateView(systemImage: "stethoscope", title: "No diagnosis yet", message: "Scan this plant to create a health baseline.")
            }
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Health timeline")
                    .font(.headline)
                Spacer()
                NavigationLink("Open") {
                    PlantHealthTimelineView(initialPlantID: plant.id)
                }
                .font(.subheadline)
            }
            CareTimelineView(scans: scans, tasks: tasks)
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func createReport() {
        do {
            reportURL = try PDFReportGenerator.makeCareReport(
                plant: plant,
                scans: scans,
                tasks: tasks,
                photos: photos
            )
        } catch {
            reportError = error.localizedDescription
        }
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}
