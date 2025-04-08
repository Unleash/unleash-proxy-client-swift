import Foundation

public struct ImpressionEvent {
    public let toggleName: String
    public let enabled: Bool
    public let variant: Variant?
    public let context: Context
    
    public init(toggleName: String, enabled: Bool, variant: Variant? = nil, context: Context) {
        self.toggleName = toggleName
        self.enabled = enabled
        self.variant = variant
        self.context = context
    }
} 