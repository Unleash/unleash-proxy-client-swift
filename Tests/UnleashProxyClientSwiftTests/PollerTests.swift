import XCTest
@testable import UnleashProxyClientSwift

final class PollerTests: XCTestCase {

    private let unleashUrl = URL(string: "https://app.unleash-hosted.com/hosted/api/proxy")!
    private let apiKey = "SECRET"
    private let timeout = 1.0

    func testTitleCaseEtagResponseHeader() {
        let response = mockResponse(headerFields: ["Etag": "W/\"77f-WboeNIYTrCbEJ+TK78VuhInQn2M\""])
        let data = stubData()
        let session = MockPollerSession(data: data, response: response)
        let poller = createPoller(with: session)

        XCTAssertTrue(poller.etag.isEmpty)
        poller.getFeatures()
        XCTAssertEqual(poller.etag, "W/\"77f-WboeNIYTrCbEJ+TK78VuhInQn2M\"")
    }

    func testLowerCaseEtagResponseHeader() {
        let response = mockResponse(headerFields: ["etag": "W/\"710-wJiNH+MQpj0ruMo7n/9j36tB+Fg\""])
        let data = stubData()
        let session = MockPollerSession(data: data, response: response)
        let poller = createPoller(with: session)

        XCTAssertTrue(poller.etag.isEmpty)
        poller.getFeatures()
        XCTAssertEqual(poller.etag, "W/\"710-wJiNH+MQpj0ruMo7n/9j36tB+Fg\"")
    }

    func testEmptyEtagResponseHeader() {
        let response = mockResponse(headerFields: ["Etag": ""])
        let data = stubData()
        let session = MockPollerSession(data: data, response: response)
        let poller = createPoller(with: session)
        poller.etag = "W/\"7c-GUwjw43L+nPpd9TY5PHtsXJueiM\""

        XCTAssertEqual(poller.etag, "W/\"7c-GUwjw43L+nPpd9TY5PHtsXJueiM\"")
        poller.getFeatures()
        XCTAssertEqual(poller.etag, "W/\"7c-GUwjw43L+nPpd9TY5PHtsXJueiM\"")
    }

    func testStartCompletesWithoutErrorWhenDataEmpty() {
        let response = mockResponse()
        let session = MockPollerSession(data: nil, response: response)
        let poller = createPoller(with: session)
        let expectation = XCTestExpectation(description: "Expect .data PollerError.")
        poller.start() { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testStartCompletesWithoutErrorWhenResponseNotModified() {
        let response = mockResponse(statusCode: 304)
        let data = stubData()
        let session = MockPollerSession(data: data, response: response)
        let poller = createPoller(with: session)
        let expectation = XCTestExpectation(description: "Expect error to be nil.")
        poller.start() { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testStartCompletesWithNetworkError() {
        for statusCode in 400..<599 {
            let response = mockResponse(statusCode: statusCode)
            let data = stubData()
            let session = MockPollerSession(data: data, response: response)
            let poller = createPoller(with: session)
            let expectation = XCTestExpectation(description: "Expect .network PollerError for status: \(statusCode).")
            poller.start() { error in
                XCTAssertEqual(error, .network)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: timeout)
        }
    }

    func testStartCompletesWithDecodingError() {
        let response = mockResponse()
        let stub: [String: Any] = ["toggles": [["foo": "bar", "baz": true]]]
        let data = try! JSONSerialization.data(withJSONObject: stub, options: .prettyPrinted)
        let session = MockPollerSession(data: data, response: response)
        let poller = createPoller(with: session)
        let expectation = XCTestExpectation(description: "Expect .decoding PollerError.")
        poller.start() { error in
            XCTAssertEqual(error, .decoding)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testStartCompletesWithoutError() {
        let response = mockResponse()
        let data = stubData()
        let session = MockPollerSession(data: data, response: response)
        let poller = createPoller(with: session)
        let expectation = XCTestExpectation(description: "Expect error to be nil.")
        poller.start() { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    private func createPoller(with session: PollerSession, url: URL? = nil) -> Poller {
        return Poller(refreshInterval: nil, unleashUrl: url ?? unleashUrl, apiKey: apiKey, context: Context(), session: session)
    }

    private func mockResponse(statusCode: Int = 200, headerFields: [String : String]? = nil) -> URLResponse {
        return HTTPURLResponse(url: unleashUrl, statusCode: statusCode, httpVersion: nil, headerFields: headerFields)!
    }

    private func stubData() -> Data {
        let stub: [String: Any] = [
            "toggles": [
                [
                    "name": "foo",
                    "enabled": true,
                    "variant": ["name": "disabled", "enabled": false]
                ],
                [
                    "name": "bar",
                    "enabled": false,
                    "variant": ["name": "disabled", "enabled": false]
                ]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: stub, options: .prettyPrinted)
    }
}
