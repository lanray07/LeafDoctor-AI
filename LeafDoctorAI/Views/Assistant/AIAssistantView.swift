import SwiftData
import SwiftUI

struct AIAssistantView: View {
    @Query(sort: \PlantProfile.createdAt, order: .reverse) private var plants: [PlantProfile]
    @Query(sort: \PlantScan.createdAt, order: .reverse) private var scans: [PlantScan]
    @StateObject private var viewModel = AssistantViewModel()
    @State private var selectedPlantID: UUID?

    private var selectedPlant: PlantProfile? {
        if let selectedPlantID {
            return plants.first(where: { $0.id == selectedPlantID })
        }
        return plants.first
    }

    private var latestScan: PlantScan? {
        guard let selectedPlant else { return nil }
        return scans.first(where: { $0.plantId == selectedPlant.id })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                questionCard
                responseCard
                DisclaimerBox()
            }
            .padding()
        }
        .background(.leafMint.opacity(0.12))
        .onAppear {
            selectedPlantID = selectedPlantID ?? plants.first?.id
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Plant Care Assistant")
                .font(.largeTitle.weight(.bold))
            Text("Generate recovery plans, treatment routines, watering advice, sunlight adjustments, seasonal care tips, and beginner guidance.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if plants.isEmpty {
                EmptyStateView(systemImage: "leaf", title: "No plants yet", message: "Add a plant profile to make advice more specific.")
            } else {
                Picker("Plant", selection: $selectedPlantID) {
                    ForEach(plants) { plant in
                        Text(plant.nickname.isEmpty ? plant.plantName : plant.nickname).tag(Optional(plant.id))
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ask for guidance")
                .font(.headline)
            TextEditor(text: $viewModel.question)
                .frame(minHeight: 120)
                .padding(6)
                .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack {
                Button {
                    Task {
                        await viewModel.answerGeneralCareQuestion(for: selectedPlant)
                    }
                } label: {
                    Label("Ask", systemImage: "bubble.left.and.text.bubble.right.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    Task {
                        if let selectedPlant {
                            await viewModel.generateRecoveryAdvice(for: selectedPlant, latestScan: latestScan)
                        }
                    }
                } label: {
                    Label("Recovery", systemImage: "cross.case.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedPlant == nil)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var responseCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Assistant output")
                .font(.headline)

            if viewModel.isLoading {
                HStack {
                    ProgressView()
                    Text("Generating cautious care guidance...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            } else if !viewModel.treatmentPlan.isEmpty {
                TreatmentPlanCard(title: "Treatment routine", steps: viewModel.treatmentPlan)
            } else if !viewModel.response.isEmpty {
                Text(viewModel.response)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(.leafMint.opacity(0.46), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else if let latestScan {
                PlantScanCard(scan: latestScan)
                Button {
                    Task {
                        let result = PlantScanResult(
                            disease: latestScan.diseaseName,
                            category: DiseaseCategory(rawValue: latestScan.diseaseCategory) ?? .healthyPlant,
                            severity: latestScan.severityValue,
                            confidence: latestScan.confidence,
                            symptoms: latestScan.symptoms,
                            possibleCauses: latestScan.possibleCauses,
                            treatmentSuggestions: latestScan.treatmentSuggestions,
                            wateringAdvice: latestScan.wateringAdvice,
                            sunlightAdvice: latestScan.sunlightAdvice,
                            summary: latestScan.summary
                        )
                        await viewModel.generateTreatmentPlan(for: result, plantType: selectedPlant?.plantName ?? "plant")
                    }
                } label: {
                    Label("Generate treatment plan", systemImage: "list.clipboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                EmptyStateView(systemImage: "sparkles", title: "Ready to help", message: "Ask about watering, light, treatment routines, recovery progress, or beginner care.")
            }
        }
    }
}
