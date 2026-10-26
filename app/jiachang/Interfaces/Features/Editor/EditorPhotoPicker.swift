import SwiftUI
import PhotosUI

struct EditorPhotoPicker: View {
    let existing: RecipeSummary?
    @Binding var imageData: Data?

    @Environment(PhotoCapture.self) private var capture
    @Environment(\.appLanguage) private var language
    @Environment(\.openURL) private var openURL
    @State private var libraryItem: PhotosPickerItem?
    @State private var showLibrary = false
    @State private var showCamera = false
    @State private var cameraProblem: CameraAvailability?
    @State private var photoFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Menu {
                Button { Task { await openCamera() } } label: {
                    Label(copy(.takePhoto, language), systemImage: "camera.fill")
                }
                Button { showLibrary = true } label: {
                    Label(copy(.chooseFromLibrary, language), systemImage: "photo.on.rectangle")
                }
            } label: {
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
            cameraNotice
        }
        .photosPicker(isPresented: $showLibrary, selection: $libraryItem, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { data in
                showCamera = false
                guard let data else { return }
                let prepared = capture.prepare(data)
                if let prepared { imageData = prepared }
                photoFailed = prepared == nil
            }
            .ignoresSafeArea()
        }
        .onChange(of: libraryItem) { _, item in
            guard let item else { return }
            Task {
                let data = try? await item.loadTransferable(type: Data.self)
                let prepared = data.flatMap(capture.prepare)
                if let prepared { imageData = prepared }
                photoFailed = prepared == nil
                libraryItem = nil
            }
        }
    }

    @ViewBuilder
    private var cameraNotice: some View {
        if photoFailed {
            Text(copy(.photoLoadFailed, language))
                .font(.footnote)
                .foregroundStyle(Color.terracotta)
        }
        if let cameraProblem {
            HStack(spacing: 8) {
                Text(copy(cameraProblem == .denied ? .cameraDenied : .cameraUnavailable, language))
                    .font(.footnote)
                    .foregroundStyle(Color.muted)
                if cameraProblem == .denied, let url = URL(string: UIApplication.openSettingsURLString) {
                    Button(copy(.openSettings, language)) { openURL(url) }
                        .font(.footnote.weight(.semibold))
                }
            }
        }
    }

    @ViewBuilder
    private var photo: some View {
        if let imageData, let image = UIImage(data: imageData) {
            Color.clear.overlay { Image(uiImage: image).resizable().scaledToFill() }.clipped()
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

    private func openCamera() async {
        if await capture.requestCamera() {
            cameraProblem = nil
            showCamera = true
        } else {
            cameraProblem = capture.cameraAvailability
        }
    }
}
