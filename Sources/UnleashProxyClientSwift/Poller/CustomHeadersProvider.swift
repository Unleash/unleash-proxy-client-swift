public protocol CustomHeadersProvider {
    func getCustomHeaders() -> [String: String]
}
