public protocol StorageProvider {
    func set(values: [String: Toggle])
    func value(key: String) -> Toggle?
    func clear()
}
