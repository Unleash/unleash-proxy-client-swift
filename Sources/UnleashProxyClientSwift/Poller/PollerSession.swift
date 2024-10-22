import Foundation

public protocol PollerSession {
    func perform(_ request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
}
