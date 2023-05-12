import Foundation
@testable import UnleashProxyClientSwift

class MockMetrics: Metrics {
    var isStarted: Bool = false

    override func start() {
        isStarted = true
    }

    init(appName: String) {
        let noOpPoster: (URLRequest) async throws -> (Data, URLResponse) = { _ in
            return (Data(), HTTPURLResponse(url: URL(string: "https://irrelevant.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        super.init(appName: appName, metricsInterval: Double(15), clock: { return Date() }, disableMetrics: false, poster: noOpPoster, url: URL(string: "https://irrelevant.com")!, clientKey: "irrelevant")
    }
}
