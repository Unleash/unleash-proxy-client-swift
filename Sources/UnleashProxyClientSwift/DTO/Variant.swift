// MARK: - Variant
public struct Variant: Codable {
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
    public let featureEnabled: Bool
    /// Optional payload delivered with the variant
    public let payload: Payload?
}

extension Variant {
    static let defaultDisabled = Variant(
        name: "disabled",
        enabled: false,
        featureEnabled: false,
        payload: nil
    )
}