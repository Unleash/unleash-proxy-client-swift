struct ToggleMetrics: Equatable {
    var yes: Int = 0
    var no: Int = 0
    var variants: [String: Int] = [:]

    func toJson() -> [String: Any] {
        ["yes": yes, "no": no, "variants": variants]
    }
}
