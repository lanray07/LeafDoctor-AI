import Foundation
import UIKit

enum PDFReportGenerator {
    static func makeCareReport(
        plant: PlantProfile,
        scans: [PlantScan],
        tasks: [CareTask],
        photos: [PlantPhoto]
    ) throws -> URL {
        let fileName = "\(plant.plantName.replacingOccurrences(of: " ", with: "-"))-LeafDoctor-Report.pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        try renderer.writePDF(to: url) { context in
            context.beginPage()
            var y: CGFloat = 44

            y = draw("LeafDoctor AI Care Report", at: y, font: .boldSystemFont(ofSize: 26), pageRect: pageRect)
            y = draw("Plant profile", at: y + 18, font: .boldSystemFont(ofSize: 18), pageRect: pageRect)
            y = draw("Name: \(plant.plantName)", at: y, pageRect: pageRect)
            y = draw("Nickname: \(plant.nickname.isEmpty ? "None" : plant.nickname)", at: y, pageRect: pageRect)
            y = draw("Species: \(plant.species.isEmpty ? "Unspecified" : plant.species)", at: y, pageRect: pageRect)
            y = draw("Location: \(plant.location.isEmpty ? "Unspecified" : plant.location)", at: y, pageRect: pageRect)
            y = draw("Watering: \(plant.wateringFrequency)", at: y, pageRect: pageRect)
            y = draw("Sunlight: \(plant.sunlightNeeds)", at: y, pageRect: pageRect)

            y = drawSection("Diagnosis history", y: y, context: context, pageRect: pageRect)
            if scans.isEmpty {
                y = draw("No scans recorded yet.", at: y, pageRect: pageRect)
            } else {
                for scan in scans.prefix(6) {
                    y = draw("- \(scan.createdAt.formatted(date: .abbreviated, time: .shortened)): \(scan.diseaseName) (\(scan.severity), \(scan.confidencePercent))", at: y, pageRect: pageRect)
                    y = draw("  \(scan.summary)", at: y, font: .systemFont(ofSize: 11), pageRect: pageRect)
                }
            }

            y = drawSection("Treatment recommendations", y: y, context: context, pageRect: pageRect)
            let recommendations = scans.first?.treatmentSuggestions ?? []
            if recommendations.isEmpty {
                y = draw("No treatment recommendations recorded yet.", at: y, pageRect: pageRect)
            } else {
                for item in recommendations.prefix(7) {
                    y = draw("- \(item)", at: y, pageRect: pageRect)
                }
            }

            y = drawSection("Watering schedule", y: y, context: context, pageRect: pageRect)
            if tasks.isEmpty {
                y = draw("No scheduled care tasks yet.", at: y, pageRect: pageRect)
            } else {
                for task in tasks.prefix(8) {
                    y = draw("- \(task.taskType): \(task.dueDate.formatted(date: .abbreviated, time: .shortened)) \(task.completed ? "(completed)" : "")", at: y, pageRect: pageRect)
                }
            }

            y = drawSection("Progress photos", y: y, context: context, pageRect: pageRect)
            y = drawPhotos(photos: photos, at: y, context: context, pageRect: pageRect)

            y = drawSection("Care summary", y: y, context: context, pageRect: pageRect)
            _ = draw("AI results are informational only, not guaranteed botanical diagnosis. Treatment outcomes may vary. Severe infestations should be reviewed by professionals.", at: y, font: .italicSystemFont(ofSize: 11), pageRect: pageRect)
        }

        return url
    }

    private static func drawSection(_ title: String, y: CGFloat, context: UIGraphicsPDFRendererContext, pageRect: CGRect) -> CGFloat {
        var currentY = y + 20
        if currentY > pageRect.height - 120 {
            context.beginPage()
            currentY = 44
        }
        return draw(title, at: currentY, font: .boldSystemFont(ofSize: 18), pageRect: pageRect)
    }

    private static func drawPhotos(
        photos: [PlantPhoto],
        at y: CGFloat,
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect
    ) -> CGFloat {
        let images = photos.prefix(4).compactMap { photo -> UIImage? in
            guard let data = photo.imageData else { return nil }
            return UIImage(data: data)
        }

        guard !images.isEmpty else {
            return draw("No progress photos saved yet.", at: y, pageRect: pageRect)
        }

        var currentY = y
        let size = CGSize(width: 120, height: 120)
        var x: CGFloat = 44
        for image in images {
            if x + size.width > pageRect.width - 44 {
                x = 44
                currentY += size.height + 12
            }
            if currentY > pageRect.height - 170 {
                context.beginPage()
                currentY = 44
                x = 44
            }
            image.draw(in: CGRect(origin: CGPoint(x: x, y: currentY), size: size))
            x += size.width + 12
        }
        return currentY + size.height + 8
    }

    @discardableResult
    private static func draw(
        _ text: String,
        at y: CGFloat,
        font: UIFont = .systemFont(ofSize: 12),
        pageRect: CGRect
    ) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraph,
            .foregroundColor: UIColor.label
        ]
        let rect = CGRect(x: 44, y: y, width: pageRect.width - 88, height: 96)
        let measured = text.boundingRect(with: rect.size, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
        text.draw(with: rect, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
        return y + ceil(measured.height) + 8
    }
}
