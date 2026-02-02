import XCTest
@testable import Prompter

final class OverlayFrameTests: XCTestCase {

    // MARK: - Initialization Tests

    func testOverlayFrameInitialization() {
        let frame = OverlayFrame(x: 100, y: 200, width: 400, height: 500)

        XCTAssertEqual(frame.x, 100)
        XCTAssertEqual(frame.y, 200)
        XCTAssertEqual(frame.width, 400)
        XCTAssertEqual(frame.height, 500)
    }

    func testDefaultFrame() {
        let defaultFrame = OverlayFrame.default

        XCTAssertEqual(defaultFrame.x, 100)
        XCTAssertEqual(defaultFrame.y, 100)
        XCTAssertEqual(defaultFrame.width, 400)
        XCTAssertEqual(defaultFrame.height, 500)
    }

    // MARK: - CGRect Conversion Tests

    func testToNSRect() {
        let frame = OverlayFrame(x: 50, y: 100, width: 300, height: 400)
        let rect = frame.toNSRect()

        XCTAssertEqual(rect.origin.x, 50)
        XCTAssertEqual(rect.origin.y, 100)
        XCTAssertEqual(rect.size.width, 300)
        XCTAssertEqual(rect.size.height, 400)
    }

    func testFromCGRect() {
        let cgRect = CGRect(x: 75, y: 125, width: 350, height: 450)
        let frame = OverlayFrame.from(cgRect)

        XCTAssertEqual(frame.x, 75)
        XCTAssertEqual(frame.y, 125)
        XCTAssertEqual(frame.width, 350)
        XCTAssertEqual(frame.height, 450)
    }

    func testRoundTrip() {
        let original = OverlayFrame(x: 123.5, y: 456.7, width: 789.1, height: 234.5)

        let rect = original.toNSRect()
        let roundTripped = OverlayFrame.from(rect)

        XCTAssertEqual(roundTripped.x, original.x)
        XCTAssertEqual(roundTripped.y, original.y)
        XCTAssertEqual(roundTripped.width, original.width)
        XCTAssertEqual(roundTripped.height, original.height)
    }

    // MARK: - Codable Tests

    func testEncodeDecode() throws {
        let original = OverlayFrame(x: 100, y: 200, width: 300, height: 400)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OverlayFrame.self, from: encoded)

        XCTAssertEqual(decoded, original)
    }

    // MARK: - Equatable Tests

    func testEquality() {
        let frame1 = OverlayFrame(x: 100, y: 200, width: 300, height: 400)
        let frame2 = OverlayFrame(x: 100, y: 200, width: 300, height: 400)
        let frame3 = OverlayFrame(x: 100, y: 200, width: 300, height: 500)

        XCTAssertEqual(frame1, frame2)
        XCTAssertNotEqual(frame1, frame3)
    }
}
