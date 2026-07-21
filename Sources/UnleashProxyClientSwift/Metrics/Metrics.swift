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
    var timer: DispatchSourceTimer?
    var bucket: Bucket
    let url: URL
    let customHeaders: [String: String]
    let connectionId: UUID
    let sdkFlavor: String?
    let sdkFlavorVersion: String?

    private let lock = NSLock()

    init(
        appName: String,
        metricsInterval: TimeInterval,
        clock: @escaping () -> Date,
        disableMetrics: Bool = false,
        poster: @escaping PosterHandler,
        url: URL,
        clientKey: String,
        customHeaders: [String: String] = [:],
        connectionId: UUID,
        sdkFlavor: String? = nil,
        sdkFlavorVersion: String? = nil
        ) {
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
        self.sdkFlavor = sdkFlavor
        self.sdkFlavorVersion = sdkFlavorVersion
    }

    func start() {
        lock.lock()
        let isDisabled = self.disableMetrics
        lock.unlock()

        if isDisabled { return }

        lock.lock()
        self.timer?.cancel()
        self.timer = nil
        let interval = self.metricsInterval
        lock.unlock()

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.sendMetrics()
        }
        timer.resume()

        lock.lock()
        self.timer = timer
        lock.unlock()
    }

    func stop() {
        lock.lock()
        self.timer?.cancel()
        self.timer = nil
        lock.unlock()
    }

    func count(name: String, enabled: Bool) {
        lock.lock()
        let isDisabled = self.disableMetrics
        if isDisabled {
            lock.unlock()
            return
        }

        var toggle = bucket.toggles[name] ?? ToggleMetrics()
        if enabled {
            toggle.yes += 1
        } else {
            toggle.no += 1
        }
        bucket.toggles[name] = toggle
        lock.unlock()
    }

    func countVariant(name: String, variant: String) {
        lock.lock()
        let isDisabled = self.disableMetrics
        if isDisabled {
            lock.unlock()
            return
        }

        var toggle = bucket.toggles[name] ?? ToggleMetrics()
        toggle.variants[variant, default: 0] += 1
        bucket.toggles[name] = toggle
        lock.unlock()
    }

    func sendMetrics() {
        let localBucket: Bucket
        let clockFunction: () -> Date
        
        lock.lock()
        bucket.closeBucket()
        localBucket = bucket
        clockFunction = self.clock
        bucket = Bucket(clock: clockFunction)
        lock.unlock()

        guard !localBucket.isEmpty() else { return }

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
        request.setValue("unleash-ios-sdk:\(LibraryInfo.version)", forHTTPHeaderField: "unleash-sdk")
        if let sdkFlavor {
            request.setValue(sdkFlavor, forHTTPHeaderField: "unleash-sdk-flavor")
        }
        if let sdkFlavorVersion {
            request.setValue(sdkFlavorVersion, forHTTPHeaderField: "unleash-sdk-flavor-version")
        }
        if !customHeaders.isEmpty {
            for (key, value) in customHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        return request
    }
}
