import Foundation
import SwiftEventBus

public class Poller {
    var refreshInterval: Int?
    var unleashUrl: URL
    var timer: DispatchSourceTimer?
    var ready: Bool
    var apiKey: String
    var etag: String
    var appName: String
    var connectionId: UUID

    private let session: PollerSession
    var storageProvider: StorageProvider
    let customHeaders: [String: String]
    let customHeadersProvider: CustomHeadersProvider

    private let lock = NSLock()

    public init(
        refreshInterval: Int? = nil,
        unleashUrl: URL,
        apiKey: String,
        session: PollerSession = URLSession.shared,
        storageProvider: StorageProvider = DictionaryStorageProvider(),
        customHeaders: [String: String] = [:],
        customHeadersProvider: CustomHeadersProvider = DefaultCustomHeadersProvider(),
        bootstrap: Bootstrap = .toggles([]),
        appName: String,
        connectionId: UUID
    ) {
        self.refreshInterval = refreshInterval
        self.unleashUrl = unleashUrl
        self.apiKey = apiKey
        self.appName = appName
        self.connectionId = connectionId
        timer = nil
        ready = false
        etag = ""
        self.session = session
        self.storageProvider = storageProvider
        self.customHeaders = customHeaders
        self.customHeadersProvider = customHeadersProvider

        let toggles = bootstrap.toggles
        if toggles.isEmpty == false {
            createFeatureMap(toggles: toggles)
        }
    }

    public func start(
        bootstrapping toggles: [Toggle] = [],
        context: Context,
        completionHandler: ((PollerError?) -> Void)? = nil
    ) {
        if toggles.isEmpty {
            getFeatures(context: context, completionHandler: completionHandler)
        } else {
            Printer.printMessage("Starting with provided bootstrap toggles")
            createFeatureMap(toggles: toggles)
            completionHandler?(nil)
        }

        let refreshIntervalValue = refreshInterval

        if refreshIntervalValue == 0 {
            return
        }

        let interval = Double(refreshIntervalValue ?? 15)

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.getFeatures(context: context)
        }
        timer.resume()

        lock.lock()
        self.timer = timer
        lock.unlock()
    }

    public func stop() {
        lock.lock()
        timer?.cancel()
        timer = nil
        lock.unlock()
    }

    func formatURL(context: Context) -> URL? {
        let url = unleashUrl

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.percentEncodedQuery = context
            .toURIMap()
            .compactMap { key, value in
                if let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved),
                   let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved)
                {
                    return [encodedKey, encodedValue].joined(separator: "=")
                }
                return nil
            }
            .joined(separator: "&")

        return components?.url
    }

    private func createFeatureMap(toggles: [Toggle]) {
        storageProvider.clear()
        let values = Dictionary(
            uniqueKeysWithValues: toggles.map { ($0.name, $0) }
        )
        storageProvider.set(values: values)
    }

    public func getFeature(name: String) -> Toggle? {
        return storageProvider.value(key: name)
    }

    func getFeatures(
        context: Context,
        completionHandler: ((PollerError?) -> Void)? = nil
    ) {
        guard let url = formatURL(context: context) else {
            completionHandler?(.url)
            Printer.printMessage("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let currentEtag: String

        lock.lock()
        currentEtag = etag
        lock.unlock()

        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue(currentEtag, forHTTPHeaderField: "If-None-Match")
        request.setValue(appName, forHTTPHeaderField: "unleash-appname")
        request.setValue(connectionId.uuidString, forHTTPHeaderField: "unleash-connection-id")
        request.setValue("unleash-ios-sdk:\(LibraryInfo.version)", forHTTPHeaderField: "unleash-sdk")

        let customHeaders = self.customHeaders.merging(customHeadersProvider.getCustomHeaders()) { _, new in
            new
        }.filter { key, _ in !isSensitiveHeader(key) }

        if !customHeaders.isEmpty {
            for (key, value) in customHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        request.cachePolicy = .reloadIgnoringLocalCacheData

        session.perform(request) { [self] data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                Printer.printMessage("No response")
                completionHandler?(.noResponse)
                return
            }

            if httpResponse.statusCode == 304 {
                completionHandler?(nil)
                Printer.printMessage("No changes in feature toggles.")
                return
            }

            if httpResponse.statusCode > 399, httpResponse.statusCode < 599 {
                completionHandler?(.network)
                Printer.printMessage("Error fetching toggles")
                return
            }

            guard let data = data else {
                completionHandler?(nil)
                Printer.printMessage("No response data")
                return
            }

            guard httpResponse.statusCode == 200 else {
                Printer.printMessage("Unhandled status code")
                completionHandler?(.unhandledStatusCode)
                return
            }

            var result: FeatureResponse?

            if let newEtag = httpResponse.allHeaderFields["Etag"] as? String, !newEtag.isEmpty {
                lock.lock()
                self.etag = newEtag
                lock.unlock()
            }

            do {
                result = try JSONDecoder().decode(FeatureResponse.self, from: data)
            } catch {
                Printer.printMessage(error.localizedDescription)
            }

            guard let decodedResponse = result else {
                completionHandler?(.decoding)
                return
            }

            self.createFeatureMap(toggles: decodedResponse.toggles)

            let wasReady: Bool
            lock.lock()
            wasReady = self.ready
            if !wasReady {
                self.ready = true
            }
            lock.unlock()

            if wasReady {
                Printer.printMessage("Flags updated")
                SwiftEventBus.post("update")
            } else {
                Printer.printMessage("Initial flags fetched")
                SwiftEventBus.post("ready")
            }

            completionHandler?(nil)
        }
    }

    private func isSensitiveHeader(_ header: String) -> Bool {
        let lowercasedHeader = header.lowercased()
        return lowercasedHeader == "content-type" ||
            lowercasedHeader == "if-none-match" ||
            lowercasedHeader.hasPrefix("unleash-")
    }
}

private extension CharacterSet {
    static let rfc3986Unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
}
