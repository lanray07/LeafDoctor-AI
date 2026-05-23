import Foundation

@MainActor
final class AssistantViewModel: ObservableObject {
    @Published var question = ""
    @Published var response = ""
    @Published var treatmentPlan: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let aiService: AIService

    init(aiService: AIService = MockAIService()) {
        self.aiService = aiService
    }

    func generateRecoveryAdvice(for plant: PlantProfile, latestScan: PlantScan?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            response = try await aiService.generateRecoveryAdvice(for: plant, latestScan: latestScan)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func generateTreatmentPlan(for scan: PlantScanResult, plantType: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            treatmentPlan = try await aiService.generateTreatmentPlan(for: scan, plantType: plantType)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func answerGeneralCareQuestion(for plant: PlantProfile?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let name = plant?.plantName ?? "your plant"
        response = """
        For \(name), consider making one care change at a time and monitoring the result. If your note is "\(question)", it may indicate a watering, light, soil, or pest issue. Check soil moisture, inspect leaf undersides, compare recent photos, and avoid strong treatments until symptoms are clearer.
        """
    }
}
