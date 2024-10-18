import Foundation

public enum Bootstrap {
    case toggles([Toggle])
    case jsonFile(path: String)
    
    var toggles: [Toggle] {
        switch self {
        case .toggles(let toggles):
            return toggles
            
        case .jsonFile(let path):
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decodedData: FeatureResponse = try JSONDecoder()
                    .decode(FeatureResponse.self, from: data)
                return decodedData.toggles
            } catch {
                fatalError("Failed to decode JSON file at path: \(path): \(error)")
            }
        }
    }
}
