import XCTest
@testable import jiachang

@MainActor
final class PhotoCaptureTests: XCTestCase {
    func testOnlyGrantedCameraAccessAllowsPresentation() async {
        for availability in [CameraAvailability.ready, .denied, .unavailable] {
            let capture = PhotoCapture(
                cameraAccess: StubCameraAccess(availability: availability),
                normalizer: JPEGPhotoNormalizer()
            )
            let allowed = await capture.requestCamera()
            XCTAssertEqual(allowed, availability == .ready)
            XCTAssertEqual(capture.cameraAvailability, availability)
        }
    }
}

private struct StubCameraAccess: CameraAccess {
    let availability: CameraAvailability

    func requestAccess() async -> CameraAvailability { availability }
}
