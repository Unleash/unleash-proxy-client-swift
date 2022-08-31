
import Foundation
import SwiftEventBus

public protocol PollerSession {
    func perform(_ request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
}

public enum PollerError: Error {
    case data
    case decoding
    case network
    case url
}

public class Poller {
    var refreshInterval: Int?
    var unleashUrl: String
    var timer: Timer?
    var toggles: [String: Toggle] = [:]
    var ready: Bool
    var apiKey: String;
    var etag: String;
    
    private let session: PollerSession
    
    public init(refreshInterval: Int? = nil, unleashUrl: String, apiKey: String, session: PollerSession = URLSession.shared) {
        self.refreshInterval = refreshInterval
        self.unleashUrl = unleashUrl
        self.apiKey = apiKey
        self.timer = nil
        self.toggles = [:]
        self.ready = false
        self.etag = ""
        self.session = session
    }

    public func start(context: [String: String], completionHandler: ((PollerError?) -> Void)? = nil) -> Void {
        self.getFeatures(context: context, completionHandler: completionHandler)

        let timer = Timer.scheduledTimer(withTimeInterval: Double(self.refreshInterval ?? 15), repeats: true) { timer in
            self.getFeatures(context: context)
        }
        self.timer = timer
        RunLoop.current.add(timer, forMode: .default)
    }
    
    public func stop() -> Void {
        self.timer?.invalidate()
    }
    
    func formatURL(context: [String: String]) -> String {
        let params = context.keys.map({ "\($0)=\(unwrap(context[$0]))" })

        return unleashUrl + "?" + params.joined(separator: "&")
    }
    
    private func createFeatureMap(features: FeatureResponse) -> [String: Toggle] {
        return features.toggles.reduce([String: Toggle]()) { result, toggle in
            var updatedResult = result
            updatedResult[toggle.name] = toggle
            return updatedResult
        }
    }
    
    func getFeatures(context: [String: String], completionHandler: ((PollerError?) -> Void)? = nil) -> Void {
        guard let url = URL(string: formatURL(context: context)) else {
            completionHandler?(.url)
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apiKey, forHTTPHeaderField: "Authorization")
        request.setValue(self.etag, forHTTPHeaderField: "If-None-Match")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        session.perform(request, completionHandler: { (data, response, error) in
            guard let data = data, error == nil else {
                completionHandler?(.data)
                print("Something went wrong")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 304 {
                    completionHandler?(nil)
                    print("No changes in feature toggles.")
                    return
                }
                
                if httpResponse.statusCode > 399 && httpResponse.statusCode < 599 {
                    completionHandler?(.network)
                    print("Error fetching toggles")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    var result: FeatureResponse?
                    
                    if let etag = httpResponse.allHeaderFields["Etag"] as? String, !etag.isEmpty {
                        self.etag = etag
                    }
                    
                    do {
                        result = try JSONDecoder().decode(FeatureResponse.self, from: data)
                    } catch {
                        print(error.localizedDescription)
                    }
                    
                    guard let json = result else {
                        completionHandler?(.decoding)
                        return
                    }
                    
                    self.toggles = self.createFeatureMap(features: json)
                    if (self.ready) {
                        SwiftEventBus.post("update")
                    } else {
                        SwiftEventBus.post("ready")
                        self.ready = true
                    }

                    completionHandler?(nil)
                }
            }
        })
    }
}
