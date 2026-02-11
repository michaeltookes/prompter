import SwiftUI

/// Editor for the Full Image + 3 Bullets layout.
///
/// Fields:
/// - Image: Large full-bleed image
/// - Bullets: Exactly 3 bullet points
struct FullBleedBulletsEditorView: View {
    @Binding var card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Image section
            VStack(alignment: .leading, spacing: 8) {
                Text("Hero Image")
                    .font(.headline)
                    .foregroundColor(Theme.editorTextSecondary)

                ImageDropZone(
                    assetRef: imageBinding(at: 0),
                    placeholder: "Drop hero image here"
                )
                .frame(height: 250)
            }

            // Bullets section (exactly 3)
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Points (3 bullets)")
                    .font(.headline)
                    .foregroundColor(Theme.editorTextSecondary)

                ForEach(0..<3, id: \.self) { index in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.accent)
                            .frame(width: 24, height: 24)
                            .background(Theme.accent.opacity(0.2))
                            .clipShape(Circle())

                        TextField("Bullet point \(index + 1)...", text: bulletBinding(at: index))
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Text("This layout always shows exactly 3 bullet points.")
                    .font(.caption)
                    .foregroundColor(Theme.editorTextSecondary)
                    .padding(.top, 4)
            }

            Spacer()
        }
        .frame(maxWidth: 600, alignment: .leading)
    }

    // MARK: - Bindings

    private func imageBinding(at index: Int) -> Binding<AssetRef?> {
        Binding(
            get: {
                guard index < card.images.count else { return nil }
                return card.images[index]
            },
            set: { newValue in
                var images = card.images

                // Ensure array has at least one slot
                if images.isEmpty {
                    images.append(nil)
                }

                if index < images.count {
                    images[index] = newValue
                }
                card.images = images
            }
        )
    }

    private func bulletBinding(at index: Int) -> Binding<String> {
        Binding(
            get: {
                guard let bullets = card.bullets, index < bullets.count else { return "" }
                return bullets[index]
            },
            set: { newValue in
                var bullets = card.bullets ?? ["", "", ""]

                // Ensure array has exactly 3 slots
                while bullets.count < 3 {
                    bullets.append("")
                }

                bullets[index] = newValue
                card.bullets = bullets
            }
        )
    }
}

#Preview {
    FullBleedBulletsEditorView(card: .constant(Card(
        layout: .fullBleedBullets,
        bullets: ["First key point", "Second key point", "Third key point"]
    )))
    .padding()
    .frame(width: 500, height: 600)
}
