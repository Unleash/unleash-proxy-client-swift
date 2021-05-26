
import Foundation
import SwiftEventBus

// MARK: - Welcome
struct FeatureResponse: Codable {
    let toggles: [Toggle]
}

// MARK: - Toggle
struct Toggle: Codable {
    let name: String
    let enabled: Bool
    let variant: Variant
}

// MARK: - Variant
public struct Variant: Codable {
    let name: String
    let enabled: Bool
    let payload: Payload?
}

// MARK: - Payload
public struct Payload: Codable {
    let type, value: String
}

struct Context {
    let appName: String?
    let environment: String?
}


@available(macOS 10.15, *)
public class UnleashClient: ObservableObject {
    let unleashUrl: String
    let apiKey: String
    let refreshInterval: Int?
    var context: [String: String] = [:]
    var timer: Timer?
    var toggles: [Toggle]
    var ready: Bool
    
    public init(unleashUrl: String, clientKey: String, refreshInterval: Int? = nil, appName: String? = nil, environment: String? = nil) {
        self.unleashUrl = unleashUrl
        self.apiKey = clientKey
        self.refreshInterval = refreshInterval
        self.context["appName"] = appName
        self.context["environment"] = environment
        self.timer = nil
        self.toggles = []
        self.ready = false
   }
    
    public func start() -> Void {
        self.getFeatures()
        
 
        self.timer = Timer.scheduledTimer(withTimeInterval: Double(self.refreshInterval ?? 15), repeats: true) { timer in
            print("FIRING")
            self.getFeatures()
        }
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.default)
    }
    
    public func stop() -> Void {
        self.timer?.invalidate();
    }
    
    public func isEnabled(name: String) -> Bool {
        for toggle in self.toggles {
            if toggle.name == name {
                return toggle.enabled;
            }
        }
        return false
    }
    
    public func getVariant(name: String) -> Variant? {
        for toggle in self.toggles {
            if toggle.name == name {
                return toggle.variant
            }
        }
        return nil
    }
    
    public func subscribe(name: String, callback: @escaping () -> Void) {
        SwiftEventBus.onBackgroundThread(self, name: name) { result in
            callback()
        }
    }
    
    private func formatURL() -> String {
        var params: [String] = []
        for key in self.context.keys {
        let param = "\(key)=\(unwrap(self.context[key]))"
           params.append(param)
        }

        return self.unleashUrl + "?" + params.joined(separator: "&");
    }
    
    public func updateContext(context: [String: String]) -> Void {
        self.context = context;
        self.stop()
        self.start()
    }
    
    private func getFeatures() -> Void {
        guard let url = URL(string: formatURL()) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        print(request.url as Any)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apiKey, forHTTPHeaderField: "Authorization")
        
        
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let data = data, error == nil else {
                print("Something went wrong")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse{
                
                if httpResponse.statusCode == 304 {
                    print("No changes in feature toggles.")
                    return
                }
                
                if httpResponse.statusCode > 399 && httpResponse.statusCode < 599 {
                    print("Error fetching toggles")
                }
                
                if httpResponse.statusCode == 200 {
                    var result: FeatureResponse?
                    do {
                        result = try JSONDecoder().decode(FeatureResponse.self, from: data)
                    } catch {
                        print(error.localizedDescription)
                    }
                    
                    guard let json = result else {
                        return
                    }
                    
                    self.toggles = json.toggles
                    if (self.ready) {
                        SwiftEventBus.post("update")
                    } else {
                        SwiftEventBus.post("ready")
                        self.ready = true
                    }
                    
                    for feature in json.toggles {
                        print(feature.name)
                    }
                }


            }
           
        }).resume()
    }
}





