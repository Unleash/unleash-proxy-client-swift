public struct Context {
    let appName: String?
    let environment: String?
    var userId: String?
    var sessionId: String?
    var remoteAddress: String?
    var properties: [String: String]?

    init(
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

    public func toMap() -> [String: String] {
        var params: [String: String] = [:]
        properties?.forEach { key, value in
            params[key] = value
        }
        if let userId = userId {
            params["userId"] = userId
        }
        if let remoteAddress = remoteAddress {
            params["remoteAddress"] = remoteAddress
        }
        if let sessionId = sessionId {
            params["sessionId"] = sessionId
        }
        if let appName = appName {
            params["appName"] = appName
        }
        if let environment = environment {
            params["environment"] = environment
        }

        return params
    }

    func toURIMap() -> [String: String] {
        var params: [String: String] = [:]
        if let userId = userId {
            params["userId"] = userId
        }
        if let remoteAddress = remoteAddress {
            params["remoteAddress"] = remoteAddress
        }
        if let sessionId = sessionId {
            params["sessionId"] = sessionId
        }
        if let appName = appName {
            params["appName"] = appName
        }
        if let environment = environment {
            params["environment"] = environment
        }
        properties?.forEach { key, value in
            params["properties[\(key)]"] = value
        }
        return params
    }
}
