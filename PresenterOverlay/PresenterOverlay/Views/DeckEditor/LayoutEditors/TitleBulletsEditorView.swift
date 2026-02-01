import SwiftUI

/// Editor for the Title + Bullets layout.
///
/// Fields:
/// - Title: Single line text field
/// - Bullets: Dynamic list of bullet points (add/remove/reorder)
struct TitleBulletsEditorView: View {
    @Binding var card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title field
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.headline)
                    .foregroundColor(Theme.textSecondary)

                TextField("Enter title...", text: titleBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
            }

            // Bullets section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Bullet Points")
                        .font(.headline)
                        .foregroundColor(Theme.textSecondary)

                    Spacer()

                    Button(action: addBullet) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(Theme.accent)
                    }
                    .buttonStyle(.plain)
                }

                if let bullets = card.bullets, !bullets.isEmpty {
                    ForEach(Array(bullets.enumerated()), id: \.offset) { index, bullet in
                        HStack(spacing: 12) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(Theme.textSecondary)
                                .font(.system(size: 12))

                            TextField("Bullet point...", text: bulletBinding(at: index))
                                .textFieldStyle(.roundedBorder)

                            Button(action: { removeBullet(at: index) }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    Text("No bullet points. Click + to add one.")
                        .foregroundColor(Theme.textSecondary)
                        .italic()
                        .padding(.vertical, 8)
                }
            }

            Spacer()
        }
        .frame(maxWidth: 600, alignment: .leading)
    }

    // MARK: - Bindings

    private var titleBinding: Binding<String> {
        Binding(
            get: { card.title ?? "" },
            set: { card.title = $0.isEmpty ? nil : $0 }
        )
    }

    private func bulletBinding(at index: Int) -> Binding<String> {
        Binding(
            get: {
                guard let bullets = card.bullets, index < bullets.count else { return "" }
                return bullets[index]
            },
            set: { newValue in
                var bullets = card.bullets ?? []
                if index < bullets.count {
                    bullets[index] = newValue
                    card.bullets = bullets
                }
            }
        )
    }

    // MARK: - Actions

    private func addBullet() {
        var bullets = card.bullets ?? []
        bullets.append("")
        card.bullets = bullets
    }

    private func removeBullet(at index: Int) {
        var bullets = card.bullets ?? []
        guard index < bullets.count else { return }
        bullets.remove(at: index)
        card.bullets = bullets.isEmpty ? nil : bullets
    }
}

#Preview {
    TitleBulletsEditorView(card: .constant(Card(
        layout: .titleBullets,
        title: "Key Points",
        bullets: ["First bullet", "Second bullet", "Third bullet"]
    )))
    .padding()
    .frame(width: 500, height: 400)
}
