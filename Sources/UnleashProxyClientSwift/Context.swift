public struct Context {
    public let appName: String
    public let environment: String?
    public let userId: String?
    public let sessionId: String?
    public let remoteAddress: String?
    public let properties: [String: String]?

    public init(
        appName: String? = nil,
        environment: String? = nil,
        userId: String? = nil,
        sessionId: String? = nil,
        remoteAddress: String? = nil,
        properties: [String: String]? = nil
    ) {
        self.appName = appName ?? "unleash-swift-client"
        self.environment = environment
        self.userId = userId
        self.sessionId = sessionId
        self.remoteAddress = remoteAddress
        self.properties = properties
    }
    
    func toMap() -> [String: String] {
        var params: [String: String] = [:]
        params["appName"] = appName
        if let environment = self.environment {
            params["environment"] = environment
        }
        if let userId = self.userId {
            params["userId"] = userId
        }
        if let sessionId = self.sessionId {
            params["sessionId"] = sessionId
        }
        if let remoteAddress = self.remoteAddress {
            params["remoteAddress"] = remoteAddress
        }
        properties?.forEach { (key, value) in
            params["properties[\(key)]"] = value
        }
        return params
    }
}
