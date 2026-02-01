import Foundation

/// A single presenter card with layout-specific content.
///
/// Cards are the atomic unit of presenter notes. Each card:
/// - Uses one of 5 layout templates
/// - Contains text and/or images appropriate to that layout
/// - Is displayed one at a time in the overlay
struct Card: Identifiable, Codable, Equatable {
    /// Unique identifier for this card
    var id: UUID

    /// The layout template this card uses
    var layout: LayoutType

    /// Card title (used by titleBullets layout)
    var title: String?

    /// Notes text (used by imageTopNotes, twoImagesNotes layouts)
    var notes: String?

    /// Bullet points (used by titleBullets, fullBleedBullets layouts)
    var bullets: [String]?

    /// Caption text (used by grid2x2Caption layout)
    var caption: String?

    /// Image references for this card
    /// Array size matches layout.imageSlotCount
    /// nil elements represent empty slots
    var imageSlots: [AssetRef?]

    /// When this card was created
    var createdAt: Date

    /// When this card was last modified
    var updatedAt: Date

    // MARK: - Computed Properties

    /// Alias for imageSlots for convenience
    var images: [AssetRef?] {
        get { imageSlots }
        set {
            imageSlots = newValue
            updatedAt = Date()
        }
    }

    // MARK: - Initialization

    /// Creates a new card with the specified layout
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - layout: The layout template to use
    ///   - title: Optional title text
    ///   - notes: Optional notes text
    ///   - bullets: Optional bullet points
    ///   - caption: Optional caption text
    ///   - imageSlots: Optional image references (auto-sized if nil)
    init(
        id: UUID = UUID(),
        layout: LayoutType,
        title: String? = nil,
        notes: String? = nil,
        bullets: [String]? = nil,
        caption: String? = nil,
        imageSlots: [AssetRef?]? = nil
    ) {
        self.id = id
        self.layout = layout
        self.title = title
        self.notes = notes
        self.bullets = bullets
        self.caption = caption
        self.imageSlots = imageSlots ?? Array(repeating: nil, count: layout.imageSlotCount)
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Image Operations

    /// Sets an image in the specified slot
    /// - Parameters:
    ///   - asset: The asset reference (or nil to clear)
    ///   - index: The slot index (0-based)
    mutating func setImage(_ asset: AssetRef?, at index: Int) {
        guard index >= 0, index < imageSlots.count else { return }
        imageSlots[index] = asset
        updatedAt = Date()
    }

    /// Clears the image at the specified slot
    mutating func clearImage(at index: Int) {
        setImage(nil, at: index)
    }

    // MARK: - Bullet Operations

    /// Adds a bullet point to the card
    mutating func addBullet(_ text: String) {
        if bullets == nil {
            bullets = []
        }
        bullets?.append(text)
        updatedAt = Date()
    }

    /// Updates a bullet at the specified index
    mutating func updateBullet(_ text: String, at index: Int) {
        guard var currentBullets = bullets,
              index >= 0,
              index < currentBullets.count else { return }
        currentBullets[index] = text
        bullets = currentBullets
        updatedAt = Date()
    }

    /// Removes a bullet at the specified index
    mutating func removeBullet(at index: Int) {
        guard var currentBullets = bullets,
              index >= 0,
              index < currentBullets.count else { return }
        currentBullets.remove(at: index)
        bullets = currentBullets
        updatedAt = Date()
    }

    // MARK: - Layout Change

    /// Changes the card's layout, adjusting imageSlots as needed
    mutating func changeLayout(to newLayout: LayoutType) {
        let oldSlots = imageSlots
        let newSlotCount = newLayout.imageSlotCount

        // Create new slots array, preserving existing images where possible
        var newSlots = [AssetRef?](repeating: nil, count: newSlotCount)
        for index in 0..<min(oldSlots.count, newSlotCount) {
            newSlots[index] = oldSlots[index]
        }

        layout = newLayout
        imageSlots = newSlots
        updatedAt = Date()
    }
}
