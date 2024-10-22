import Foundation

extension Date {
    func iso8601String() -> String {
        ISO8601DateFormatter().string(from: self)
    }
}
