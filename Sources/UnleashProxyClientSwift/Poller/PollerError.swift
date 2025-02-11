public enum PollerError: Error {
    case decoding(Error)
    case network(Error?)
    case url
    case noResponse(Error?)
    case unhandledStatusCode(Int)
}
