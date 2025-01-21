// MetricsTests.swift

import XCTest
import SwiftEventBus
@testable import UnleashProxyClientSwift

final class MetricsTests: XCTestCase {
    func testCountMetrics() throws {
        let metricsSent = expectation(description: "Metrics sent")
        SwiftEventBus.onBackgroundThread(self, name: "sent") { _ in
            metricsSent.fulfill()
        }

        let fixedClock = { DateComponents(calendar: .current, timeZone: TimeZone(identifier: "UTC"), year: 2022, month: 12, day: 24, hour: 23, minute: 0, second: 0).date! }

        var recordedRequestBody: Data?

        let poster: Metrics.PosterHandler = { request, completionHandler in
            recordedRequestBody = request.httpBody
            let response = HTTPURLResponse(url: URL(string: "https://unleashapi.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
            completionHandler(.success((Data(), response!)))
        }

        let metrics = Metrics(appName: "TestApp",
                metricsInterval: 1,
                clock: fixedClock,
                poster: poster,
                url: URL(string: "https://unleashinstance.com")!,
                clientKey: "testKey",
                connectionId: UUID())
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

        let decodedRecordedRequestBody = try JSONSerialization.jsonObject(with: recordedRequestBody!, options: [])
        let decodedExpectedMetrics = try JSONSerialization.jsonObject(with: Data(expectedMetrics.utf8), options: [])

        XCTAssertEqual(decodedRecordedRequestBody as? [String: AnyHashable],
                decodedExpectedMetrics as? [String: AnyHashable],
                "The recorded request body should match the expected metrics")
    }

    func testFailOnCountMetricsSent() throws {
        let metricsSentError = expectation(description: "Metrics sent error")
        SwiftEventBus.onBackgroundThread(self, name: "error") { _ in
            metricsSentError.fulfill()
        }

        let fixedClock = { DateComponents(calendar: .current, timeZone: TimeZone(identifier: "UTC"), year: 2022, month: 12, day: 24, hour: 23, minute: 0, second: 0).date! }

        let poster: Metrics.PosterHandler = { request, completionHandler in
            completionHandler(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Metrics posting error"])))
        }

        let metrics = Metrics(appName: "TestApp",
                metricsInterval: 1,
                clock: fixedClock,
                poster: poster,
                url: URL(string: "https://unleashinstance.com")!,
                clientKey: "testKey",
                connectionId: UUID())
        metrics.start()

        metrics.count(name: "irrelevant", enabled: true)

        wait(for: [metricsSentError], timeout: 2)
    }

    func testDisabledMetrics() throws {
        let fixedClock = { DateComponents(calendar: .current, timeZone: TimeZone(identifier: "UTC"), year: 2022, month: 12, day: 24, hour: 23, minute: 0, second: 0).date! }

        let poster: Metrics.PosterHandler = { request, completionHandler in
            completionHandler(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "should never get here"])))
        }

        let metrics = Metrics(appName: "TestApp",
                metricsInterval: 1,
                clock: fixedClock,
                disableMetrics: true,
                poster: poster,
                url: URL(string: "https://unleashinstance.com")!,
                clientKey: "testKey",
                connectionId: UUID())
        metrics.start()

        metrics.count(name: "irrelevant", enabled: true)
        metrics.countVariant(name: "testToggle", variant: "variantA")

        XCTAssertEqual(metrics.bucket.toggles, [:])
    }


}
