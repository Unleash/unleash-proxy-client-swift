// MARK: - Toggle
public struct Toggle: Codable, Equatable {
    public let name: String
    public let enabled: Bool
    public let impressionData: Bool
    public let variant: Variant?
    
    public init(
        name: String,
        enabled: Bool,
        impressionData: Bool = false,
        variant: Variant? = nil
    ) {
        self.name = name
        self.enabled = enabled
        self.impressionData = impressionData
        self.variant = variant
    }
}
