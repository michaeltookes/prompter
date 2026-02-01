import XCTest
@testable import PresenterOverlay

final class LayoutTypeTests: XCTestCase {

    // MARK: - Display Name Tests

    func testDisplayNames() {
        XCTAssertEqual(LayoutType.titleBullets.displayName, "Title + Bullets")
        XCTAssertEqual(LayoutType.imageTopNotes.displayName, "Image + Notes")
        XCTAssertEqual(LayoutType.twoImagesNotes.displayName, "Two Images + Notes")
        XCTAssertEqual(LayoutType.grid2x2Caption.displayName, "2×2 Grid + Caption")
        XCTAssertEqual(LayoutType.fullBleedBullets.displayName, "Full Image + 3 Bullets")
    }

    // MARK: - Image Slot Count Tests

    func testImageSlotCounts() {
        XCTAssertEqual(LayoutType.titleBullets.imageSlotCount, 0)
        XCTAssertEqual(LayoutType.imageTopNotes.imageSlotCount, 1)
        XCTAssertEqual(LayoutType.twoImagesNotes.imageSlotCount, 2)
        XCTAssertEqual(LayoutType.grid2x2Caption.imageSlotCount, 4)
        XCTAssertEqual(LayoutType.fullBleedBullets.imageSlotCount, 1)
    }

    // MARK: - Max Bullet Count Tests

    func testMaxBulletCounts() {
        XCTAssertNil(LayoutType.titleBullets.maxBulletCount) // Variable
        XCTAssertNil(LayoutType.imageTopNotes.maxBulletCount)
        XCTAssertNil(LayoutType.twoImagesNotes.maxBulletCount)
        XCTAssertNil(LayoutType.grid2x2Caption.maxBulletCount)
        XCTAssertEqual(LayoutType.fullBleedBullets.maxBulletCount, 3)
    }

    // MARK: - Has Fields Tests

    func testHasTitle() {
        XCTAssertTrue(LayoutType.titleBullets.hasTitle)
        XCTAssertFalse(LayoutType.imageTopNotes.hasTitle)
        XCTAssertFalse(LayoutType.twoImagesNotes.hasTitle)
        XCTAssertFalse(LayoutType.grid2x2Caption.hasTitle)
        XCTAssertFalse(LayoutType.fullBleedBullets.hasTitle)
    }

    func testHasNotes() {
        XCTAssertFalse(LayoutType.titleBullets.hasNotes)
        XCTAssertTrue(LayoutType.imageTopNotes.hasNotes)
        XCTAssertTrue(LayoutType.twoImagesNotes.hasNotes)
        XCTAssertFalse(LayoutType.grid2x2Caption.hasNotes)
        XCTAssertFalse(LayoutType.fullBleedBullets.hasNotes)
    }

    func testHasCaption() {
        XCTAssertFalse(LayoutType.titleBullets.hasCaption)
        XCTAssertFalse(LayoutType.imageTopNotes.hasCaption)
        XCTAssertFalse(LayoutType.twoImagesNotes.hasCaption)
        XCTAssertTrue(LayoutType.grid2x2Caption.hasCaption)
        XCTAssertFalse(LayoutType.fullBleedBullets.hasCaption)
    }

    func testHasBullets() {
        XCTAssertTrue(LayoutType.titleBullets.hasBullets)
        XCTAssertFalse(LayoutType.imageTopNotes.hasBullets)
        XCTAssertFalse(LayoutType.twoImagesNotes.hasBullets)
        XCTAssertFalse(LayoutType.grid2x2Caption.hasBullets)
        XCTAssertTrue(LayoutType.fullBleedBullets.hasBullets)
    }

    // MARK: - Icon Name Tests

    func testIconNames() {
        XCTAssertEqual(LayoutType.titleBullets.iconName, "text.alignleft")
        XCTAssertEqual(LayoutType.imageTopNotes.iconName, "photo.on.rectangle")
        XCTAssertEqual(LayoutType.twoImagesNotes.iconName, "rectangle.split.2x1")
        XCTAssertEqual(LayoutType.grid2x2Caption.iconName, "square.grid.2x2")
        XCTAssertEqual(LayoutType.fullBleedBullets.iconName, "photo.fill")
    }

    // MARK: - Identifiable Tests

    func testIdentifiable() {
        XCTAssertEqual(LayoutType.titleBullets.id, "TITLE_BULLETS")
        XCTAssertEqual(LayoutType.fullBleedBullets.id, "FULL_BLEED_IMAGE_3_BULLETS")
    }

    // MARK: - All Cases Tests

    func testAllCases() {
        XCTAssertEqual(LayoutType.allCases.count, 5)
    }

    // MARK: - Codable Tests

    func testEncodeDecode() throws {
        let layout = LayoutType.grid2x2Caption

        let encoded = try JSONEncoder().encode(layout)
        let decoded = try JSONDecoder().decode(LayoutType.self, from: encoded)

        XCTAssertEqual(decoded, layout)
    }
}
