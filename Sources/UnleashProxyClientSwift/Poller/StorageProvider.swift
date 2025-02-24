public protocol StorageProvider {
    func set(value: Toggle?, key: String)
    func reset(keyedValues: [String: Toggle])
    func value(key: String) -> Toggle?
    func clear()
}
