import XCTest
import Combine
@testable import CleanArchitecture

@MainActor
final class CancelBagTest: XCTestCase {

    func test_store_appendsSubscription() {
        let bag = CancelBag()

        AnyCancellable {}.store(in: bag)
        AnyCancellable {}.store(in: bag)

        XCTAssertEqual(bag.subscriptions.count, 2)
    }

    func test_cancel_removesAndCancelsSubscriptions() {
        let bag = CancelBag()
        var cancelledCount = 0
        AnyCancellable { cancelledCount += 1 }.store(in: bag)

        XCTAssertEqual(bag.subscriptions.count, 1)

        bag.cancel()

        XCTAssertEqual(bag.subscriptions.count, 0)
        XCTAssertEqual(cancelledCount, 1) 
    }

    func test_storesTask() {
        let bag = CancelBag()

        Task {}.store(in: bag)

        XCTAssertEqual(bag.subscriptions.count, 1)
    }

    // MARK: - isEqual

    func test_isEqual_sameInstance_true() {
        let bag = CancelBag()
        XCTAssertTrue(bag.isEqual(to: bag))
    }

    func test_isEqual_differentInstances_false() {
        XCTAssertFalse(CancelBag().isEqual(to: CancelBag()))
    }

    func test_isEqual_equalToAny_matchesAnything() {
        let anyBag = CancelBag(equalToAny: true)

        XCTAssertTrue(anyBag.isEqual(to: CancelBag()))
        XCTAssertTrue(CancelBag().isEqual(to: anyBag))
    }
}
