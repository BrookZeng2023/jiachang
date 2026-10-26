import AVFoundation
import UIKit

struct SystemCameraAccess: CameraAccess {
    func requestAccess() async -> CameraAvailability {
        guard await MainActor.run(body: { UIImagePickerController.isSourceTypeAvailable(.camera) }) else {
            return .unavailable
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .ready
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video) ? .ready : .denied
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }
}
