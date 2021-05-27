//
//  File.swift
//  
//
//  Created by Fredrik Strand Oseberg on 27/05/2021.
//

import Foundation
@testable import UnleashProxyClientSwift

class MockPoller: Poller {
    var dataGenerator: () -> [String: Toggle];
    
    init(callback: @escaping () -> [String: Toggle], unleashUrl: String, apiKey: String ) {
        self.dataGenerator = callback
        super.init(refreshInterval: 15, unleashUrl: unleashUrl, apiKey: apiKey)
    }
    
    override func getFeatures(context: [String: String]) -> Void {
        self.toggles = dataGenerator()
    }
}
