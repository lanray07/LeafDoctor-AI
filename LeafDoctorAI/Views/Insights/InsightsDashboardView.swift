import Charts
import SwiftData
import SwiftUI

struct InsightsDashboardView: View {
    @Query(sort: \PlantProfile.createdAt, order: .reverse) private var plants: [PlantProfile]
    @Query(sort: \PlantScan.createdAt, order: .reverse) private var scans: [PlantScan]
    @Query(sort: \CareTask.dueDate, order: .reverse) private var tasks: [CareTask]
    @Query(sort: \Achievement.title, order: .forward) private var achievements: [Achievement]

    private var averageHealthScore: Double {
        let latestScans = plants.compactMap { plant in
            scans.first(where: { $0.plantId == plant.id })
        }
        guard !latestScans.isEmpty else { return 100 }
        return latestScans.map { $0.severityValue.healthScore }.reduce(0, +) / Double(latestScans.count)
    }

    private var reminderCompletionRate: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter(\.completed).count) / Double(tasks.count)
    }

    private var wateringConsistency: Double {
        let wateringTasks = tasks.filter { $0.taskTypeValue == .watering }
        guard !wateringTasks.isEmpty else { return 0 }
        return Double(wateringTasks.filter(\.completed).count) / Double(wateringTasks.count)
    }

    private var issueCounts: [IssueCount] {
        let grouped = Dictionary(grouping: scans, by: \.diseaseCategory)
        return grouped.map { IssueCount(name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private var healthiestPlants: [PlantHealth] {
        plants.map { plant in
            let score = scans.first(where: { $0.plantId == plant.id })?.severityValue.healthScore ?? 100
            return PlantHealth(name: plant.nickname.isEmpty ? plant.plantName : plant.nickname, score: score)
        }
        .sorted { $0.score > $1.score }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                metricsGrid
                issuesChart
                healthChart
                achievementsSection
            }
            .padding()
        }
        .background(.leafMint.opacity(0.12))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    PlantHealthTimelineView()
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .accessibilityLabel("Plant health timeline")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insights")
                .font(.largeTitle.weight(.bold))
            Text("Monitor healthiest plants, common issues, watering consistency, health score, and reminder completion.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricPill(title: "Average health", value: "\(Int(averageHealthScore))/100", icon: "heart.circle.fill")
            MetricPill(title: "Reminder completion", value: reminderCompletionRate.formatted(.percent.precision(.fractionLength(0))), icon: "checkmark.circle.fill")
            MetricPill(title: "Watering consistency", value: wateringConsistency.formatted(.percent.precision(.fractionLength(0))), icon: "drop.fill")
            MetricPill(title: "Tracked issues", value: "\(scans.count)", icon: "cross.case.fill")
        }
    }

    private var issuesChart: some View {
        AnalyticsChartCard(title: "Most common issues", subtitle: "Based on saved scan categories") {
            if issueCounts.isEmpty {
                EmptyStateView(systemImage: "chart.bar", title: "No scan data", message: "Scan plants to populate issue trends.")
            } else {
                Chart(issueCounts.prefix(6)) { issue in
                    BarMark(
                        x: .value("Issue", issue.name),
                        y: .value("Scans", issue.count)
                    )
                    .foregroundStyle(.leafTeal)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
    }

    private var healthChart: some View {
        AnalyticsChartCard(title: "Healthiest plants", subtitle: "Latest scan score, or 100 without scans") {
            if healthiestPlants.isEmpty {
                EmptyStateView(systemImage: "leaf", title: "No plants", message: "Add plants to compare health scores.")
            } else {
                Chart(healthiestPlants.prefix(6)) { plant in
                    BarMark(
                        x: .value("Plant", plant.name),
                        y: .value("Health", plant.score)
                    )
                    .foregroundStyle(.leafPrimary)
                }
                .chartYScale(domain: 0...100)
            }
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                Spacer()
                Text("\(achievements.filter(\.unlocked).count)/\(achievements.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if achievements.isEmpty {
                EmptyStateView(systemImage: "seal", title: "No badges yet", message: "Achievements appear after your first plant, scans, and care streaks.")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(achievements) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
            }
        }
    }

    private struct IssueCount: Identifiable {
        var id: String { name }
        var name: String
        var count: Int
    }

    private struct PlantHealth: Identifiable {
        var id: String { name }
        var name: String
        var score: Double
    }
}
