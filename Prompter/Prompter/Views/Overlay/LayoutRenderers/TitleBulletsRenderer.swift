import SwiftUI

/// Renders the Title + Bullets layout in the overlay.
struct TitleBulletsRenderer: View {
    let card: Card
    let fontScale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            if let title = card.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: Theme.titleFontSize * fontScale, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }

            // Bullets
            if let bullets = card.bullets {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(bullets.enumerated()), id: \.offset) { _, bullet in
                        HStack(alignment: .top, spacing: 10) {
                            Text("•")
                                .font(.system(size: Theme.notesFontSize * fontScale, weight: .bold))
                                .foregroundColor(Theme.accent)
                                .accessibilityHidden(true)

                            Text(bullet)
                                .font(.system(size: Theme.notesFontSize * fontScale))
                                .foregroundColor(Theme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    TitleBulletsRenderer(
        card: Card(
            layout: .titleBullets,
            title: "Key Features",
            bullets: [
                "First important point to remember",
                "Second thing to mention",
                "Third key takeaway"
            ]
        ),
        fontScale: 1.0
    )
    .padding()
    .background(Theme.surfaceBackground)
}
