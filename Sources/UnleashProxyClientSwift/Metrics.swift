import Foundation
import SwiftEventBus

extension Date {
    func iso8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

struct ToggleMetrics {
    var yes: Int = 0
    var no: Int = 0
    var variants: [String: Int] = [:]

    func toJson() -> [String: Any] {
        ["yes": yes, "no": no, "variants": variants]
    }
}

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

struct MetricsPayload {
    let appName: String
    let instanceId: String
    let bucket: Bucket

    func toJson() -> [String: Any] {
        [
            "appName": appName,
            "instanceId": instanceId,
            "bucket": bucket.toJson()
        ]
    }
}

public class Metrics {
    let appName: String
    let metricsInterval: TimeInterval
    let clientKey: String
    let poster: (URLRequest) async throws -> (Data, URLResponse)
    let clock: () -> Date
    var disableMetrics: Bool
    var timer: Timer?
    var bucket: Bucket
    let url: URL

    init(appName: String,
         metricsInterval: TimeInterval,
         clock: @escaping () -> Date,
         disableMetrics: Bool = false,
         poster: @escaping (URLRequest) async throws -> (Data, URLResponse),
         url: URL,
         clientKey: String) {
        self.appName = appName
        self.metricsInterval = metricsInterval
        self.clock = clock
        self.disableMetrics = disableMetrics
        self.poster = poster
        self.url = url
        self.clientKey = clientKey
        self.bucket = Bucket(clock: clock)
    }

    func start() {
        guard !disableMetrics else { return }

        timer = Timer.scheduledTimer(withTimeInterval: metricsInterval, repeats: true) { _ in
            Task {
                await self.sendMetrics()
            }
        }
    }

    func count(name: String, enabled: Bool) {
        guard !disableMetrics else { return }

        var toggle = bucket.toggles[name] ?? ToggleMetrics()
        if enabled {
            toggle.yes += 1
        } else {
            toggle.no += 1
        }
        bucket.toggles[name] = toggle
    }

    func countVariant(name: String, variant: String) {
        guard !disableMetrics else { return }

        var toggle = bucket.toggles[name] ?? ToggleMetrics()
        toggle.variants[variant, default: 0] += 1
        bucket.toggles[name] = toggle
    }

    func sendMetrics() async {
        bucket.closeBucket()
        guard !bucket.isEmpty() else { return }

        let localBucket = bucket
        bucket = Bucket(clock: clock)

        do {
            let payload = MetricsPayload(appName: appName, instanceId: "swift", bucket: localBucket)
            let jsonPayload = try JSONSerialization.data(withJSONObject: payload.toJson())
            let request = createRequest(payload: jsonPayload)
            let (_, _) = try await poster(request)
            SwiftEventBus.post("sent")
        } catch {
            print("Metrics error: \(error)")
        }
    }

    func createRequest(payload: Data) -> URLRequest {
        var request = URLRequest(url: url.appendingPathComponent("client/metrics"))
        request.httpMethod = "POST"
        request.httpBody = payload
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("no-cache", forHTTPHeaderField: "Cache")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(clientKey, forHTTPHeaderField: "Authorization")
        return request
    }
}

