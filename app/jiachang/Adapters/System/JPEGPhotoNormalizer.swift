import UIKit

/// Caps the longest edge and re-encodes as JPEG so stored photos stay small.
struct JPEGPhotoNormalizer: PhotoNormalizer {
    var maximumEdge: CGFloat = 2000
    var quality: CGFloat = 0.85

    func normalize(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maximumEdge / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let output = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return output.jpegData(compressionQuality: quality)
    }
}
