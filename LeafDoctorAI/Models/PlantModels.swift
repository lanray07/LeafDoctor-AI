import Foundation
import SwiftData

enum ExperienceLevel: String, CaseIterable, Codable, Identifiable, Hashable {
    case beginner = "Beginner"
    case hobbyist = "Hobbyist"
    case advanced = "Advanced"

    var id: String { rawValue }
}

enum PlantEnvironment: String, CaseIterable, Codable, Identifiable, Hashable {
    case indoor = "Indoor"
    case outdoor = "Outdoor"
    case greenhouse = "Greenhouse"

    var id: String { rawValue }
}

enum ReminderPreference: String, CaseIterable, Codable, Identifiable, Hashable {
    case essential = "Essential reminders"
    case balanced = "Balanced routine"
    case proactive = "Proactive coaching"

    var id: String { rawValue }
}

enum PhotoCategory: String, CaseIterable, Codable, Identifiable, Hashable {
    case leaf = "Leaf"
    case stem = "Stem"
    case flower = "Flower"
    case roots = "Roots"
    case fullPlant = "Full plant"

    var id: String { rawValue }
}

enum DiseaseSeverity: String, CaseIterable, Codable, Identifiable, Hashable {
    case healthy = "Healthy"
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"

    var id: String { rawValue }

    var healthScore: Double {
        switch self {
        case .healthy: return 96
        case .mild: return 76
        case .moderate: return 52
        case .severe: return 25
        }
    }
}

enum DiseaseCategory: String, CaseIterable, Codable, Identifiable, Hashable {
    case fungalDisease = "Fungal disease"
    case bacterialDisease = "Bacterial disease"
    case pestDamage = "Pest damage"
    case rootRot = "Root rot"
    case nutrientDeficiency = "Nutrient deficiency"
    case overwatering = "Overwatering"
    case underwatering = "Underwatering"
    case leafBurn = "Leaf burn"
    case mould = "Mould"
    case healthyPlant = "Healthy plant"

    var id: String { rawValue }
}

enum CareTaskType: String, CaseIterable, Codable, Identifiable, Hashable {
    case watering = "Watering"
    case fertilising = "Fertilising"
    case pruning = "Pruning"
    case repotting = "Repotting"
    case misting = "Misting"
    case pestCheck = "Pest check"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .watering: return "drop.fill"
        case .fertilising: return "leaf.fill"
        case .pruning: return "scissors"
        case .repotting: return "shippingbox.fill"
        case .misting: return "cloud.rain.fill"
        case .pestCheck: return "ladybug.fill"
        }
    }
}

enum SubscriptionPlan: String, CaseIterable, Codable, Identifiable, Hashable {
    case free = "Free"
    case pro = "Pro"
    case premium = "Premium"
    case lifetime = "Lifetime"

    var id: String { rawValue }
}

struct PlantScanResult: Codable, Hashable {
    var disease: String
    var category: DiseaseCategory
    var severity: DiseaseSeverity
    var confidence: Double
    var symptoms: [String]
    var possibleCauses: [String]
    var treatmentSuggestions: [String]
    var wateringAdvice: String
    var sunlightAdvice: String
    var summary: String
}

struct CareTaskDraft: Identifiable, Hashable {
    var id = UUID()
    var taskType: CareTaskType
    var dueDate: Date
    var repeatIntervalDays: Int
    var notes: String
}

@Model
final class PlantProfile {
    @Attribute(.unique) var id: UUID
    var plantName: String
    var nickname: String
    var species: String
    var location: String
    var indoorOutdoor: String
    var wateringFrequency: String
    var sunlightNeeds: String
    var fertilizerSchedule: String
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        plantName: String,
        nickname: String = "",
        species: String = "",
        location: String = "",
        indoorOutdoor: String = PlantEnvironment.indoor.rawValue,
        wateringFrequency: String = "Every 7 days",
        sunlightNeeds: String = "Bright indirect light",
        fertilizerSchedule: String = "Monthly during growing season",
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.plantName = plantName
        self.nickname = nickname
        self.species = species
        self.location = location
        self.indoorOutdoor = indoorOutdoor
        self.wateringFrequency = wateringFrequency
        self.sunlightNeeds = sunlightNeeds
        self.fertilizerSchedule = fertilizerSchedule
        self.notes = notes
        self.createdAt = createdAt
    }
}

@Model
final class PlantPhoto {
    @Attribute(.unique) var id: UUID
    var plantId: UUID
    @Attribute(.externalStorage) var imageData: Data?
    var category: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        plantId: UUID,
        imageData: Data?,
        category: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.plantId = plantId
        self.imageData = imageData
        self.category = category
        self.createdAt = createdAt
    }
}

@Model
final class PlantScan {
    @Attribute(.unique) var id: UUID
    var plantId: UUID
    var diseaseName: String
    var diseaseCategory: String
    var severity: String
    var confidence: Double
    var symptoms: [String]
    var possibleCauses: [String]
    var treatmentSuggestions: [String]
    var wateringAdvice: String
    var sunlightAdvice: String
    var summary: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        plantId: UUID,
        diseaseName: String,
        diseaseCategory: String,
        severity: String,
        confidence: Double,
        symptoms: [String],
        possibleCauses: [String],
        treatmentSuggestions: [String],
        wateringAdvice: String,
        sunlightAdvice: String,
        summary: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.plantId = plantId
        self.diseaseName = diseaseName
        self.diseaseCategory = diseaseCategory
        self.severity = severity
        self.confidence = confidence
        self.symptoms = symptoms
        self.possibleCauses = possibleCauses
        self.treatmentSuggestions = treatmentSuggestions
        self.wateringAdvice = wateringAdvice
        self.sunlightAdvice = sunlightAdvice
        self.summary = summary
        self.createdAt = createdAt
    }
}

@Model
final class CareTask {
    @Attribute(.unique) var id: UUID
    var plantId: UUID
    var taskType: String
    var dueDate: Date
    var completed: Bool
    var completedAt: Date?
    var repeatIntervalDays: Int
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        plantId: UUID,
        taskType: String,
        dueDate: Date,
        completed: Bool = false,
        completedAt: Date? = nil,
        repeatIntervalDays: Int = 0,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.plantId = plantId
        self.taskType = taskType
        self.dueDate = dueDate
        self.completed = completed
        self.completedAt = completedAt
        self.repeatIntervalDays = repeatIntervalDays
        self.notes = notes
        self.createdAt = createdAt
    }
}

@Model
final class Achievement {
    @Attribute(.unique) var id: UUID
    var title: String
    var achievementDescription: String
    var unlocked: Bool
    var unlockedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        unlocked: Bool = false,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.achievementDescription = description
        self.unlocked = unlocked
        self.unlockedAt = unlockedAt
    }
}

@Model
final class SubscriptionState {
    @Attribute(.unique) var id: UUID
    var plan: String
    var isActive: Bool
    var renewsAt: Date?

    init(
        id: UUID = UUID(),
        plan: String = SubscriptionPlan.free.rawValue,
        isActive: Bool = false,
        renewsAt: Date? = nil
    ) {
        self.id = id
        self.plan = plan
        self.isActive = isActive
        self.renewsAt = renewsAt
    }
}

extension PlantScan {
    var severityValue: DiseaseSeverity {
        DiseaseSeverity(rawValue: severity) ?? .moderate
    }

    var confidencePercent: String {
        confidence.formatted(.percent.precision(.fractionLength(0)))
    }
}

extension CareTask {
    var taskTypeValue: CareTaskType {
        CareTaskType(rawValue: taskType) ?? .watering
    }

    var isDueToday: Bool {
        Calendar.current.isDateInToday(dueDate) && !completed
    }

    var isOverdue: Bool {
        dueDate < Calendar.current.startOfDay(for: .now) && !completed
    }
}
