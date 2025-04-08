import Foundation
import SwiftEventBus

@available(macOS 10.15, *)
public class UnleashClientBase {
    public var context: Context
    var timer: Timer?
    var poller: Poller
    var metrics: Metrics
    var connectionId: UUID

    public init(
        unleashUrl: String,
        clientKey: String,
        refreshInterval: Int = 15,
        metricsInterval: Int = 30,
        disableMetrics: Bool = false,
        appName: String = "unleash-swift-client",
        environment: String? = "default",
        context: [String: String]? = nil,
        pollerSession: PollerSession = URLSession.shared,
        poller: Poller? = nil,
        metrics: Metrics? = nil,
        customHeaders: [String: String] = [:],
        customHeadersProvider: CustomHeadersProvider = DefaultCustomHeadersProvider(),
        bootstrap: Bootstrap = .toggles([])
    ) {
        guard let url = URL(string: unleashUrl), url.scheme != nil else {
            fatalError("Invalid Unleash URL: \(unleashUrl)")
        }

        self.connectionId = UUID()
        self.timer = nil
        if let poller = poller {
            self.poller = poller
        } else {
            self.poller = Poller(
                refreshInterval: refreshInterval,
                unleashUrl: url,
                apiKey: clientKey,
                session: pollerSession,
                customHeaders: customHeaders,
                customHeadersProvider: customHeadersProvider,
                bootstrap: bootstrap,
                appName: appName,
                connectionId: connectionId
            )
        }
        if let metrics = metrics {
            self.metrics = metrics
        } else {
            let urlSessionPoster: Metrics.PosterHandler = { request, completionHandler in
                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if let error = error {
                        completionHandler(.failure(error))
                    } else if let data = data, let response = response {
                        completionHandler(.success((data, response)))
                    }
                }
                task.resume()
            }
            self.metrics = Metrics(appName: appName, metricsInterval: Double(metricsInterval), clock: { return Date() }, disableMetrics: disableMetrics, poster: urlSessionPoster, url: url, clientKey: clientKey, customHeaders: customHeaders, connectionId: connectionId)
        }
        
        self.context = Context(appName: appName, environment: environment)
        if let providedContext = context {
            self.context = self.calculateContext(context: providedContext)
        }
    }

    public func start(
        bootstrap: Bootstrap = .toggles([]),
        _ printToConsole: Bool = false,
        completionHandler: ((PollerError?) -> Void)? = nil
    ) -> Void {
        Printer.showPrintStatements = printToConsole
        self.stop()
        poller.start(
            bootstrapping: bootstrap.toggles,
            context: context,
            completionHandler: completionHandler
        )
        metrics.start()
    }

    public func stop() -> Void {
        poller.stop()
        metrics.stop()
        SwiftEventBus.unregister(self)
    }

    public func isEnabled(name: String) -> Bool {
        let toggle = poller.getFeature(name: name)
        let enabled = toggle?.enabled ?? false
        metrics.count(name: name, enabled: enabled)
        
        if let toggle = toggle, toggle.impressionData {
            SwiftEventBus.post("impression", sender: ImpressionEvent(
                toggleName: name,
                enabled: enabled,
                context: context
            ))
        }
        
        return enabled
    }

    public func getVariant(name: String) -> Variant {
        let toggle = poller.getFeature(name: name)
        let variant = toggle?.variant ?? .defaultDisabled
        let enabled = toggle?.enabled ?? false

        
        metrics.count(name: name, enabled: enabled)
        metrics.countVariant(name: name, variant: variant.name)
        
        if let toggle = toggle, toggle.impressionData {
            
            SwiftEventBus.post("impression", sender: ImpressionEvent(
                toggleName: name,
                enabled: enabled,
                variant: variant,
                context: context
            ))
        }
        
        return variant
    }

    public func subscribe(name: String, callback: @escaping () -> Void) {
        if Thread.isMainThread {
            print("Subscribing to \(name) on main thread")
            SwiftEventBus.onMainThread(self, name: name) { result in
                callback()
            }
        } else {
            print("Subscribing to \(name) on background thread")
            SwiftEventBus.onBackgroundThread(self, name: name) { result in
                callback()
            }
        }
    }
    
    public func subscribe(_ event: UnleashEvent, callback: @escaping () -> Void) {
        subscribe(name: event.rawValue, callback: callback)
    }

    public func subscribe(_ event: UnleashEvent, callback: @escaping (Any?) -> Void) {
        subscribe(name: event.rawValue, callback: callback)
    }

    public func subscribe(name: String, callback: @escaping (Any?) -> Void) {
        let handler: (Notification?) -> Void = { notification in
            callback(notification?.object)
        }
        
        if Thread.isMainThread {
            print("Subscribing to \(name) on main thread with object")
            SwiftEventBus.onMainThread(self, name: name, handler: handler)
        } else {
            print("Subscribing to \(name) on background thread with object")
            SwiftEventBus.onBackgroundThread(self, name: name, handler: handler)
        }
    }

    public func unsubscribe(name: String) {
        SwiftEventBus.unregister(self, name: name)
    }
    
    public func unsubscribe(_ event: UnleashEvent) {
        unsubscribe(name: event.rawValue)
    }
    
    public func updateContext(context: [String: String], properties: [String:String]? = nil, completionHandler: ((PollerError?) -> Void)? = nil) {
        self.context = self.calculateContext(context: context, properties: properties)
        self.start(Printer.showPrintStatements, completionHandler: completionHandler)
    }

    func calculateContext(context: [String: String], properties: [String:String]? = nil) -> Context {
        let specialKeys: Set = ["appName", "environment", "userId", "sessionId", "remoteAddress"]
        var newProperties: [String: String] = [:]

        context.forEach { (key, value) in
            if !specialKeys.contains(key) {
                newProperties[key] = value
            }
        }

        properties?.forEach { (key, value) in
            newProperties[key] = value
        }
        
        let newContext = Context(
            appName: self.context.appName,
            environment: self.context.environment,
            userId: context["userId"],
            sessionId: context["sessionId"],
            remoteAddress: context["remoteAddress"],
            properties: newProperties
        )

        return newContext
    }
}

@available(iOS 13, tvOS 13, *)
public class UnleashClient: UnleashClientBase, ObservableObject {
    @MainActor
    public func start(
        bootstrap: Bootstrap = .toggles([]),
        printToConsole: Bool = false
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            start(bootstrap: bootstrap, printToConsole) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    @MainActor
    public func updateContext(
        context: [String: String],
        properties: [String:String]? = nil
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            updateContext(context: context, properties: properties) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
