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
    
    enum CodingKeys: String, CodingKey {
        case name
        case enabled
        case impressionData
        case variant
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        variant = try container.decodeIfPresent(Variant.self, forKey: .variant)
        impressionData = (try? container.decodeIfPresent(Bool.self, forKey: .impressionData)) ?? false
    }
}
