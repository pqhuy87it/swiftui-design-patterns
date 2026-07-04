import XCTest
import Combine
@testable import CleanArchitecture

@MainActor
final class StoreTest: XCTestCase {

    func test_subscript_get_returnsValueAtKeyPath() {
        let store = Store<AppState>(AppState())

        XCTAssertTrue(store[\.system.isActive]) // default = true
    }

    func test_subscript_set_updatesValue() {
        let store = Store<AppState>(AppState())

        store[\.system.isActive] = false

        XCTAssertFalse(store.value.system.isActive)
    }

    func test_subscript_set_sameValue_doesNotEmit() {
        let store = Store<AppState>(AppState())
        var emissions = 0
        let cancellable = store.sink { _ in emissions += 1 }

        store[\.system.isActive] = true

        XCTAssertEqual(emissions, 1)
        cancellable.cancel()
    }

    func test_subscript_set_newValue_emits() {
        let store = Store<AppState>(AppState())
        var emissions = 0
        let cancellable = store.sink { _ in emissions += 1 }

        store[\.system.isActive] = false

        XCTAssertEqual(emissions, 2)
        cancellable.cancel()
    }

    func test_bulkUpdate_appliesAllChangesAndEmitsOnce() {
        let store = Store<AppState>(AppState())
        var emissions = 0
        let cancellable = store.sink { _ in emissions += 1 }

        store.bulkUpdate {
            $0.system.isActive = false
            $0.system.keyboardHeight = 100
        }

        XCTAssertFalse(store.value.system.isActive)
        XCTAssertEqual(store.value.system.keyboardHeight, 100)
        XCTAssertEqual(emissions, 2)
        cancellable.cancel()
    }

    func test_updates_removesDuplicates() {
        let store = Store<AppState>(AppState())
        var received: [Bool] = []
        let cancellable = store.updates(for: \.system.isActive).sink { received.append($0) }

        store[\.system.isActive] = false                       // emit false
        store.bulkUpdate { $0.system.keyboardHeight = 50 }
        store[\.system.isActive] = true                        // emit true

        XCTAssertEqual(received, [true, false, true])
        cancellable.cancel()
    }
}
