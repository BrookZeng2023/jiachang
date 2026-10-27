import SwiftUI
import UIKit

/// Fixed 360×480 pt layout at 3× → 1080×1440 PNG.
@MainActor
struct ShareCardRenderer: ShareCardRendering {
    static let size = CGSize(width: 360, height: 480)

    func pngData(for content: ShareCardContent) throws -> Data {
        let card = ShareCardView(content: content)
            .frame(width: Self.size.width, height: Self.size.height)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        renderer.isOpaque = true
        guard let image = renderer.uiImage, let data = image.pngData() else {
            throw SharingError.renderFailed
        }
        return data
    }
}
