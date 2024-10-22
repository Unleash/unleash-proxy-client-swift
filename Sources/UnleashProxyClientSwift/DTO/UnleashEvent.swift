// MARK: UnleashEvent
public enum UnleashEvent: String, CaseIterable {
    /// Emitted when UnleashClient is ready after finished first flag fetch
    case ready
    /// Emitted when toggles have been updated
    case update
    /// Emitted on metrics sent
    case sent
    /// Emitted when metrics failed to send
    case error
}
