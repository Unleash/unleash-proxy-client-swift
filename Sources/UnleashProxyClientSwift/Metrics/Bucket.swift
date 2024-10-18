import Foundation

struct Bucket {
    private let clock: () -> Date
    var start: Date
    var stop: Date?
    var toggles: [String: ToggleMetrics] = [:]

    init(clock: @escaping () -> Date) {
        self.clock = clock
        start = clock()
    }

    mutating func closeBucket() {
        stop = clock()
    }

    func isEmpty() -> Bool {
        toggles.isEmpty
    }

    func toJson() -> [String: Any] {
        let mappedToggles = toggles.mapValues { $0.toJson() }
        return [
            "start": start.iso8601String(),
            "stop": stop?.iso8601String() ?? "",
            "toggles": mappedToggles
        ]
    }
}
