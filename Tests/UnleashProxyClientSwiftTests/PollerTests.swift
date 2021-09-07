import XCTest
@testable import UnleashProxyClientSwift

final class PollerTests: XCTestCase {

    private let unleashUrl = "https://app.unleash-hosted.com/hosted/api/proxy"
    private let apiKey = "SECRET"

    func testTitleCaseEtagResponseHeader() {
        let response = mockResponse(headerFields: ["Etag": "W/\"77f-WboeNIYTrCbEJ+TK78VuhInQn2M\""])
        let data = stubData()
        let session = MockPollerSession(data: data, response: response)
        let poller = createPoller(with: session)

        XCTAssertTrue(poller.etag.isEmpty)
        poller.getFeatures(context: [:])
        XCTAssertEqual(poller.etag, "W/\"77f-WboeNIYTrCbEJ+TK78VuhInQn2M\"")
    }

    func testLowerCaseEtagResponseHeader() {
        let response = mockResponse(headerFields: ["etag": "W/\"710-wJiNH+MQpj0ruMo7n/9j36tB+Fg\""])
        let data = stubData()
        let session = MockPollerSession(data: data, response: response)
        let poller = createPoller(with: session)

        XCTAssertTrue(poller.etag.isEmpty)
        poller.getFeatures(context: [:])
        XCTAssertEqual(poller.etag, "W/\"710-wJiNH+MQpj0ruMo7n/9j36tB+Fg\"")
    }

    func testEmptyEtagResponseHeader() {
        let response = mockResponse(headerFields: ["Etag": ""])
        let data = stubData()
        let session = MockPollerSession(data: data, response: response)
        let poller = createPoller(with: session)
        poller.etag = "W/\"7c-GUwjw43L+nPpd9TY5PHtsXJueiM\""

        XCTAssertEqual(poller.etag, "W/\"7c-GUwjw43L+nPpd9TY5PHtsXJueiM\"")
        poller.getFeatures(context: [:])
        XCTAssertEqual(poller.etag, "W/\"7c-GUwjw43L+nPpd9TY5PHtsXJueiM\"")
    }

    private func createPoller(with session: PollerSession) -> Poller {
        return Poller(refreshInterval: nil, unleashUrl: unleashUrl, apiKey: apiKey, session: session)
    }

    private func mockResponse(statusCode: Int = 200, headerFields: [String : String]? = nil) -> URLResponse {
        return HTTPURLResponse(url: URL(string: unleashUrl)!, statusCode: statusCode, httpVersion: nil, headerFields: headerFields)!
    }

    private func stubData() -> Data {
        let stub: [String: Any] = [
            "toggles": [
                [ "name": "foo", "enabled": true ],
                [ "name": "bar", "enabled": false ]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: stub, options: .prettyPrinted)
    }
}
