
import Foundation
import SwiftEventBus

public class Poller {
    var refreshInterval: Int?
    var unleashUrl: URL
    var timer: Timer?
    var ready: Bool
    var apiKey: String;
    var etag: String;
    var appName: String;
    var connectionId: UUID;

    private let session: PollerSession
    var storageProvider: StorageProvider
    let customHeaders: [String: String]
    let customHeadersProvider: CustomHeadersProvider

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
        self.timer = nil
        self.ready = false
        self.etag = ""
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
    ) -> Void {
  
        if toggles.isEmpty {
            self.getFeatures(context: context, completionHandler: completionHandler)
        } else {
            Printer.printMessage("Starting with provided bootstrap toggles")
            createFeatureMap(toggles: toggles)
            completionHandler?(nil)
        }

        if self.refreshInterval == 0 {
            return
        }

        let timer = Timer.scheduledTimer(withTimeInterval: Double(self.refreshInterval ?? 15), repeats: true) { timer in
            self.getFeatures(context: context)
        }
        self.timer = timer
        RunLoop.current.add(timer, forMode: .default)
    }
    
    public func stop() -> Void {
        self.timer?.invalidate()
    }

    func formatURL(context: Context) -> URL? {
        var components = URLComponents(url: unleashUrl, resolvingAgainstBaseURL: false)
        components?.percentEncodedQuery = context
            .toURIMap()
            .compactMap { key, value in
            if let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved),
               let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved) {
                return [encodedKey, encodedValue].joined(separator: "=")
            }
            return nil
        }.joined(separator: "&")

        return components?.url
    }
    
    private func createFeatureMap(toggles: [Toggle]) {
        storageProvider.clear()
        toggles.forEach { storageProvider.set(value: $0, key: $0.name) }
    }
    
    public func getFeature(name: String) -> Toggle? {
        return self.storageProvider.value(key: name);
    }

    func getFeatures(
        context: Context,
        completionHandler: ((PollerError?) -> Void)? = nil
    ) -> Void {
        guard let url = formatURL(context: context) else {
            completionHandler?(.url)
            Printer.printMessage("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apiKey, forHTTPHeaderField: "Authorization")
        request.setValue(self.etag, forHTTPHeaderField: "If-None-Match")
        request.setValue(self.appName, forHTTPHeaderField: "unleash-appname")
        request.setValue(self.connectionId.uuidString, forHTTPHeaderField: "unleash-connection-id")
        request.setValue("unleash-client-swift:\(LibraryInfo.version)", forHTTPHeaderField: "unleash-sdk")

        let customHeaders = self.customHeaders.merging(self.customHeadersProvider.getCustomHeaders()) { (_, new) in
            new
        }.filter { key, _ in !isSensitiveHeader(key) }

        if !customHeaders.isEmpty {
            for (key, value) in customHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        session.perform(request) { (data, response, error) in
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
            
            if httpResponse.statusCode > 399 && httpResponse.statusCode < 599 {
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
            
            if let etag = httpResponse.allHeaderFields["Etag"] as? String, !etag.isEmpty {
                self.etag = etag
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
            if (self.ready) {
                Printer.printMessage("Flags updated")
                SwiftEventBus.post("update")
            } else {
                Printer.printMessage("Initial flags fetched")
                SwiftEventBus.post("ready")
                self.ready = true
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

fileprivate extension CharacterSet {
    static let rfc3986Unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
}
