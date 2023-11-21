public struct Context {
    public let appName: String?
    public let environment: String?
    public var userId: String?
    public var sessionId: String?
    public var remoteAddress: String?
    public var properties: [String: String]?
    
    public init(
        appName: String? = nil,
        environment: String? = nil,
        userId: String? = nil,
        sessionId: String? = nil,
        remoteAddress: String? = nil,
        properties: [String: String]? = nil
    ) {
        self.appName = appName
        self.environment = environment
        self.userId = userId
        self.sessionId = sessionId
        self.remoteAddress = remoteAddress
        self.properties = properties
    }
    
    func toMap() -> [String: String] {
        var params: [String: String] = [:]
        if let userId = self.userId {
            params["userId"] = userId
        }
        if let remoteAddress = self.remoteAddress {
            params["remoteAddress"] = remoteAddress
        }
        if let sessionId = self.sessionId {
            params["sessionId"] = sessionId
        }
        if let appName = self.appName {
            params["appName"] = appName
        }
        if let environment = self.environment {
            params["environment"] = environment
        }
        properties?.forEach { (key, value) in
            params["properties[\(key)]"] = value
        }
        return params
    }
}
