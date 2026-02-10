import AppKit
import Foundation
import os

private let logger = Logger(subsystem: "com.tookes.Prompter", category: "Assets")

/// Manages image assets stored on disk.
///
/// Assets are stored in ~/Library/Application Support/Prompter/Assets/
/// with UUID-based filenames to ensure uniqueness.
///
/// Responsibilities:
/// - Import images from file URLs or data
/// - Store images in the assets directory
/// - Load images from asset references
/// - Delete unused assets
@MainActor
final class AssetManager {

    // MARK: - Singleton

    static let shared = AssetManager()

    // MARK: - Properties

    /// Base directory for all app data
    private let appSupportURL: URL

    /// Directory for storing image assets
    private let assetsURL: URL

    /// In-memory cache for loaded images
    private var imageCache: [UUID: NSImage] = [:]

    /// Maximum cache size (number of images)
    private let maxCacheSize = 50

    // MARK: - Initialization

    private init() {
        // Get Application Support directory
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        appSupportURL = appSupport.appendingPathComponent("Prompter", isDirectory: true)
        assetsURL = appSupportURL.appendingPathComponent("Assets", isDirectory: true)

        // Create directories if needed
        try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: assetsURL, withIntermediateDirectories: true)
    }

    // MARK: - Import

    /// Imports an image from a file URL (synchronous - for compatibility)
    /// - Parameter url: The source file URL
    /// - Returns: An AssetRef if successful, nil otherwise
    func importImage(from url: URL) -> AssetRef? {
        guard let imageData = try? Data(contentsOf: url) else {
            logger.error("Failed to read image data from \(url)")
            return nil
        }

        // Determine file extension
        let ext = url.pathExtension.lowercased()
        let validExtensions = ["png", "jpg", "jpeg", "heic", "gif", "webp", "tiff"]
        let fileExtension = validExtensions.contains(ext) ? ext : "png"

        return importImage(data: imageData, extension: fileExtension)
    }

    /// Imports an image from a file URL asynchronously
    /// - Parameter url: The source file URL
    /// - Returns: An AssetRef if successful, nil otherwise
    func importImageAsync(from url: URL) async -> AssetRef? {
        let ext = url.pathExtension.lowercased()
        let validExtensions = ["png", "jpg", "jpeg", "heic", "gif", "webp", "tiff"]
        let fileExtension = validExtensions.contains(ext) ? ext : "png"

        // Read file data on background thread
        let imageData: Data? = await Task.detached(priority: .userInitiated) {
            try? Data(contentsOf: url)
        }.value

        guard let data = imageData else {
            logger.error("Failed to read image data from \(url)")
            return nil
        }

        return await importImageAsync(data: data, extension: fileExtension)
    }

    /// Imports an image from raw data (synchronous - for compatibility)
    /// - Parameters:
    ///   - data: The image data
    ///   - extension: The file extension (defaults to png)
    /// - Returns: An AssetRef if successful, nil otherwise
    func importImage(data: Data, extension ext: String = "png") -> AssetRef? {
        // Generate unique ID
        let id = UUID()
        let filename = "\(id.uuidString).\(ext)"
        let destinationURL = assetsURL.appendingPathComponent(filename)

        do {
            try data.write(to: destinationURL)
            logger.debug("Imported image as \(filename)")
            return AssetRef(id: id, filename: filename)
        } catch {
            logger.error("Failed to write image: \(error.localizedDescription)")
            return nil
        }
    }

    /// Imports an image from raw data asynchronously
    /// - Parameters:
    ///   - data: The image data
    ///   - extension: The file extension (defaults to png)
    /// - Returns: An AssetRef if successful, nil otherwise
    func importImageAsync(data: Data, extension ext: String = "png") async -> AssetRef? {
        let id = UUID()
        let filename = "\(id.uuidString).\(ext)"
        let destinationURL = assetsURL.appendingPathComponent(filename)

        // Write file on background thread
        let success = await Task.detached(priority: .userInitiated) {
            do {
                try data.write(to: destinationURL)
                return true
            } catch {
                logger.error("Failed to write image: \(error.localizedDescription)")
                return false
            }
        }.value

        if success {
            logger.debug("Imported image as \(filename)")
            return AssetRef(id: id, filename: filename)
        }
        return nil
    }

    // MARK: - Load

    /// Loads an image for the given asset reference (synchronous - for compatibility)
    /// - Parameter assetRef: The asset reference
    /// - Returns: The loaded NSImage, or nil if not found
    func loadImage(for assetRef: AssetRef) -> NSImage? {
        // Check cache first
        if let cached = imageCache[assetRef.id] {
            return cached
        }

        // Load from disk
        let fileURL = assetsURL.appendingPathComponent(assetRef.filename)

        guard let image = NSImage(contentsOf: fileURL) else {
            logger.error("Failed to load image from \(fileURL)")
            return nil
        }

        // Add to cache (with eviction if needed)
        addToCache(id: assetRef.id, image: image)

        return image
    }

    /// Loads an image for the given asset reference asynchronously
    /// - Parameter assetRef: The asset reference
    /// - Returns: The loaded NSImage, or nil if not found
    func loadImageAsync(for assetRef: AssetRef) async -> NSImage? {
        // Check cache first (on main actor)
        if let cached = imageCache[assetRef.id] {
            return cached
        }

        let fileURL = assetsURL.appendingPathComponent(assetRef.filename)

        // Load and decode image on background thread
        let image: NSImage? = await Task.detached(priority: .userInitiated) {
            NSImage(contentsOf: fileURL)
        }.value

        guard let loadedImage = image else {
            logger.error("Failed to load image from \(fileURL)")
            return nil
        }

        // Add to cache (on main actor)
        addToCache(id: assetRef.id, image: loadedImage)

        return loadedImage
    }

    /// Returns the file URL for an asset (useful for direct file access)
    func fileURL(for assetRef: AssetRef) -> URL {
        return assetsURL.appendingPathComponent(assetRef.filename)
    }

    // MARK: - Delete

    /// Deletes an asset from disk
    /// - Parameter assetRef: The asset to delete
    func deleteAsset(_ assetRef: AssetRef) {
        let fileURL = assetsURL.appendingPathComponent(assetRef.filename)

        do {
            try FileManager.default.removeItem(at: fileURL)
            imageCache.removeValue(forKey: assetRef.id)
            logger.info("Deleted asset \(assetRef.filename)")
        } catch {
            logger.error("Failed to delete asset: \(error.localizedDescription)")
        }
    }

    /// Deletes all assets not referenced in the given set
    /// - Parameter referencedAssets: Set of asset IDs that are still in use
    func cleanupUnusedAssets(referencedAssets: Set<UUID>) {
        let fileManager = FileManager.default

        guard let files = try? fileManager.contentsOfDirectory(at: assetsURL, includingPropertiesForKeys: nil) else {
            return
        }

        for fileURL in files {
            let filename = fileURL.lastPathComponent
            // Extract UUID from filename (format: UUID.ext)
            let uuidString = filename.components(separatedBy: ".").first ?? ""

            if let uuid = UUID(uuidString: uuidString), !referencedAssets.contains(uuid) {
                try? fileManager.removeItem(at: fileURL)
                imageCache.removeValue(forKey: uuid)
                logger.debug("Cleaned up unused asset \(filename)")
            }
        }
    }

    // MARK: - Cache Management

    private func addToCache(id: UUID, image: NSImage) {
        // Simple FIFO eviction when cache is full
        if imageCache.count >= maxCacheSize {
            if let firstKey = imageCache.keys.first {
                imageCache.removeValue(forKey: firstKey)
            }
        }
        imageCache[id] = image
    }

    /// Clears the in-memory image cache
    func clearCache() {
        imageCache.removeAll()
    }

    // MARK: - Utility

    /// Returns the total size of all assets in bytes
    func totalAssetSize() -> Int64 {
        let fileManager = FileManager.default

        guard let files = try? fileManager.contentsOfDirectory(at: assetsURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        return files.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }
}
