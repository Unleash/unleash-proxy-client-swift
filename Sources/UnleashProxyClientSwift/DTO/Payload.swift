// MARK: - Payload
public struct Payload: Codable {
    public let type, value: String
    
    public init(type: String, value: String) {
        self.type = type
        self.value = value
    }
}
