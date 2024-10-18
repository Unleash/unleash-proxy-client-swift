// MARK: - Toggle
public struct Toggle: Codable {
    public let name: String
    public let enabled: Bool
    public let variant: Variant?
    
    public init(
        name: String,
        enabled: Bool,
        variant: Variant? = nil
    ) {
        self.name = name
        self.enabled = enabled
        self.variant = variant
    }
}
