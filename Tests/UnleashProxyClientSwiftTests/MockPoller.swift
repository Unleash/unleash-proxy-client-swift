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

    init(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
        self.data = data
        self.response = response
        self.error = error
    }

    func perform(_ request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        completionHandler(data, response, error)
    }
}

class MockPoller: Poller {
    var dataGenerator: () -> [String: Toggle];
    
    init(callback: @escaping () -> [String: Toggle], unleashUrl: String, apiKey: String, session: PollerSession) {
        self.dataGenerator = callback
        super.init(refreshInterval: 15, unleashUrl: unleashUrl, apiKey: apiKey, session: session)
    }
    
    override func getFeatures(context: [String: String]) -> Void {
        self.toggles = dataGenerator()
    }
}
