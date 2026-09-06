import Foundation
import AVFoundation
import UIKit
import SwiftUI

@MainActor
final class CameraManager: ObservableObject {
    @Published var isPresented = false
    @Published private(set) var lastCapturedImage: UIImage?
    @Published private(set) var lastError: String?
    @Published private(set) var isAuthorized = false

    func refreshAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }

    func openCamera() {
        refreshAuthorization()
        guard isAuthorized else {
            lastError = "Camera permission is not granted."
            return
        }
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            lastError = "Camera is unavailable on this device."
            return
        }
        lastError = nil
        isPresented = true
    }

    func handleCapture(_ image: UIImage?) {
        lastCapturedImage = image
        isPresented = false
    }

    func handleCancel() {
        isPresented = false
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @ObservedObject var manager: CameraManager

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.cameraCaptureMode = .photo
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(manager: manager)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let manager: CameraManager

        init(manager: CameraManager) {
            self.manager = manager
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            Task { @MainActor in
                manager.handleCancel()
            }
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            Task { @MainActor in
                manager.handleCapture(image)
            }
        }
    }
}
