import Foundation

public enum Bootstrap {
    /// Provide a list of Toggles
    case toggles([Toggle])
    
    /// Provide a path to json file describing toggles
    ///
    /// > Important: If the file cannot be opened it will log error to console and default to an empty list of toggles
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
                Printer.printMessage("Could not open JSON Bootsrap file at path: \(path). Using empty list.")
                return []
            }
        }
    }
}
