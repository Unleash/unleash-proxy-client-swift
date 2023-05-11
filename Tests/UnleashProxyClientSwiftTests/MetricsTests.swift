import XCTest
import SwiftEventBus
@testable import UnleashProxyClientSwift

final class MetricsTests: XCTestCase {
    func testCountMetrics() {
        let metricsSent = XCTestExpectation(description: "Metrics sent")
        SwiftEventBus.onBackgroundThread(self, name: "sent") { _ in
            metricsSent.fulfill()
        }
        let fixedClock = { DateComponents(calendar: .current, timeZone: TimeZone(identifier: "UTC"), year: 2022, month: 12, day: 24, hour: 23, minute: 0, second: 0).date! }
        var recordedRequestBody: Data?
        let poster: (URLRequest) async throws -> (Data, URLResponse) = { request in
            recordedRequestBody = request.httpBody
            return (Data(), HTTPURLResponse(url: URL(string: "https://unleashapi.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        let metrics = Metrics(appName: "TestApp",
                metricsInterval: 1,
                clock: fixedClock,
                poster: poster,
                url: URL(string: "https://unleashinstance.com")!,
                clientKey: "testKey")
        metrics.start()

        metrics.count(name: "testToggle", enabled: true)
        metrics.count(name: "testToggle", enabled: true)
        metrics.count(name: "testToggle", enabled: false)
        metrics.countVariant(name: "testToggle", variant: "variantA")
        metrics.countVariant(name: "testToggle", variant: "variantA")
        metrics.countVariant(name: "testToggle", variant: "variantB")

        wait(for: [metricsSent], timeout: 2)
        let expectedMetrics = """
                              {
                                "appName" : "TestApp",
                                "bucket" : {
                                  "start" : "2022-12-24T23:00:00Z",
                                  "stop" : "2022-12-24T23:00:00Z",
                                  "toggles" : {
                                    "testToggle" : {
                                      "yes" : 2,
                                      "no" : 1,
                                      "variants" : {
                                        "variantA" : 2,
                                        "variantB": 1
                                      }
                                    }
                                  }
                                },
                                "instanceId" : "swift"
                              }
                              """;
        XCTAssertEqual(
                try! JSONSerialization.jsonObject(with: recordedRequestBody!, options: []) as? [String: AnyHashable],
                try! JSONSerialization.jsonObject(with: expectedMetrics.data(using: .utf8)!, options: []) as? [String: AnyHashable],
                "The recorded request body should match the expected metrics"
        )
    }
}
