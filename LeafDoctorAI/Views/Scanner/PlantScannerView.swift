import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct PlantScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlantProfile.createdAt, order: .reverse) private var plants: [PlantProfile]
    @StateObject private var viewModel = ScannerViewModel()
    @State private var selectedPlantID: UUID?
    @State private var showingCamera = false
    @State private var showingCropper = false
    @State private var savedScan: PlantScan?
    @State private var saveMessage: String?

    private var selectedPlant: PlantProfile? {
        plants.first(where: { $0.id == selectedPlantID })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                photoInput
                scanDetails
                scanButton
                resultSection
                DisclaimerBox()
            }
            .padding()
        }
        .background(.leafMint.opacity(0.12))
        .sheet(isPresented: $showingCamera) {
            CameraPicker { image in
                viewModel.setCameraImage(image)
                showingCropper = true
            }
        }
        .sheet(isPresented: $showingCropper) {
            if let image = viewModel.selectedImage {
                ImageCropperView(image: image) { cropped in
                    viewModel.setCroppedImage(cropped)
                }
            }
        }
        .onChange(of: viewModel.selectedPickerItem) { _, _ in
            Task {
                await viewModel.loadSelectedPhoto()
                showingCropper = viewModel.selectedImage != nil
            }
        }
    }

    private var photoInput: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Plant photo")
                .font(.headline)

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.background)
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(alignment: .bottomTrailing) {
                            Button {
                                showingCropper = true
                            } label: {
                                Label("Crop", systemImage: "crop")
                                    .font(.caption.weight(.semibold))
                                    .padding(9)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                            .padding()
                        }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 42))
                            .foregroundStyle(.leafPrimary)
                        Text("Add a clear photo of the affected plant area.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                }
            }

            HStack {
                PhotosPicker(selection: $viewModel.selectedPickerItem, matching: .images) {
                    Label("Upload", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    showingCamera = true
                } label: {
                    Label("Camera", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var scanDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Plant", selection: $selectedPlantID) {
                Text("Create scanned plant").tag(UUID?.none)
                ForEach(plants) { plant in
                    Text(plant.nickname.isEmpty ? plant.plantName : plant.nickname).tag(Optional(plant.id))
                }
            }

            Picker("Plant area", selection: $viewModel.photoCategory) {
                ForEach(PhotoCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading) {
                Text("Symptoms or notes")
                    .font(.subheadline.weight(.semibold))
                TextEditor(text: $viewModel.symptoms)
                    .frame(minHeight: 110)
                    .padding(6)
                    .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var scanButton: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                Task { await runScan() }
            } label: {
                HStack {
                    if viewModel.isScanning {
                        ProgressView()
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(viewModel.isScanning ? "Scanning..." : "Scan Plant")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isScanning)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if let saveMessage {
                Text(saveMessage)
                    .font(.footnote)
                    .foregroundStyle(.leafPrimary)
            }
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI output")
                .font(.headline)
            if let savedScan {
                PlantScanCard(scan: savedScan)
                TreatmentPlanCard(
                    title: "Recommendations",
                    steps: savedScan.treatmentSuggestions + [savedScan.wateringAdvice, savedScan.sunlightAdvice]
                )
            } else if let result = viewModel.scanResult {
                VStack(alignment: .leading, spacing: 12) {
                    HealthStatusBadge(severity: result.severity)
                    Text(result.disease)
                        .font(.title3.weight(.bold))
                    Text(result.summary)
                        .foregroundStyle(.secondary)
                    TreatmentPlanCard(title: "Treatment routine", steps: result.treatmentSuggestions)
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                EmptyStateView(systemImage: "waveform.path.ecg", title: "Ready to diagnose", message: "Mock AI mode will return possible issue, confidence, severity, symptoms, causes, treatment, watering, and sunlight advice.")
            }
        }
    }

    private func runScan() async {
        let plant = selectedPlant ?? createScannedPlant()
        let plantType = plant.species.isEmpty ? plant.plantName : plant.species
        guard let result = await viewModel.scan(plantType: plantType) else { return }

        let scan = PlantScan(
            plantId: plant.id,
            diseaseName: result.disease,
            diseaseCategory: result.category.rawValue,
            severity: result.severity.rawValue,
            confidence: result.confidence,
            symptoms: result.symptoms,
            possibleCauses: result.possibleCauses,
            treatmentSuggestions: result.treatmentSuggestions,
            wateringAdvice: result.wateringAdvice,
            sunlightAdvice: result.sunlightAdvice,
            summary: result.summary
        )
        modelContext.insert(scan)

        if let data = viewModel.selectedImageData {
            modelContext.insert(PlantPhoto(
                plantId: plant.id,
                imageData: data,
                category: viewModel.photoCategory.rawValue
            ))
        }

        savedScan = scan
        selectedPlantID = plant.id
        saveMessage = "Saved scan to \(plant.plantName)."
    }

    private func createScannedPlant() -> PlantProfile {
        let count = plants.filter { $0.plantName.hasPrefix("Scanned Plant") }.count + 1
        let plant = PlantProfile(
            plantName: "Scanned Plant \(count)",
            location: "Unassigned",
            indoorOutdoor: PlantEnvironment.indoor.rawValue,
            notes: "Created from plant scanner."
        )
        modelContext.insert(plant)
        return plant
    }
}
