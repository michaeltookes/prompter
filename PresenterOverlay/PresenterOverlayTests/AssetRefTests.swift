import XCTest
@testable import PresenterOverlay

final class AssetRefTests: XCTestCase {

    // MARK: - Initialization Tests

    func testAssetRefInitialization() {
        let id = UUID()
        let asset = AssetRef(id: id, filename: "test-image.png")

        XCTAssertEqual(asset.id, id)
        XCTAssertEqual(asset.filename, "test-image.png")
    }

    func testAssetRefInitializationWithOriginalName() {
        let asset = AssetRef(
            filename: "abc123.png",
            originalName: "my-photo.png"
        )

        XCTAssertEqual(asset.originalName, "my-photo.png")
        XCTAssertEqual(asset.filename, "abc123.png")
    }

    func testAssetRefInitializationWithCreatedAt() {
        let date = Date()
        let asset = AssetRef(filename: "test.png", createdAt: date)

        XCTAssertEqual(asset.createdAt, date)
    }

    // MARK: - File Extension Tests

    func testFileExtension() {
        let pngAsset = AssetRef(id: UUID(), filename: "image.png")
        let jpegAsset = AssetRef(id: UUID(), filename: "photo.jpeg")
        let noExtAsset = AssetRef(id: UUID(), filename: "noextension")

        XCTAssertEqual(pngAsset.fileExtension, "png")
        XCTAssertEqual(jpegAsset.fileExtension, "jpeg")
        XCTAssertEqual(noExtAsset.fileExtension, "")
    }

    // MARK: - Codable Tests

    func testEncodeDecode() throws {
        let original = AssetRef(id: UUID(), filename: "test.png", originalName: "original.png")

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AssetRef.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.filename, original.filename)
        XCTAssertEqual(decoded.originalName, original.originalName)
    }

    // MARK: - Equatable Tests

    func testEquality() {
        let id = UUID()
        let date = Date()
        let asset1 = AssetRef(id: id, filename: "test.png", originalName: nil, createdAt: date)
        let asset2 = AssetRef(id: id, filename: "test.png", originalName: nil, createdAt: date)
        let asset3 = AssetRef(id: UUID(), filename: "test.png")

        XCTAssertEqual(asset1, asset2)
        XCTAssertNotEqual(asset1, asset3)
    }
}
