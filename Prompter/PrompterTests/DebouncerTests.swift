import XCTest
@testable import Prompter

final class DebouncerTests: XCTestCase {

    // MARK: - Debounce Tests

    func testDebounceExecutesAfterDelay() {
        let expectation = expectation(description: "Debounced action executes")
        let debouncer = Debouncer(delay: 0.1)

        var executed = false
        debouncer.debounce {
            executed = true
            expectation.fulfill()
        }

        // Should not execute immediately
        XCTAssertFalse(executed)

        wait(for: [expectation], timeout: 0.5)
        XCTAssertTrue(executed)
    }

    func testDebounceCoalescesMultipleCalls() {
        let expectation = expectation(description: "Debounced action executes once")
        let debouncer = Debouncer(delay: 0.1)

        var executionCount = 0
        for _ in 0..<5 {
            debouncer.debounce {
                executionCount += 1
            }
        }

        // Wait for debounce to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(executionCount, 1, "Should only execute once despite multiple calls")
    }

    func testDebounceExecutesLastAction() {
        let expectation = expectation(description: "Last action executes")
        let debouncer = Debouncer(delay: 0.1)

        var result = ""
        debouncer.debounce { result = "first" }
        debouncer.debounce { result = "second" }
        debouncer.debounce { result = "third" }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(result, "third", "Should execute the last debounced action")
    }

    // MARK: - Cancel Tests

    func testCancelPreventsExecution() {
        let expectation = expectation(description: "Wait for potential execution")
        expectation.isInverted = true // We expect this NOT to be fulfilled
        let debouncer = Debouncer(delay: 0.1)

        var executed = false
        debouncer.debounce {
            executed = true
            expectation.fulfill()
        }

        debouncer.cancel()

        // Wait longer than the debounce delay
        wait(for: [expectation], timeout: 0.2)
        XCTAssertFalse(executed, "Cancelled action should not execute")
    }

    func testCancelAfterExecutionDoesNothing() {
        let expectation = expectation(description: "Action executes")
        let debouncer = Debouncer(delay: 0.05)

        var executed = false
        debouncer.debounce {
            executed = true
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.2)

        // Cancel after execution - should not cause any issues
        debouncer.cancel()
        XCTAssertTrue(executed)
    }

    // MARK: - Flush Tests

    func testFlushExecutesImmediately() {
        let debouncer = Debouncer(delay: 1.0) // Long delay

        var executed = false
        debouncer.debounce {
            executed = true
        }

        XCTAssertFalse(executed, "Should not execute before flush")

        debouncer.flush()

        XCTAssertTrue(executed, "Should execute immediately after flush")
    }

    func testFlushWithNoPendingAction() {
        let debouncer = Debouncer(delay: 0.1)

        // Should not crash when flushing with no pending action
        debouncer.flush()
    }

    func testFlushAfterCancelDoesNotExecute() {
        let debouncer = Debouncer(delay: 1.0)

        var executed = false
        debouncer.debounce {
            executed = true
        }

        debouncer.cancel()
        debouncer.flush()

        XCTAssertFalse(executed, "Cancelled action should not execute on flush")
    }

    // MARK: - Custom Queue Tests

    func testCustomQueue() {
        let expectation = expectation(description: "Executes on custom queue")
        let customQueue = DispatchQueue(label: "test.queue")
        let debouncer = Debouncer(delay: 0.1, queue: customQueue)

        var executedOnCustomQueue = false
        debouncer.debounce {
            // Check we're on the custom queue by label
            let currentLabel = String(cString: __dispatch_queue_get_label(nil), encoding: .utf8)
            executedOnCustomQueue = currentLabel == "test.queue"
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
        XCTAssertTrue(executedOnCustomQueue)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentDebouncing() {
        let expectation = expectation(description: "Concurrent debouncing completes")
        let debouncer = Debouncer(delay: 0.05)

        let iterations = 100
        var finalValue = 0

        let group = DispatchGroup()

        for i in 0..<iterations {
            group.enter()
            DispatchQueue.global().async {
                debouncer.debounce {
                    finalValue = i
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // Wait for debounce to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
        // We can't predict which value wins, but it should be one of them
        XCTAssertTrue(finalValue >= 0 && finalValue < iterations)
    }
}
