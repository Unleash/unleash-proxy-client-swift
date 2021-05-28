
import Foundation
import SwiftEventBus


public class Poller {
    var refreshInterval: Int?
    var unleashUrl: String
    var timer: Timer?
    var toggles: [String: Toggle] = [:]
    var ready: Bool
    var apiKey: String;
    var etag: String;
    
    public init(refreshInterval: Int? = nil, unleashUrl: String, apiKey: String) {
        self.refreshInterval = refreshInterval
        self.unleashUrl = unleashUrl
        self.apiKey = apiKey
        self.timer = nil
        self.toggles = [:]
        self.ready = false
        self.etag = ""
   }
    
    public func start(context: [String: String]) -> Void {
        self.getFeatures(context: context)
        print("Starting")
 
        self.timer = Timer.scheduledTimer(withTimeInterval: Double(self.refreshInterval ?? 15), repeats: true) { timer in
            self.getFeatures(context: context)
        }
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.default)
    }
    
    public func stop() -> Void {
        self.timer?.invalidate();
    }
    
    func formatURL(context: [String: String]) -> String {
        var params: [String] = []
        for key in context.keys {
        let param = "\(key)=\(unwrap(context[key]))"
           params.append(param)
        }

        return self.unleashUrl + "?" + params.joined(separator: "&");
    }
    
    private func createFeatureMap(features: FeatureResponse) -> [String: Toggle] {
        var toggleMap: [String: Toggle] = [:]
        
        for toggle in features.toggles {
            toggleMap[toggle.name] = toggle
        }
        
        return toggleMap
    }
    
    func getFeatures(context: [String: String]) -> Void {
        guard let url = URL(string: formatURL(context: context)) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apiKey, forHTTPHeaderField: "Authorization")
        request.setValue(self.etag, forHTTPHeaderField: "If-None-Match")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let data = data, error == nil else {
                print("Something went wrong")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 304 {
                    print("No changes in feature toggles.")
                    return
                }
                
                if httpResponse.statusCode > 399 && httpResponse.statusCode < 599 {
                    print("Error fetching toggles")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    var result: FeatureResponse?
                    
                    if httpResponse.allHeaderFields["Etag"] as! String != "" {
                        self.etag = httpResponse.allHeaderFields["Etag"] as! String
                    }
                    
                    do {
                        result = try JSONDecoder().decode(FeatureResponse.self, from: data)
                    } catch {
                        print(error.localizedDescription)
                    }
                    
                    guard let json = result else {
                        return
                    }
                    
                    self.toggles = self.createFeatureMap(features: json)
                    if (self.ready) {
                        SwiftEventBus.post("update")
                    } else {
                        SwiftEventBus.post("ready")
                        self.ready = true
                    }
                }
            }
        }).resume()
    }
}





