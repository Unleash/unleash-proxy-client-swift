// MARK: - Payload
public struct Payload: Codable, Equatable {
    public let type, value: String
    
    public init(type: String, value: String) {
        self.type = type
        self.value = value
    }
}
