import XCTest
import SwiftUI
@testable import CleanArchitecture

@MainActor
final class LoadableTest: XCTestCase {

    // MARK: - value / error

    func test_value_returnsUnderlyingForLoadedAndLoading() {
        XCTAssertEqual(Loadable.loaded(5).value, 5)
        XCTAssertEqual(Loadable<Int>.isLoading(last: 3, cancelBag: CancelBag()).value, 3)
        XCTAssertNil(Loadable<Int>.notRequested.value)
        XCTAssertNil(Loadable<Int>.failed(TestError()).value)
    }

    func test_error_returnsErrorOnlyForFailed() {
        XCTAssertNotNil(Loadable<Int>.failed(TestError()).error)
        XCTAssertNil(Loadable.loaded(1).error)
        XCTAssertNil(Loadable<Int>.notRequested.error)
    }

    // MARK: - setIsLoading / cancelLoading

    func test_setIsLoading_keepsLastValue() {
        var loadable = Loadable.loaded(7)
        loadable.setIsLoading(cancelBag: CancelBag())

        guard case .isLoading = loadable else { return XCTFail("expected .isLoading") }
        XCTAssertEqual(loadable.value, 7)
    }

    func test_cancelLoading_withLastValue_becomesLoaded() {
        var loadable = Loadable<Int>.isLoading(last: 9, cancelBag: CancelBag())
        loadable.cancelLoading()

        XCTAssertEqual(loadable, .loaded(9))
    }

    func test_cancelLoading_withoutLastValue_becomesFailed() {
        var loadable = Loadable<Int>.isLoading(last: nil, cancelBag: CancelBag())
        loadable.cancelLoading()

        XCTAssertNotNil(loadable.error)
    }

    // MARK: - map

    func test_map_transformsLoadedValue() {
        let mapped = Loadable.loaded(5).map { "value=\($0)" }
        XCTAssertEqual(mapped, .loaded("value=5"))
    }

    func test_map_preservesNotRequestedAndFailed() {
        XCTAssertEqual(Loadable<Int>.notRequested.map { "\($0)" }, .notRequested)
        XCTAssertNotNil(Loadable<Int>.failed(TestError()).map { "\($0)" }.error)
    }

    // MARK: - Equatable

    func test_equatable() {
        XCTAssertEqual(Loadable<Int>.notRequested, .notRequested)
        XCTAssertEqual(Loadable.loaded(1), .loaded(1))
        XCTAssertNotEqual(Loadable.loaded(1), .loaded(2))
        XCTAssertNotEqual(Loadable<Int>.notRequested, .loaded(1))
    }

    // MARK: - LoadableSubject.load

    func test_load_success_setsLoaded() async {
        let box = Box<Loadable<Int>>(.notRequested)
        let binding = Binding(get: { box.value }, set: { box.value = $0 })

        binding.load { 42 }
        await poll { box.value.value == 42 }

        XCTAssertEqual(box.value, .loaded(42))
    }

    func test_load_failure_setsFailed() async {
        let box = Box<Loadable<Int>>(.notRequested)
        let binding = Binding(get: { box.value }, set: { box.value = $0 })

        binding.load { throw TestError() }
        await poll { box.value.error != nil }

        XCTAssertNotNil(box.value.error)
    }

    // MARK: - Helpers

    private final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    private func poll(timeout: TimeInterval = 1, until condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() >= deadline { return XCTFail("poll timed out") }
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
    }
}
