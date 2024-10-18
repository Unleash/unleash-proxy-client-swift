// MARK: - Variant
public struct Variant: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case name, enabled, payload
        case featureEnabled = "feature_enabled"
    }
    
    /// Name of the variant
    public let name: String
    /// Enabled state for the variant
    ///     - true variant is enabled
    ///     - false variant is disabled
    public let enabled: Bool
    /// Enabled state of host feature which informs if variant is disabled from host feature state
    ///     - false: Host feature is disabled
    ///     - true: Host feature is enabled
    public let featureEnabled: Bool?
    /// Optional payload delivered with the variant
    public let payload: Payload?
    
    public init(
        name: String,
        enabled: Bool,
        featureEnabled: Bool? = nil,
        payload: Payload? = nil
    ) {
        self.name = name
        self.enabled = enabled
        self.featureEnabled = featureEnabled
        self.payload = payload
    }
}

extension Variant {
    static let defaultDisabled = Variant(
        name: "disabled",
        enabled: false,
        featureEnabled: false,
        payload: nil
    )
}
