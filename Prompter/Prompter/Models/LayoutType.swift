import Foundation

/// Defines the 5 available card layout templates.
///
/// Each layout provides a pre-designed arrangement of text and images
/// optimized for quick glancing during presentations.
enum LayoutType: String, Codable, CaseIterable, Identifiable, Equatable {
    /// Title at top with bullet points below
    /// - Image slots: 0
    /// - Best for: Talking points, key messages
    case titleBullets = "TITLE_BULLETS"

    /// Single image at top with notes below
    /// - Image slots: 1
    /// - Best for: Screenshots with context
    case imageTopNotes = "IMAGE_TOP_NOTES"

    /// Two images side-by-side with notes below
    /// - Image slots: 2
    /// - Best for: Before/after, comparisons
    case twoImagesNotes = "TWO_IMAGES_NOTES"

    /// 2x2 grid of images with caption below
    /// - Image slots: 4
    /// - Best for: Process flows, multiple screens
    case grid2x2Caption = "GRID_2X2_CAPTION"

    /// Full-bleed image with 3 bullet points below
    /// - Image slots: 1
    /// - Best for: Hero images with key takeaways
    case fullBleedBullets = "FULL_BLEED_IMAGE_3_BULLETS"

    // MARK: - Identifiable

    var id: String { rawValue }

    // MARK: - Display Properties

    /// Human-readable display name for the layout
    var displayName: String {
        switch self {
        case .titleBullets:     return "Title + Bullets"
        case .imageTopNotes:    return "Image + Notes"
        case .twoImagesNotes:   return "Two Images + Notes"
        case .grid2x2Caption:   return "2×2 Grid + Caption"
        case .fullBleedBullets: return "Full Image + 3 Bullets"
        }
    }

    /// SF Symbol icon name for the layout
    var iconName: String {
        switch self {
        case .titleBullets:     return "text.alignleft"
        case .imageTopNotes:    return "photo.on.rectangle"
        case .twoImagesNotes:   return "rectangle.split.2x1"
        case .grid2x2Caption:   return "square.grid.2x2"
        case .fullBleedBullets: return "photo.fill"
        }
    }

    // MARK: - Layout Properties

    /// Number of image slots available in this layout
    var imageSlotCount: Int {
        switch self {
        case .titleBullets:     return 0
        case .imageTopNotes:    return 1
        case .twoImagesNotes:   return 2
        case .grid2x2Caption:   return 4
        case .fullBleedBullets: return 1
        }
    }

    /// Maximum number of bullet points for this layout
    /// Returns nil if bullets aren't supported
    var maxBulletCount: Int? {
        switch self {
        case .titleBullets:     return nil  // Variable, user decides
        case .fullBleedBullets: return 3    // Fixed at 3
        default:                return nil
        }
    }

    /// Whether this layout has a title field
    var hasTitle: Bool {
        switch self {
        case .titleBullets: return true
        default:            return false
        }
    }

    /// Whether this layout has a notes field
    var hasNotes: Bool {
        switch self {
        case .imageTopNotes:    return true
        case .twoImagesNotes:   return true
        default:                return false
        }
    }

    /// Whether this layout has a caption field
    var hasCaption: Bool {
        switch self {
        case .grid2x2Caption: return true
        default:              return false
        }
    }

    /// Whether this layout has bullet points
    var hasBullets: Bool {
        switch self {
        case .titleBullets:     return true
        case .fullBleedBullets: return true
        default:                return false
        }
    }
}
