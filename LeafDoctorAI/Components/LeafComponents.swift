import SwiftUI
import UIKit

extension Color {
    static let leafPrimary = Color("AccentColor")
    static let leafDeep = Color(red: 0.05, green: 0.32, blue: 0.22)
    static let leafTeal = Color(red: 0.03, green: 0.55, blue: 0.50)
    static let leafMint = Color(red: 0.83, green: 0.94, blue: 0.88)
    static let leafWarning = Color(red: 0.88, green: 0.55, blue: 0.18)
    static let leafDanger = Color(red: 0.80, green: 0.20, blue: 0.18)
}

extension ShapeStyle where Self == Color {
    static var leafPrimary: Color { Color.leafPrimary }
    static var leafDeep: Color { Color.leafDeep }
    static var leafTeal: Color { Color.leafTeal }
    static var leafMint: Color { Color.leafMint }
    static var leafWarning: Color { Color.leafWarning }
    static var leafDanger: Color { Color.leafDanger }
}

struct PlantCard: View {
    let plant: PlantProfile
    var latestScan: PlantScan?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: [.leafMint, .leafTeal.opacity(0.22)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "leaf.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.leafDeep)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 5) {
                Text(plant.nickname.isEmpty ? plant.plantName : plant.nickname)
                    .font(.headline)
                    .lineLimit(1)
                Text(plant.species.isEmpty ? plant.plantName : plant.species)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Label(plant.location.isEmpty ? plant.indoorOutdoor : plant.location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let latestScan {
                HealthStatusBadge(severity: latestScan.severityValue)
            } else {
                HealthStatusBadge(severity: .healthy)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.leafPrimary.opacity(0.12), lineWidth: 1)
        )
    }
}

struct HealthStatusBadge: View {
    let severity: DiseaseSeverity

    private var color: Color {
        switch severity {
        case .healthy: return .leafTeal
        case .mild: return .leafWarning
        case .moderate: return .orange
        case .severe: return .leafDanger
        }
    }

    var body: some View {
        Text(severity.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

struct WateringReminderCard: View {
    let task: CareTask
    let plantName: String
    var onComplete: () -> Void
    var onSnooze: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: task.taskTypeValue.systemImage)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(.leafTeal, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(plantName)
                    .font(.headline)
                Text("\(task.taskType) due \(task.dueDate.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Menu {
                Button("Complete", systemImage: "checkmark.circle", action: onComplete)
                Button("Snooze 1 day", systemImage: "clock.arrow.circlepath", action: onSnooze)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
            .accessibilityLabel("Care reminder actions")
        }
        .padding()
        .background(.leafMint.opacity(0.5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct PlantScanCard: View {
    let scan: PlantScan

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scan.diseaseName)
                        .font(.headline)
                    Text(scan.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HealthStatusBadge(severity: scan.severityValue)
            }

            HStack {
                Label(scan.confidencePercent, systemImage: "gauge.with.dots.needle.50percent")
                Spacer()
                Label(scan.diseaseCategory, systemImage: "cross.case.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(scan.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !scan.symptoms.isEmpty {
                compactList(title: "Symptoms", items: scan.symptoms)
            }

            if !scan.possibleCauses.isEmpty {
                compactList(title: "Possible causes", items: scan.possibleCauses)
            }

            if !scan.treatmentSuggestions.isEmpty {
                compactList(title: "Treatment suggestions", items: scan.treatmentSuggestions)
            }

            Label(scan.wateringAdvice, systemImage: "drop.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Label(scan.sunlightAdvice, systemImage: "sun.max.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.secondary.opacity(0.12), lineWidth: 1)
            )
    }

    private func compactList(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            ForEach(items.prefix(3), id: \.self) { item in
                Label(item, systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct TreatmentPlanCard: View {
    let title: String
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "list.clipboard.fill")
                .font(.headline)
                .foregroundStyle(.leafDeep)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(.leafPrimary, in: Circle())
                    Text(step)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.leafMint.opacity(0.46), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct CareTimelineView: View {
    let scans: [PlantScan]
    let tasks: [CareTask]

    private var entries: [TimelineEntry] {
        let scanEntries = scans.map {
            TimelineEntry(
                date: $0.createdAt,
                icon: "waveform.path.ecg",
                title: $0.diseaseName,
                subtitle: "Scan result: \($0.severity)"
            )
        }
        let taskEntries = tasks.map {
            TimelineEntry(
                date: $0.completedAt ?? $0.dueDate,
                icon: $0.taskTypeValue.systemImage,
                title: $0.taskType,
                subtitle: $0.completed ? "Completed" : "Scheduled"
            )
        }
        return (scanEntries + taskEntries).sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if entries.isEmpty {
                EmptyStateView(
                    systemImage: "clock.badge.questionmark",
                    title: "No timeline yet",
                    message: "Scans and completed care tasks will appear here."
                )
            } else {
                ForEach(entries.prefix(12)) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: entry.icon)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(.leafTeal, in: Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.title)
                                .font(.subheadline.weight(.semibold))
                            Text(entry.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private struct TimelineEntry: Identifiable {
        var id = UUID()
        var date: Date
        var icon: String
        var title: String
        var subtitle: String
    }
}

struct AnalyticsChartCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            content
                .frame(height: 180)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.secondary.opacity(0.12), lineWidth: 1)
        )
    }
}

struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: achievement.unlocked ? "seal.fill" : "seal")
                .font(.title2)
                .foregroundStyle(achievement.unlocked ? .leafPrimary : .secondary)
            Text(achievement.title)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(achievement.achievementDescription)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 126)
        .background(achievement.unlocked ? .leafMint.opacity(0.7) : .secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct UpgradeBanner: View {
    var title = "Unlock deeper plant care"
    var message = "Unlimited scans, advanced reminders, PDF reports, and recovery tracking."
    var action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.leafDeep)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.7), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("View") {
                action()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(LinearGradient(colors: [.leafMint, .leafTeal.opacity(0.22)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 34))
                .foregroundStyle(.leafPrimary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct DisclaimerBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("AI disclaimer", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.leafWarning)
            Text("AI results are informational only. They are not guaranteed botanical diagnosis, treatment outcomes may vary, and severe infestations should be reviewed by professionals.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.leafWarning.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.leafPrimary)
            Text(value)
                .font(.title3.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.secondary.opacity(0.12), lineWidth: 1)
        )
    }
}
