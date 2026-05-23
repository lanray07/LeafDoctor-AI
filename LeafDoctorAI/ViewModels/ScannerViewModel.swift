import Foundation
import PhotosUI
import UIKit

@MainActor
final class ScannerViewModel: ObservableObject {
    @Published var selectedPickerItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var selectedImageData: Data?
    @Published var photoCategory: PhotoCategory = .leaf
    @Published var symptoms = ""
    @Published var isScanning = false
    @Published var scanResult: PlantScanResult?
    @Published var errorMessage: String?

    private let aiService: AIService

    init(aiService: AIService = MockAIService()) {
        self.aiService = aiService
    }

    func loadSelectedPhoto() async {
        guard let selectedPickerItem else { return }

        do {
            if let data = try await selectedPickerItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImageData = data
                selectedImage = image
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setCameraImage(_ image: UIImage) {
        selectedImage = image
        selectedImageData = image.jpegData(compressionQuality: 0.86)
    }

    func setCroppedImage(_ image: UIImage) {
        selectedImage = image
        selectedImageData = image.jpegData(compressionQuality: 0.88)
    }

    func scan(plantType: String) async -> PlantScanResult? {
        guard selectedImageData != nil else {
            errorMessage = "Add a clear plant photo before scanning."
            return nil
        }

        isScanning = true
        errorMessage = nil
        defer { isScanning = false }

        do {
            let result = try await aiService.scanPlantPhoto(
                plantType: plantType,
                photoCategory: photoCategory,
                symptoms: symptoms,
                imageData: selectedImageData
            )
            scanResult = result
            return result
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
