import Foundation

/// Simulates a real network `HTTPURLResponse` with raw header casing
/// without Apple's default constructor key-canonicalization.
final class FakeHTTPURLResponse: HTTPURLResponse, @unchecked Sendable {
    private let rawHeaders: [String: String]

    init(url: URL, statusCode: Int, headerFields: [String: String]) {
        self.rawHeaders = headerFields
        super.init(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var allHeaderFields: [AnyHashable: Any] {
        return rawHeaders
    }
}
