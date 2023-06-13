import Foundation
@testable import UnleashProxyClientSwift

class MockMetrics: Metrics {
    var isStarted: Bool = false

    override func start() {
        isStarted = true
    }

    init(appName: String) {
        let noOpPoster: Metrics.PosterHandler = { request, completionHandler in
            let response = HTTPURLResponse(url: URL(string: "https://irrelevant.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
            completionHandler(.success((Data(), response!)))
        }
        super.init(appName: appName, metricsInterval: Double(15), clock: { return Date() }, disableMetrics: false, poster: noOpPoster, url: URL(string: "https://irrelevant.com")!, clientKey: "irrelevant")
    }
}
