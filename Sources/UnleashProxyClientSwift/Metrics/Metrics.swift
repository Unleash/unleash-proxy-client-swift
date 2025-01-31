import Foundation
import SwiftEventBus

public class Metrics {
    let appName: String
    let metricsInterval: TimeInterval
    let clientKey: String
    typealias PosterHandler = (URLRequest, @escaping (Result<(Data, URLResponse), Error>) -> Void) -> Void
    let poster: PosterHandler
    let clock: () -> Date
    var disableMetrics: Bool
    var timer: Timer?
    var bucket: Bucket
    let url: URL
    let customHeaders: [String: String]
    let connectionId: UUID

    init(appName: String,
         metricsInterval: TimeInterval,
         clock: @escaping () -> Date,
         disableMetrics: Bool = false,
         poster: @escaping PosterHandler,
         url: URL,
         clientKey: String,
         customHeaders: [String: String] = [:],
         connectionId: UUID) {
        self.appName = appName
        self.metricsInterval = metricsInterval
        self.clock = clock
        self.disableMetrics = disableMetrics
        self.poster = poster
        self.url = url
        self.clientKey = clientKey
        self.bucket = Bucket(clock: clock)
        self.customHeaders = customHeaders
        self.connectionId = connectionId
    }

    func start() {
        if disableMetrics { return }

        self.timer = Timer.scheduledTimer(withTimeInterval: metricsInterval, repeats: true) { _ in
            self.sendMetrics()
        }
    }

    func stop() {
        self.timer?.invalidate()
    }
    
    private let queue = DispatchQueue(label: "io.getunleash.metrics")

    func count(name: String, enabled: Bool) {
        if disableMetrics { return }

        queue.sync {
            var toggle = bucket.toggles[name] ?? ToggleMetrics()
            if enabled {
                toggle.yes += 1
            } else {
                toggle.no += 1
            }
            bucket.toggles[name] = toggle
        }
    }

    func countVariant(name: String, variant: String) {
        if disableMetrics { return }

        queue.sync {
            var toggle = bucket.toggles[name] ?? ToggleMetrics()
            toggle.variants[variant, default: 0] += 1
            bucket.toggles[name] = toggle
        }
    }

    func sendMetrics() {
        bucket.closeBucket()
        guard !bucket.isEmpty() else { return }

        let localBucket = bucket
        bucket = Bucket(clock: clock)

        do {
            let payload = MetricsPayload(appName: appName, instanceId: "swift", bucket: localBucket)
            let jsonPayload = try JSONSerialization.data(withJSONObject: payload.toJson())
            let request = createRequest(payload: jsonPayload)
            poster(request) { result in
                switch result {
                case .success(_):
                    SwiftEventBus.post("sent")
                case .failure(let error):
                    Printer.printMessage("Error sending metrics")
                    SwiftEventBus.post("error", sender: error)
                }
            }
        } catch {
            Printer.printMessage("Error preparing metrics for sending")
            SwiftEventBus.post("error", sender: error)
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
        request.addValue(appName, forHTTPHeaderField: "unleash-appname")
        request.addValue(connectionId.uuidString, forHTTPHeaderField: "unleash-connection-id")
        request.setValue("unleash-client-swift:\(LibraryInfo.version)", forHTTPHeaderField: "unleash-sdk")
        if !self.customHeaders.isEmpty {
            for (key, value) in self.customHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        return request
    }
}
