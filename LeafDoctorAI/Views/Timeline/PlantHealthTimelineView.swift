import SwiftData
import SwiftUI
import UIKit

struct PlantHealthTimelineView: View {
    @Query(sort: \PlantProfile.createdAt, order: .reverse) private var plants: [PlantProfile]
    @Query(sort: \PlantScan.createdAt, order: .reverse) private var scans: [PlantScan]
    @Query(sort: \CareTask.dueDate, order: .reverse) private var tasks: [CareTask]
    @Query(sort: \PlantPhoto.createdAt, order: .reverse) private var photos: [PlantPhoto]
    @State private var selectedPlantID: UUID?

    init(initialPlantID: UUID? = nil) {
        _selectedPlantID = State(initialValue: initialPlantID)
    }

    private var filteredScans: [PlantScan] {
        guard let selectedPlantID else { return scans }
        return scans.filter { $0.plantId == selectedPlantID }
    }

    private var filteredTasks: [CareTask] {
        guard let selectedPlantID else { return tasks }
        return tasks.filter { $0.plantId == selectedPlantID }
    }

    private var filteredPhotos: [PlantPhoto] {
        guard let selectedPlantID else { return photos }
        return photos.filter { $0.plantId == selectedPlantID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                beforeAfter
                progressTrend
                CareTimelineView(scans: filteredScans, tasks: filteredTasks)
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding()
        }
        .background(.leafMint.opacity(0.12))
        .navigationTitle("Health Timeline")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plant health timeline")
                .font(.largeTitle.weight(.bold))
            Text("Scan history, watering history, treatment progress, before/after photos, and recovery trend.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Plant", selection: $selectedPlantID) {
                Text("All plants").tag(UUID?.none)
                ForEach(plants) { plant in
                    Text(plant.nickname.isEmpty ? plant.plantName : plant.nickname).tag(Optional(plant.id))
                }
            }
            .pickerStyle(.menu)

            HStack(spacing: 10) {
                MetricPill(title: "Scans", value: "\(filteredScans.count)", icon: "waveform.path.ecg")
                MetricPill(title: "Care events", value: "\(filteredTasks.filter(\.completed).count)", icon: "checkmark.circle.fill")
            }
        }
    }

    private var beforeAfter: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Before and after")
                .font(.headline)
            if filteredPhotos.count < 2 {
                EmptyStateView(systemImage: "photo.on.rectangle.angled", title: "More photos needed", message: "Two or more saved scan photos will create a before/after comparison.")
            } else {
                HStack(spacing: 12) {
                    photoTile(filteredPhotos.last, title: "Before")
                    photoTile(filteredPhotos.first, title: "After")
                }
            }
        }
    }

    private var progressTrend: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recovery trend")
                .font(.headline)
            if filteredScans.isEmpty {
                EmptyStateView(systemImage: "chart.line.uptrend.xyaxis", title: "No trend yet", message: "Repeat scans over time to build a health score trend.")
            } else {
                let sorted = filteredScans.sorted { $0.createdAt < $1.createdAt }
                ForEach(sorted.suffix(5)) { scan in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(scan.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                            Spacer()
                            Text("\(Int(scan.severityValue.healthScore))/100")
                                .font(.caption.weight(.semibold))
                        }
                        ProgressView(value: scan.severityValue.healthScore, total: 100)
                            .tint(.leafPrimary)
                    }
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    @ViewBuilder
    private func photoTile(_ photo: PlantPhoto?, title: String) -> some View {
        if let photo, let data = photo.imageData, let image = UIImage(data: data) {
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text(title)
                    .font(.caption.weight(.bold))
                    .padding(8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(8)
            }
        } else {
            EmptyStateView(systemImage: "photo", title: title, message: "No photo")
        }
    }
}
