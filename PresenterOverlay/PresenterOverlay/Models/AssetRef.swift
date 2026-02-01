import Foundation

/// Reference to an image asset stored on disk.
///
/// When users drag images into cards, we:
/// 1. Copy the image to our Assets folder
/// 2. Rename it using a UUID
/// 3. Store this reference in the card
///
/// This ensures decks are self-contained and won't break
/// if the original image is moved or deleted.
struct AssetRef: Identifiable, Codable, Equatable {
    /// Unique identifier for this asset
    let id: UUID

    /// Filename in the Assets folder (e.g., "abc123.png")
    let filename: String

    /// Original filename before import (for display purposes)
    let originalName: String?

    /// When this asset was imported
    let createdAt: Date

    // MARK: - Computed Properties

    /// File extension (e.g., "png", "jpg")
    var fileExtension: String {
        (filename as NSString).pathExtension
    }

    // MARK: - Initialization

    /// Creates a new asset reference
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - filename: Name of file in Assets folder
    ///   - originalName: Original filename before import
    ///   - createdAt: Import timestamp (defaults to now)
    init(
        id: UUID = UUID(),
        filename: String,
        originalName: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.filename = filename
        self.originalName = originalName
        self.createdAt = createdAt
    }
}
