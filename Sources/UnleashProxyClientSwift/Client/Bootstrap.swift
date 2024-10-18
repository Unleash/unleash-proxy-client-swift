import Foundation

public enum Bootstrap {
    case toggles([Toggle])
    case jsonFile(String)
    
    var toggles: [Toggle] {
        switch self {
        case .toggles(let toggles):
            return toggles
            
        case .jsonFile(let file):
            guard
                let filePath = Bundle.main.path(forResource: file, ofType: "json")
            else {
                fatalError("Bootstrap file does not exist: \(file).json")
            }
            
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                let decodedData: FeatureResponse = try JSONDecoder()
                    .decode(FeatureResponse.self, from: data)
                return decodedData.toggles
            } catch {
                fatalError("Failed to decode JSON file: \(file).json: \(error)")
            }
        }
    }
}
