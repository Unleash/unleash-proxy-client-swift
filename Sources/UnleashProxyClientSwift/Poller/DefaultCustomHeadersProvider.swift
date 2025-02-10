import Foundation

public class DefaultCustomHeadersProvider: CustomHeadersProvider {
    public init() {}
    public func getCustomHeaders() -> [String: String] {
        return [:]
    }
}
