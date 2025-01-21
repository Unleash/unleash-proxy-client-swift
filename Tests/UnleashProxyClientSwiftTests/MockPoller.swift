//
//  File.swift
//  
//
//  Created by Fredrik Strand Oseberg on 27/05/2021.
//

import Foundation
@testable import UnleashProxyClientSwift

class MockPollerSession: PollerSession {
    var data: Data?
    var response: URLResponse?
    var error: Error?    
    
    var performRequestHandler: ((URLRequest) -> Void)?
    
    init(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
        self.data = data
        self.response = response
        self.error = error
    }

    func perform(_ request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        performRequestHandler?(request)
        completionHandler(data, response, error)
    }
}

public class MockDictionaryStorageProvider: StorageProvider {
    private var storage: [String: Toggle] = [:]

    public init(storage: [String: Toggle]) {
        self.storage = storage
    }

    public func set(value: Toggle?, key: String) {
        storage[key] = value
    }

    public func value(key: String) -> Toggle? {
        return storage[key]
    }
    
    public func clear() {
        storage = [:]
    }
}

class MockPoller: Poller {
    var dataGenerator: () -> [String: Toggle];
    var stubCompletionError: PollerError?
    
    init(callback: @escaping () -> [String: Toggle], unleashUrl: URL, apiKey: String, session: PollerSession, appName: String, connectionId: UUID) {
        self.dataGenerator = callback
        super.init(refreshInterval: 15, unleashUrl: unleashUrl, apiKey: apiKey, session: session, appName: appName, connectionId: connectionId)
    }
    
    override func getFeatures(context: Context, completionHandler: ((PollerError?) -> Void)? = nil) -> Void {
        self.storageProvider = MockDictionaryStorageProvider(storage: dataGenerator())
        completionHandler?(stubCompletionError)
    }
}
