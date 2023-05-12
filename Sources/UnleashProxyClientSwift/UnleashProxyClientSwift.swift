
import Foundation
import SwiftEventBus

// MARK: - Welcome
struct FeatureResponse: Codable {
    let toggles: [Toggle]
}

// MARK: - Toggle
public struct Toggle: Codable {
    public let name: String
    public let enabled: Bool
    public let variant: Variant
}

// MARK: - Variant
public struct Variant: Codable {
    public let name: String
    public let enabled: Bool
    public let payload: Payload?
}

// MARK: - Payload
public struct Payload: Codable {
    public let type, value: String
}

struct Context {
    let appName: String?
    let environment: String?
}


@available(macOS 10.15, *)
public class UnleashClientBase {
    public var context: [String: String] = [:]
    var timer: Timer?
    var poller: Poller
    var metrics: Metrics

    public init(unleashUrl: String, clientKey: String, refreshInterval: Int = 15, metricsInterval: Int = 30, disableMetrics: Bool = false, appName: String = "unleash-swift-client", environment: String? = nil, poller: Poller? = nil, metrics: Metrics? = nil) {
        guard let url = URL(string: unleashUrl), url.scheme != nil else {
            fatalError("Invalid Unleash URL: \(unleashUrl)")
        }

        self.context["appName"] = appName
        self.context["environment"] = environment
        self.timer = nil
        if let poller = poller {
            self.poller = poller
        } else {
            self.poller = Poller(refreshInterval: refreshInterval, unleashUrl: unleashUrl, apiKey: clientKey)
        }
        if let metrics = metrics {
            self.metrics = metrics
        } else {
            self.metrics = Metrics(appName: appName, metricsInterval: Double(metricsInterval), clock: { return Date() }, poster: URLSession.shared.data, url: url, clientKey: clientKey)
        }

   }

    public func start(_ printToConsole: Bool = false, completionHandler: ((PollerError?) -> Void)? = nil) -> Void {
        Printer.showPrintStatements = printToConsole
        poller.start(context: context, completionHandler: completionHandler)
        metrics.start()
    }

    public func stop() -> Void {
        poller.stop()
    }

    public func isEnabled(name: String) -> Bool {
        let enabled = poller.toggles[name]?.enabled ?? false
        metrics.count(name: name, enabled: enabled)
        return enabled
    }

    public func getVariant(name: String) -> Variant {
        let variant = poller.toggles[name]?.variant ?? Variant(name: "disabled", enabled: false, payload: nil)
        metrics.count(name: name, enabled: variant.enabled)
        metrics.countVariant(name: name, variant: variant.name)
        return variant
    }

    public func subscribe(name: String, callback: @escaping () -> Void) {
        SwiftEventBus.onBackgroundThread(self, name: name) { result in
            callback()
        }
    }

    public func updateContext(context: [String: String]) -> Void {
        var newContext: [String: String] = [:]
        newContext["appName"] = self.context["appName"]
        newContext["environment"] = self.context["environment"]

        context.forEach { (key, value) in
            newContext[key] = value
        }

        self.context = newContext
        self.stop()
        self.start()
    }
}

@available(iOS 13, *)
public class UnleashClient: UnleashClientBase, ObservableObject {
}
