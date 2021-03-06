import XCTest
import Nimble
import ReactiveSwift
import enum Result.NoError
@testable import ReactiveFeedback

class SystemTests: XCTestCase {

    func test_emits_initial() {
        let initial = "initial"
        let feedback = Feedback<String, String> { state in
            return SignalProducer(value: "_a")
        }
        let system = SignalProducer<String, NoError>.system(
            initial: initial,
            reduce: { (state: String, event: String) in
                return state + event
            },
            feedbacks: feedback)
        let result = system.first()?.value

        expect(result) == initial
    }

    func test_reducer_with_one_feedback_loop() {
        let feedback = Feedback<String, String> { state in
            return SignalProducer(value: "_a")
        }
        let system = SignalProducer<String, NoError>.system(
            initial: "initial",
            reduce: { (state: String, event: String) in
                return state + event
            },
            feedbacks: feedback)

        var result: [String]!
        system.take(first: 3)
            .collect()
            .startWithValues {
                result = $0
            }

        let expected = [
            "initial",
            "initial_a",
            "initial_a_a"
        ]
        expect(result).toEventually(equal(expected))
    }

    func test_reduce_with_two_immediate_feedback_loops() {
        let feedback1 = Feedback<String, String> { state in
            return SignalProducer(value: "_a")
        }
        let feedback2 = Feedback<String, String> { state in
            return SignalProducer(value: "_b")
        }
        let system = SignalProducer<String, NoError>.system(
            initial: "initial",
            reduce: { (state: String, event: String) in
                return state + event
            },
            feedbacks: feedback1, feedback2)

        var result: [String]!
        system.take(first: 5)
            .collect()
            .startWithValues {
                result = $0
            }

        let expected = [
            "initial",
            "initial_a",
            "initial_a_b",
            "initial_a_b_a",
            "initial_a_b_a_b",
        ]
        expect(result).toEventually(equal(expected))
    }

    func test_reduce_with_async_feedback_loop() {
        let feedback = Feedback<String, String> { state -> SignalProducer<String, NoError> in
            if state == "initial" {
                return SignalProducer(value: "_a")
                    .delay(0.1, on: QueueScheduler.main)
            }
            if state == "initial_a" {
                return SignalProducer(value: "_b")
            }
            if state == "initial_a_b" {
                return SignalProducer(value: "_c")
            }
            return SignalProducer.empty
        }
        let system = SignalProducer<String, NoError>.system(
            initial: "initial",
            reduce: { (state: String, event: String) in
                return state + event
            },
            feedbacks: feedback)

        var result: [String]!
        system.take(first: 4)
            .collect()
            .startWithValues {
                result = $0
            }

        let expected = [
            "initial",
            "initial_a",
            "initial_a_b",
            "initial_a_b_c"
        ]
        expect(result).toEventually(equal(expected))
    }
}
