import Foundation

public enum BootstrapError: Error {
    case fileDoesNotExist
}

extension String {
    func objectFromJSON<T: Decodable>() throws -> T {
        guard let filePath = Bundle
            .main
            .path(forResource: self, ofType: "json")
        else {
            throw BootstrapError.fileDoesNotExist
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        return try JSONDecoder().decode(T.self, from: data)
    }
}
