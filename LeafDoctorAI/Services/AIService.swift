import Foundation

protocol AIService {
    func scanPlantPhoto(
        plantType: String,
        photoCategory: PhotoCategory,
        symptoms: String,
        imageData: Data?
    ) async throws -> PlantScanResult

    func generateTreatmentPlan(for scan: PlantScanResult, plantType: String) async throws -> [String]
    func generateCareSchedule(for plant: PlantProfile) async throws -> [CareTaskDraft]
    func generateRecoveryAdvice(for plant: PlantProfile, latestScan: PlantScan?) async throws -> String
    func generatePlantInsights(plants: [PlantProfile], scans: [PlantScan], tasks: [CareTask]) async throws -> [String]
}

enum AIServiceError: LocalizedError {
    case backendNotConfigured
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .backendNotConfigured:
            return "Remote AI is not configured. Mock AI is enabled by default."
        case .invalidResponse:
            return "The AI response could not be read."
        }
    }
}

struct MockAIService: AIService {
    func scanPlantPhoto(
        plantType: String,
        photoCategory: PhotoCategory,
        symptoms: String,
        imageData: Data?
    ) async throws -> PlantScanResult {
        try await Task.sleep(nanoseconds: 850_000_000)

        let lowercasedSymptoms = symptoms.lowercased()
        let isWaterConcern = lowercasedSymptoms.contains("yellow") || lowercasedSymptoms.contains("droop")
        let isSpotsConcern = lowercasedSymptoms.contains("spot") || photoCategory == .leaf
        let category: DiseaseCategory = isWaterConcern ? .overwatering : (isSpotsConcern ? .fungalDisease : .healthyPlant)
        let severity: DiseaseSeverity = category == .healthyPlant ? .healthy : (isWaterConcern ? .moderate : .mild)
        let disease = category == .healthyPlant ? "No obvious issue detected" : category.rawValue

        return PlantScanResult(
            disease: disease,
            category: category,
            severity: severity,
            confidence: category == .healthyPlant ? 0.82 : 0.74,
            symptoms: category == .healthyPlant ? [
                "Leaves appear generally consistent in colour",
                "No obvious widespread spotting in the selected area"
            ] : [
                "Visible change around the \(photoCategory.rawValue.lowercased()) area",
                "Possible stress pattern may indicate \(category.rawValue.lowercased())",
                "Monitor for spread over the next 3 to 5 days"
            ],
            possibleCauses: category == .healthyPlant ? [
                "Routine seasonal changes",
                "Normal older leaf turnover"
            ] : [
                "Watering routine may not match current light or temperature",
                "Airflow, humidity, or soil drainage may be contributing",
                "Recent environmental change can make symptoms more visible"
            ],
            treatmentSuggestions: category == .healthyPlant ? [
                "Continue the current care routine and photograph again if symptoms change",
                "Check soil moisture before watering instead of watering on a fixed date only"
            ] : [
                "Consider isolating the plant while monitoring the possible issue",
                "Remove badly affected leaves with clean tools when appropriate",
                "Avoid wetting foliage until the plant appears stable",
                "Use a general plant-safe treatment only after checking the species tolerance"
            ],
            wateringAdvice: isWaterConcern
                ? "Consider allowing the top soil layer to dry before watering again. Check that the pot drains freely."
                : "Water when the top 2 to 3 cm of soil feels dry, then drain excess water fully.",
            sunlightAdvice: "Bright indirect light is a safer default while the plant recovers. Avoid sudden direct sun exposure.",
            summary: "This mock result suggests a possible \(disease.lowercased()). It is informational only and should be monitored alongside real plant changes."
        )
    }

    func generateTreatmentPlan(for scan: PlantScanResult, plantType: String) async throws -> [String] {
        try await Task.sleep(nanoseconds: 350_000_000)
        return [
            "Day 1: Photograph the affected area and note soil moisture before changing care.",
            "Days 2-3: Consider adjusting watering and improving airflow around \(plantType.isEmpty ? "the plant" : plantType).",
            "Days 4-7: Monitor whether the possible issue is spreading, fading, or staying stable.",
            "Week 2: If symptoms worsen or pests are visible, consider advice from a local plant professional."
        ]
    }

    func generateCareSchedule(for plant: PlantProfile) async throws -> [CareTaskDraft] {
        [
            CareTaskDraft(taskType: .watering, dueDate: .now.addingTimeInterval(86_400), repeatIntervalDays: 7, notes: "Check soil moisture first."),
            CareTaskDraft(taskType: .pestCheck, dueDate: .now.addingTimeInterval(259_200), repeatIntervalDays: 14, notes: "Inspect under leaves and around stems."),
            CareTaskDraft(taskType: .fertilising, dueDate: .now.addingTimeInterval(1_209_600), repeatIntervalDays: 30, notes: "Use a diluted feed during active growth.")
        ]
    }

    func generateRecoveryAdvice(for plant: PlantProfile, latestScan: PlantScan?) async throws -> String {
        try await Task.sleep(nanoseconds: 300_000_000)
        guard let latestScan else {
            return "Start with a clear photo of \(plant.plantName) and record the current watering routine. The next advice will be more useful after a scan."
        }

        return "The latest scan may indicate \(latestScan.diseaseName.lowercased()). Consider keeping care changes small, monitoring new growth, and comparing photos weekly before escalating treatment."
    }

    func generatePlantInsights(plants: [PlantProfile], scans: [PlantScan], tasks: [CareTask]) async throws -> [String] {
        let completed = tasks.filter(\.completed).count
        let completionRate = tasks.isEmpty ? 0 : Double(completed) / Double(tasks.count)
        return [
            "You are tracking \(plants.count) plant\(plants.count == 1 ? "" : "s") locally and offline.",
            "Reminder completion is \(completionRate.formatted(.percent.precision(.fractionLength(0)))). Consistency may help prevent overwatering.",
            "Your most recent scans should be compared with fresh photos before making major treatment changes."
        ]
    }
}

struct RemoteAIService: AIService {
    var endpoint = URL(string: "https://YOUR_BACKEND_URL.com/leafdoctor-ai")!
    var session: URLSession = .shared

    func scanPlantPhoto(
        plantType: String,
        photoCategory: PhotoCategory,
        symptoms: String,
        imageData: Data?
    ) async throws -> PlantScanResult {
        guard !endpoint.absoluteString.contains("YOUR_BACKEND_URL") else {
            throw AIServiceError.backendNotConfigured
        }

        let body = RemotePlantScanRequest(
            plantType: plantType,
            photoCategory: photoCategory.rawValue,
            symptoms: symptoms,
            imageBase64: imageData?.base64EncodedString() ?? ""
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AIServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(RemotePlantScanResponse.self, from: data)
        return PlantScanResult(
            disease: decoded.disease,
            category: DiseaseCategory(rawValue: decoded.disease) ?? .healthyPlant,
            severity: DiseaseSeverity(rawValue: decoded.severity) ?? .moderate,
            confidence: decoded.confidence,
            symptoms: decoded.symptoms,
            possibleCauses: decoded.possibleCauses ?? [],
            treatmentSuggestions: decoded.treatmentSuggestions,
            wateringAdvice: decoded.wateringAdvice,
            sunlightAdvice: decoded.sunlightAdvice,
            summary: decoded.summary
        )
    }

    func generateTreatmentPlan(for scan: PlantScanResult, plantType: String) async throws -> [String] {
        [
            "Review the possible issue: \(scan.disease).",
            "Monitor symptoms before making aggressive treatment changes.",
            scan.wateringAdvice,
            scan.sunlightAdvice
        ]
    }

    func generateCareSchedule(for plant: PlantProfile) async throws -> [CareTaskDraft] {
        try await MockAIService().generateCareSchedule(for: plant)
    }

    func generateRecoveryAdvice(for plant: PlantProfile, latestScan: PlantScan?) async throws -> String {
        try await MockAIService().generateRecoveryAdvice(for: plant, latestScan: latestScan)
    }

    func generatePlantInsights(plants: [PlantProfile], scans: [PlantScan], tasks: [CareTask]) async throws -> [String] {
        try await MockAIService().generatePlantInsights(plants: plants, scans: scans, tasks: tasks)
    }
}

private struct RemotePlantScanRequest: Codable {
    var plantType: String
    var photoCategory: String
    var symptoms: String
    var imageBase64: String
}

private struct RemotePlantScanResponse: Codable {
    var disease: String
    var severity: String
    var confidence: Double
    var symptoms: [String]
    var possibleCauses: [String]?
    var treatmentSuggestions: [String]
    var wateringAdvice: String
    var sunlightAdvice: String
    var summary: String
}

enum LeafDoctorPrompt {
    static let internalPrompt = """
    You are LeafDoctor AI, a plant health assistant. Review uploaded plant photos, plant type, symptoms, and user notes. Identify possible plant issues using cautious, non-definitive language. Suggest general plant care improvements, watering guidance, and treatment recommendations. Do not claim guaranteed diagnosis or guaranteed treatment outcomes.
    """
}
