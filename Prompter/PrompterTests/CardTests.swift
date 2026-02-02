import XCTest
@testable import Prompter

final class CardTests: XCTestCase {

    // MARK: - Initialization Tests

    func testCardInitializationWithDefaults() {
        let card = Card(layout: .titleBullets)

        XCTAssertEqual(card.layout, .titleBullets)
        XCTAssertNil(card.title)
        XCTAssertNil(card.notes)
        XCTAssertNil(card.bullets)
        XCTAssertNil(card.caption)
        XCTAssertEqual(card.imageSlots.count, 0) // titleBullets has 0 image slots
    }

    func testCardInitializationWithValues() {
        let card = Card(
            layout: .titleBullets,
            title: "Test Title",
            bullets: ["Bullet 1", "Bullet 2"]
        )

        XCTAssertEqual(card.title, "Test Title")
        XCTAssertEqual(card.bullets?.count, 2)
        XCTAssertEqual(card.bullets?[0], "Bullet 1")
    }

    func testCardImageSlotsMatchLayout() {
        let imageTopNotesCard = Card(layout: .imageTopNotes)
        XCTAssertEqual(imageTopNotesCard.imageSlots.count, 1)

        let twoImagesCard = Card(layout: .twoImagesNotes)
        XCTAssertEqual(twoImagesCard.imageSlots.count, 2)

        let gridCard = Card(layout: .grid2x2Caption)
        XCTAssertEqual(gridCard.imageSlots.count, 4)

        let fullBleedCard = Card(layout: .fullBleedBullets)
        XCTAssertEqual(fullBleedCard.imageSlots.count, 1)
    }

    // MARK: - Bullet Operations Tests

    func testAddBullet() {
        var card = Card(layout: .titleBullets)
        XCTAssertNil(card.bullets)

        card.addBullet("First bullet")
        XCTAssertEqual(card.bullets?.count, 1)
        XCTAssertEqual(card.bullets?[0], "First bullet")

        card.addBullet("Second bullet")
        XCTAssertEqual(card.bullets?.count, 2)
    }

    func testUpdateBullet() {
        var card = Card(layout: .titleBullets, bullets: ["Original"])

        card.updateBullet("Updated", at: 0)
        XCTAssertEqual(card.bullets?[0], "Updated")
    }

    func testRemoveBullet() {
        var card = Card(layout: .titleBullets, bullets: ["A", "B", "C"])

        card.removeBullet(at: 1)
        XCTAssertEqual(card.bullets?.count, 2)
        XCTAssertEqual(card.bullets?[0], "A")
        XCTAssertEqual(card.bullets?[1], "C")
    }

    // MARK: - Image Operations Tests

    func testSetImage() {
        var card = Card(layout: .imageTopNotes)
        let asset = AssetRef(id: UUID(), filename: "test.png")

        card.setImage(asset, at: 0)
        XCTAssertNotNil(card.imageSlots[0])
        XCTAssertEqual(card.imageSlots[0]?.filename, "test.png")
    }

    func testClearImage() {
        let asset = AssetRef(id: UUID(), filename: "test.png")
        var card = Card(layout: .imageTopNotes, imageSlots: [asset])

        card.clearImage(at: 0)
        XCTAssertNil(card.imageSlots[0])
    }

    // MARK: - Layout Change Tests

    func testChangeLayout() {
        var card = Card(layout: .titleBullets)
        XCTAssertEqual(card.imageSlots.count, 0)

        card.changeLayout(to: .grid2x2Caption)
        XCTAssertEqual(card.layout, .grid2x2Caption)
        XCTAssertEqual(card.imageSlots.count, 4)
    }

    func testChangeLayoutPreservesImages() {
        let asset = AssetRef(id: UUID(), filename: "test.png")
        var card = Card(layout: .grid2x2Caption, imageSlots: [asset, nil, nil, nil])

        card.changeLayout(to: .imageTopNotes)
        XCTAssertEqual(card.imageSlots.count, 1)
        XCTAssertEqual(card.imageSlots[0]?.filename, "test.png")
    }

    // MARK: - Images Computed Property Tests

    func testImagesComputedProperty() {
        let asset = AssetRef(id: UUID(), filename: "test.png")
        var card = Card(layout: .imageTopNotes, imageSlots: [asset])

        // Test getter
        XCTAssertEqual(card.images.count, 1)
        XCTAssertEqual(card.images[0]?.filename, "test.png")

        // Test setter
        let newAsset = AssetRef(id: UUID(), filename: "new.png")
        card.images = [newAsset]
        XCTAssertEqual(card.imageSlots[0]?.filename, "new.png")
    }

    // MARK: - Codable Tests

    func testCardEncodeDecode() throws {
        let original = Card(
            layout: .titleBullets,
            title: "Test",
            bullets: ["A", "B"]
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Card.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.layout, original.layout)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.bullets, original.bullets)
    }
}
