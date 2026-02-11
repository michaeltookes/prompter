import SwiftUI
import UniformTypeIdentifiers
import ImageIO

/// A drop zone that accepts image files via drag-and-drop.
///
/// Features:
/// - Visual feedback during drag hover
/// - Supports common image formats (PNG, JPEG, HEIC, etc.)
/// - Optional click-to-browse fallback
/// - Shows existing image or placeholder
struct ImageDropZone: View {
    /// Binding to the asset reference (nil if no image)
    @Binding var assetRef: AssetRef?

    /// Optional label shown in empty state
    var placeholder: String = "Drop image here"

    /// Whether the zone is currently being hovered over
    @State private var isTargeted = false

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: Theme.imageCornerRadius)
                .fill(Theme.dropZoneBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.imageCornerRadius)
                        .stroke(
                            isTargeted ? Theme.accent : Theme.divider,
                            style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: [6, 3])
                        )
                )

            // Content
            if let ref = assetRef {
                // Show existing image
                AssetImageView(assetRef: ref)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.imageCornerRadius))
                    .overlay(alignment: .topTrailing) {
                        // Remove button
                        Button(action: { assetRef = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .accessibilityLabel("Remove image")
                        .accessibilityHint("Removes this image from the card")
                    }
            } else {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(isTargeted ? Theme.accent : Theme.textSecondary)
                        .accessibilityHidden(true)

                    Text(placeholder)
                        .font(.system(size: Theme.captionFontSize))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .onDrop(of: [.image, .fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
        .animation(.easeInOut(duration: 0.15), value: isTargeted)
        .accessibilityLabel(assetRef != nil ? "Image slot with image" : placeholder)
        .accessibilityHint("Drag and drop an image file to add it")
    }

    /// Handles dropped items
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        // Try to load as file URL first (more reliable for local files)
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

                // Verify it's an image (on background thread)
                guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                      CGImageSourceGetCount(imageSource) > 0 else { return }

                // Import image on background thread to avoid blocking UI
                Task.detached(priority: .userInitiated) {
                    let ref = await AssetManager.shared.importImageAsync(from: url)
                    await MainActor.run {
                        if let ref = ref {
                            self.assetRef = ref
                        }
                    }
                }
            }
            return true
        }

        // Fallback to loading as image data
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                guard let data = data else { return }

                // Import image on background thread to avoid blocking UI
                Task.detached(priority: .userInitiated) {
                    let ref = await AssetManager.shared.importImageAsync(data: data)
                    await MainActor.run {
                        if let ref = ref {
                            self.assetRef = ref
                        }
                    }
                }
            }
            return true
        }

        return false
    }
}

/// Displays an image from an AssetRef
struct AssetImageView: View {
    let assetRef: AssetRef

    @State private var image: NSImage?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .accessibilityLabel("Card image")
            } else if loadFailed {
                // Show error state with retry option
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.textSecondary)
                        .accessibilityHidden(true)
                    Text("Failed to load")
                        .font(.system(size: Theme.captionFontSize))
                        .foregroundColor(Theme.textSecondary)
                    Button("Retry") {
                        loadFailed = false
                        loadImage()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.accent)
                    .accessibilityLabel("Retry loading image")
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: assetRef.id) { _, _ in
            loadFailed = false
            loadImage()
        }
    }

    private func loadImage() {
        Task {
            let nsImage = await AssetManager.shared.loadImageAsync(for: assetRef)
            // Ensure @State updates happen on the main thread
            await MainActor.run {
                if let nsImage = nsImage {
                    self.image = nsImage
                    self.loadFailed = false
                } else {
                    self.loadFailed = true
                }
            }
        }
    }
}

#Preview("Empty State") {
    ImageDropZone(assetRef: .constant(nil))
        .frame(width: 200, height: 150)
        .padding()
}

#Preview("With Placeholder") {
    ImageDropZone(assetRef: .constant(nil), placeholder: "Drop logo here")
        .frame(width: 200, height: 150)
        .padding()
}
