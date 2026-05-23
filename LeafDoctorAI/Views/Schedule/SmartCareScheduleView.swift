import SwiftData
import SwiftUI

struct SmartCareScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CareTask.dueDate, order: .forward) private var tasks: [CareTask]
    @Query(sort: \PlantProfile.createdAt, order: .reverse) private var plants: [PlantProfile]
    @State private var showingEditor = false
    @State private var notificationMessage: String?

    private var dueTasks: [CareTask] {
        tasks.filter { !$0.completed }
    }

    private var completedTasks: [CareTask] {
        tasks.filter(\.completed).sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                dueSection
                historySection
            }
            .padding()
        }
        .background(.leafMint.opacity(0.12))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add care reminder")
            }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                CareTaskEditorView()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart care schedule")
                .font(.largeTitle.weight(.bold))
            Text("Track watering, fertilising, pruning, repotting, misting, and pest checks with local reminders.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                MetricPill(title: "Open tasks", value: "\(dueTasks.count)", icon: "calendar")
                MetricPill(title: "Completed", value: "\(completedTasks.count)", icon: "checkmark.circle.fill")
            }

            if let notificationMessage {
                Text(notificationMessage)
                    .font(.footnote)
                    .foregroundStyle(.leafPrimary)
            }
        }
    }

    private var dueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming reminders")
                .font(.headline)

            if plants.isEmpty {
                EmptyStateView(systemImage: "leaf", title: "Add a plant first", message: "Care tasks need a plant profile so reminders can be attached to the right routine.")
            } else if dueTasks.isEmpty {
                EmptyStateView(systemImage: "calendar.badge.plus", title: "No open reminders", message: "Create a custom schedule for watering, fertilising, pruning, repotting, misting, or pest checks.")
            } else {
                ForEach(dueTasks) { task in
                    WateringReminderCard(
                        task: task,
                        plantName: plantName(for: task.plantId),
                        onComplete: { complete(task) },
                        onSnooze: { snooze(task) }
                    )
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Care history")
                .font(.headline)

            if completedTasks.isEmpty {
                EmptyStateView(systemImage: "checklist", title: "No completed care yet", message: "Completed reminders will build your plant care timeline.")
            } else {
                ForEach(completedTasks.prefix(12)) { task in
                    HStack {
                        Image(systemName: task.taskTypeValue.systemImage)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.leafTeal, in: Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(task.taskType) - \(plantName(for: task.plantId))")
                                .font(.subheadline.weight(.semibold))
                            Text((task.completedAt ?? task.dueDate).formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private func plantName(for id: UUID) -> String {
        plants.first(where: { $0.id == id })?.plantName ?? "Plant"
    }

    private func complete(_ task: CareTask) {
        task.completed = true
        task.completedAt = .now

        if task.repeatIntervalDays > 0,
           let nextDate = Calendar.current.date(byAdding: .day, value: task.repeatIntervalDays, to: task.dueDate) {
            let nextTask = CareTask(
                plantId: task.plantId,
                taskType: task.taskType,
                dueDate: nextDate,
                repeatIntervalDays: task.repeatIntervalDays,
                notes: task.notes
            )
            modelContext.insert(nextTask)
            Task {
                try? await NotificationService.shared.scheduleReminder(for: nextTask, plantName: plantName(for: nextTask.plantId))
            }
        }
    }

    private func snooze(_ task: CareTask) {
        task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: task.dueDate) ?? task.dueDate
        Task {
            do {
                try await NotificationService.shared.scheduleReminder(for: task, plantName: plantName(for: task.plantId))
                notificationMessage = "Snoozed \(task.taskType.lowercased()) for \(plantName(for: task.plantId))."
            } catch {
                notificationMessage = error.localizedDescription
            }
        }
    }
}

struct CareTaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlantProfile.createdAt, order: .reverse) private var plants: [PlantProfile]
    @State private var selectedPlantID: UUID?
    @State private var taskType: CareTaskType = .watering
    @State private var dueDate = Date.now.addingTimeInterval(3600)
    @State private var repeats = true
    @State private var repeatIntervalDays = 7
    @State private var notes = ""
    @State private var enableNotification = true
    @State private var errorMessage: String?

    var body: some View {
        Form {
            if plants.isEmpty {
                Section {
                    EmptyStateView(systemImage: "leaf", title: "No plants", message: "Add a plant before creating a care reminder.")
                }
            } else {
                Section("Reminder") {
                    Picker("Plant", selection: $selectedPlantID) {
                        ForEach(plants) { plant in
                            Text(plant.nickname.isEmpty ? plant.plantName : plant.nickname).tag(Optional(plant.id))
                        }
                    }
                    Picker("Task type", selection: $taskType) {
                        ForEach(CareTaskType.allCases) { type in
                            Label(type.rawValue, systemImage: type.systemImage).tag(type)
                        }
                    }
                    DatePicker("Due", selection: $dueDate)
                }

                Section("Recurring schedule") {
                    Toggle("Repeat reminder", isOn: $repeats)
                    if repeats {
                        Stepper("Every \(repeatIntervalDays) day\(repeatIntervalDays == 1 ? "" : "s")", value: $repeatIntervalDays, in: 1...90)
                    }
                    Toggle("Schedule local notification", isOn: $enableNotification)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 90)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Care Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedPlantID = selectedPlantID ?? plants.first?.id
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(selectedPlantID == nil)
            }
        }
    }

    private func save() async {
        guard let selectedPlantID, let plant = plants.first(where: { $0.id == selectedPlantID }) else { return }

        let task = CareTask(
            plantId: selectedPlantID,
            taskType: taskType.rawValue,
            dueDate: dueDate,
            repeatIntervalDays: repeats ? repeatIntervalDays : 0,
            notes: notes
        )
        modelContext.insert(task)

        if enableNotification {
            do {
                _ = try await NotificationService.shared.requestAuthorization()
                try await NotificationService.shared.scheduleReminder(for: task, plantName: plant.plantName)
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }

        dismiss()
    }
}
