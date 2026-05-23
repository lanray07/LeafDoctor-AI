import SwiftData
import SwiftUI

struct DashboardView: View {
    @Binding var selectedTab: AppTab
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Query(sort: \PlantProfile.createdAt, order: .reverse) private var plants: [PlantProfile]
    @Query(sort: \PlantScan.createdAt, order: .reverse) private var scans: [PlantScan]
    @Query(sort: \CareTask.dueDate, order: .forward) private var tasks: [CareTask]
    @Query(sort: \Achievement.title, order: .forward) private var achievements: [Achievement]
    @State private var showingPaywall = false

    private var todayTasks: [CareTask] {
        tasks.filter { Calendar.current.isDateInToday($0.dueDate) && !$0.completed }
    }

    private var unhealthyPlants: [PlantProfile] {
        plants.filter { plant in
            guard let latest = scans.first(where: { $0.plantId == plant.id }) else { return false }
            return latest.severityValue != .healthy
        }
    }

    private var careStreak: Int {
        let completedDays = Set(tasks.compactMap { task -> Date? in
            guard let completedAt = task.completedAt else { return nil }
            return Calendar.current.startOfDay(for: completedAt)
        })
        var streak = 0
        var date = Calendar.current.startOfDay(for: .now)
        while completedDays.contains(date) {
            streak += 1
            guard let next = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = next
        }
        return streak
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                dashboardHeader
                quickActions
                remindersSection
                unhealthySection
                recentScansSection
                collectionSection
            }
            .padding()
        }
        .background(.leafMint.opacity(0.12))
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .task {
            seedAchievementsIfNeeded()
            updateAchievements()
        }
    }

    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.largeTitle.weight(.bold))
                    Text("A quick health check for your collection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(subscriptionManager.statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.leafPrimary)
                    Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                MetricPill(title: "Care streak", value: "\(careStreak)d", icon: "flame.fill")
                MetricPill(title: "Due today", value: "\(todayTasks.count)", icon: "drop.fill")
                MetricPill(title: "Plants", value: "\(plants.count)", icon: "leaf.fill")
            }

            UpgradeBanner {
                showingPaywall = true
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick actions")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
                Button {
                    selectedTab = .scanner
                } label: {
                    actionLabel("Scan Plant", icon: "camera.viewfinder")
                }
                NavigationLink {
                    PlantEditorView()
                } label: {
                    actionLabel("Add Plant", icon: "plus.circle.fill")
                }
                Button {
                    completeFirstWatering()
                } label: {
                    actionLabel("Watered Today", icon: "drop.circle.fill")
                }
                NavigationLink {
                    PlantHealthTimelineView()
                } label: {
                    actionLabel("Disease History", icon: "clock.arrow.circlepath")
                }
                Button {
                    selectedTab = .schedule
                } label: {
                    actionLabel("Care Schedule", icon: "calendar.badge.clock")
                }
                NavigationLink {
                    AIAssistantView()
                } label: {
                    actionLabel("AI Assistant", icon: "sparkles")
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func actionLabel(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.leafPrimary)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Spacer()
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's watering reminders")
                .font(.headline)

            if todayTasks.isEmpty {
                EmptyStateView(systemImage: "drop.circle", title: "No care due today", message: "Your next watering and care reminders will appear here.")
            } else {
                ForEach(todayTasks.prefix(3)) { task in
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

    private var unhealthySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unhealthy plants")
                .font(.headline)
            if unhealthyPlants.isEmpty {
                EmptyStateView(systemImage: "leaf.circle", title: "No urgent issues", message: "Plants with mild, moderate, or severe scan results will be highlighted here.")
            } else {
                ForEach(unhealthyPlants.prefix(3)) { plant in
                    NavigationLink {
                        PlantDetailView(plant: plant)
                    } label: {
                        PlantCard(plant: plant, latestScan: scans.first(where: { $0.plantId == plant.id }))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentScansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently scanned")
                .font(.headline)
            if scans.isEmpty {
                EmptyStateView(systemImage: "camera.metering.unknown", title: "No scans yet", message: "Use Scan Plant to create your first mock AI diagnosis.")
            } else {
                ForEach(scans.prefix(3)) { scan in
                    PlantScanCard(scan: scan)
                }
            }
        }
    }

    private var collectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Plant collection")
                    .font(.headline)
                Spacer()
                Button("View all") {
                    selectedTab = .collection
                }
                .font(.subheadline)
            }

            if plants.isEmpty {
                EmptyStateView(systemImage: "leaf", title: "Add your first plant", message: "Create a profile to unlock care schedules, scans, reports, and health history.")
            } else {
                ForEach(plants.prefix(4)) { plant in
                    NavigationLink {
                        PlantDetailView(plant: plant)
                    } label: {
                        PlantCard(plant: plant, latestScan: scans.first(where: { $0.plantId == plant.id }))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func plantName(for id: UUID) -> String {
        plants.first(where: { $0.id == id })?.plantName ?? "Plant"
    }

    private func completeFirstWatering() {
        if let task = todayTasks.first(where: { $0.taskTypeValue == .watering }) ?? todayTasks.first {
            complete(task)
        }
    }

    private func complete(_ task: CareTask) {
        task.completed = true
        task.completedAt = .now
        if task.repeatIntervalDays > 0,
           let nextDate = Calendar.current.date(byAdding: .day, value: task.repeatIntervalDays, to: task.dueDate) {
            modelContext.insert(CareTask(
                plantId: task.plantId,
                taskType: task.taskType,
                dueDate: nextDate,
                repeatIntervalDays: task.repeatIntervalDays,
                notes: task.notes
            ))
        }
        updateAchievements()
    }

    private func snooze(_ task: CareTask) {
        task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: task.dueDate) ?? task.dueDate
        Task {
            try? await NotificationService.shared.scheduleReminder(for: task, plantName: plantName(for: task.plantId))
        }
    }

    private func seedAchievementsIfNeeded() {
        guard achievements.isEmpty else { return }
        [
            ("First Plant", "Add a plant profile."),
            ("7-Day Care Streak", "Complete care for seven days in a row."),
            ("Plant Saver", "Improve a severe or moderate scan."),
            ("Watering Master", "Complete ten watering reminders."),
            ("Recovery Success", "Record treatment progress."),
            ("Plant Collector", "Track five plants.")
        ].forEach { title, description in
            modelContext.insert(Achievement(title: title, description: description))
        }
    }

    private func updateAchievements() {
        for achievement in achievements {
            let shouldUnlock: Bool
            switch achievement.title {
            case "First Plant":
                shouldUnlock = !plants.isEmpty
            case "7-Day Care Streak":
                shouldUnlock = careStreak >= 7
            case "Plant Saver":
                shouldUnlock = scans.contains { $0.severityValue == .moderate || $0.severityValue == .severe }
            case "Watering Master":
                shouldUnlock = tasks.filter { $0.completed && $0.taskTypeValue == .watering }.count >= 10
            case "Recovery Success":
                shouldUnlock = scans.count >= 2
            case "Plant Collector":
                shouldUnlock = plants.count >= 5
            default:
                shouldUnlock = false
            }

            if shouldUnlock && !achievement.unlocked {
                achievement.unlocked = true
                achievement.unlockedAt = .now
            }
        }
    }
}
