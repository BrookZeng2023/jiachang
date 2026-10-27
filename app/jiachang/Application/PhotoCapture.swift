import Foundation
import Observation

/// Use case behind the editor's photo button: decide whether the camera can
/// open, and turn whatever the user picked into storable JPEG data.
@MainActor
@Observable
final class PhotoCapture {
    private(set) var cameraAvailability: CameraAvailability?

    private let cameraAccess: any CameraAccess
    private let normalizer: any PhotoNormalizer

    init(cameraAccess: any CameraAccess, normalizer: any PhotoNormalizer) {
        self.cameraAccess = cameraAccess
        self.normalizer = normalizer
    }

    /// Returns true when the camera may be presented.
    func requestCamera() async -> Bool {
        let availability = await cameraAccess.requestAccess()
        cameraAvailability = availability
        return availability == .ready
    }

    func prepare(_ data: Data) -> Data? {
        normalizer.normalize(data)
    }
}
