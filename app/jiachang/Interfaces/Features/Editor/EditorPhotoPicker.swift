import SwiftUI
import PhotosUI

struct EditorPhotoPicker: View {
    let existing: RecipeSummary?
    @Binding var imageData: Data?
    @Environment(\.appLanguage) private var language
    @State private var item: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $item, matching: .images) {
            ZStack(alignment: .bottomLeading) {
                photo
                    .frame(height: 230)
                    .frame(maxWidth: .infinity)
                Label(copy(.changePhoto, language), systemImage: "camera.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(PressableCardStyle())
        .onChange(of: item) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    imageData = scaledJPEG(data)
                }
            }
        }
    }

    @ViewBuilder
    private var photo: some View {
        if let imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image).resizable().scaledToFill()
        } else if let existing {
            RecipeArtwork(recipe: existing, size: .original)
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color.caramel.opacity(0.8), Color.persimmon],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "camera.fill")
                    .font(.system(size: 66, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }

    private func scaledJPEG(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maximum: CGFloat = 2000
        let scale = min(1, maximum / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let output = UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return output.jpegData(compressionQuality: 0.85)
    }
}
