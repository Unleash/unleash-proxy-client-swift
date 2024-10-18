public protocol StorageProvider {
    func set(value: Toggle?, key: String)
    func value(key: String) -> Toggle?
    func clear()
}
