public enum PollerError: Error {
    case decoding
    case network
    case url
    case noResponse
    case unhandledStatusCode
}
