import SwiftUI
import UIKit

extension UIImage {
    func centerCroppedSquare(scale: CGFloat = 1) -> UIImage {
        let shortestSide = min(size.width, size.height) / max(scale, 1)
        let origin = CGPoint(
            x: (size.width - shortestSide) / 2,
            y: (size.height - shortestSide) / 2
        )
        let cropRect = CGRect(origin: origin, size: CGSize(width: shortestSide, height: shortestSide))

        guard let cgImage = cgImage?.cropping(to: cropRect) else { return self }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ImageCropperView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    var onSave: (UIImage) -> Void
    @State private var zoom: Double = 1

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ZStack {
                    Color.black.opacity(0.9)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(zoom)
                        .frame(width: 280, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(.white.opacity(0.8), lineWidth: 2)
                        )
                }
                .frame(maxWidth: .infinity)
                .frame(height: 340)

                VStack(alignment: .leading) {
                    Text("Crop zoom")
                        .font(.headline)
                    Slider(value: $zoom, in: 1...2.4)
                }
                .padding(.horizontal)

                Text("Center the affected area inside the crop square. LeafDoctor AI will use this focused image for the mock scan.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .navigationTitle("Crop photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use Image") {
                        onSave(image.centerCroppedSquare(scale: zoom))
                        dismiss()
                    }
                }
            }
        }
    }
}
