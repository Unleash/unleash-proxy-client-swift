import XCTest
@testable import UnleashProxyClientSwift

final class PollerTests: XCTestCase {

    private let unleashUrl = URL(string: "https://app.unleash-hosted.com/hosted/api/proxy")!
    private let apiKey = "SECRET"
    private let appName = "APPNAME"
    private let connectionId = UUID(uuidString: "123E4567-E89B-12d3-A456-426614174000")!
    private let timeout = 1.0

    func testWhenInitWithBootstrapTogglesThenAddToStore() {
        let stubToggles = [
            Toggle(name: "Foo", enabled: false),
            Toggle(
                name: "Bar",
                enabled: true,
                variant: .init(
                    name: "Baz",
                    enabled: false,
                    featureEnabled: true,
                    payload: .init(type: "string", value: "FooBarBaz")
                )
            )
        ]
        
        let poller = createPoller(
            with: MockPollerSession(),
            bootstrap: .toggles(stubToggles)
        )
        
        let foo = poller.getFeature(name: "Foo")
        let bar = poller.getFeature(name: "Bar")
        
        XCTAssertEqual(foo, stubToggles.first!)
        XCTAssertEqual(bar, stubToggles.last!)
    }
    
    func testWhenInitWithBootstrapFileThenAddToStore() {
        let poller = createPoller(
            with: MockPollerSession(),
            bootstrap: .jsonFile(
                path: Bundle.module.path(
                    forResource: "FeatureResponseStub", ofType: "json"
                ) ?? ""
            )
        )

        XCTAssertEqual(
            poller.getFeature(name: "no-variant"),
            Toggle(name: "no-variant", enabled: true)
        )
        
        XCTAssertEqual(
            poller.getFeature(
                name: "disabled-with-variant-disabled-no-payload"
            ),
            Toggle(
                name: "disabled-with-variant-disabled-no-payload",
                enabled: false,
                variant: .init(
                    name: "foo",
                    enabled: false,
                    featureEnabled: false
                )
            )
        )
        
        XCTAssertEqual(
            poller.getFeature(
                name: "enabled-with-variant-enabled-and-payload"
            ),
            Toggle(
                name: "enabled-with-variant-enabled-and-payload",
                enabled: true,
                variant: .init(
                    name: "bar",
                    enabled: true,
                    featureEnabled: true,
                    payload: .init(
                        type: "string",
                        value: "baz"
                    )
                )
            )
        )
    }
    
    func testTitleCaseEtagResponseHeader() {
        let response = mockResponse(headerFields: ["Etag": "W/\"77f-WboeNIYTrCbEJ+TK78VuhInQn2M\""])
        let data = stubData()
        let session = MockPollerSession(data: data, response: response)
        let poller = createPoller(with: session)

        XCTAssertTrue(poller.etag.isEmpty)
        poller.getFeatures(context: Context())
        XCTAssertEqual(poller.etag, "W/\"77f-WboeNIYTrCbEJ+TK78VuhInQn2M\"")
    }

    func testLowerCaseEtagResponseHeader() {
        let response = mockResponse(headerFields: ["etag": "W/\"710-wJiNH+MQpj0ruMo7n/9j36tB+Fg\""])
        let data = stubData()
        let session = MockPollerSession(data: data, response: response)
        let poller = createPoller(with: session)

        XCTAssertTrue(poller.etag.isEmpty)
        poller.getFeatures(context: Context())
        XCTAssertEqual(poller.etag, "W/\"710-wJiNH+MQpj0ruMo7n/9j36tB+Fg\"")
    }

    func testEmptyEtagResponseHeader() {
        let response = mockResponse(headerFields: ["Etag": ""])
        let data = stubData()
        let session = MockPollerSession(data: data, response: response)
        let poller = createPoller(with: session)
        poller.etag = "W/\"7c-GUwjw43L+nPpd9TY5PHtsXJueiM\""

        XCTAssertEqual(poller.etag, "W/\"7c-GUwjw43L+nPpd9TY5PHtsXJueiM\"")
        poller.getFeatures(context: Context())
        XCTAssertEqual(poller.etag, "W/\"7c-GUwjw43L+nPpd9TY5PHtsXJueiM\"")
    }

    func testStartCompletesWithoutErrorWhenDataEmpty() {
        let response = mockResponse()
        let session = MockPollerSession(data: nil, response: response)
        let poller = createPoller(with: session)
        let expectation = XCTestExpectation(description: "Expect .data PollerError.")
        poller.start(context: Context()) { error in
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
        poller.start(context: Context()) { error in
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
            poller.start(context: Context()) { error in
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
        poller.start(context: Context()) { error in
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
        poller.start(context: Context()) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }
    
    func testCustomHeaders() {
        let customHeaders: [String: String] = ["X-Custom-Header": "CustomValue", "X-Another-Header": "AnotherValue"]
        let response = mockResponse()
        let data = stubData()
        let session = MockPollerSession(data: data, response: response)
        let poller = Poller(refreshInterval: nil, unleashUrl: unleashUrl, apiKey: apiKey, session: session, customHeaders: customHeaders, appName: appName, connectionId: connectionId)

        let expectation = XCTestExpectation(description: "Expect custom headers to be set in the request.")

        session.performRequestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom-Header"), "CustomValue")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Another-Header"), "AnotherValue")
            XCTAssertEqual(request.value(forHTTPHeaderField: "x-unleash-appname"), "APPNAME")
            XCTAssertEqual(request.value(forHTTPHeaderField: "x-unleash-connection-id"), "123E4567-E89B-12D3-A456-426614174000")
            XCTAssertTrue(request.value(forHTTPHeaderField: "x-unleash-sdk")!.range(of: #"^unleash-client-swift:\d+\.\d+\.\d+$"#, options: .regularExpression) != nil, "x-unleash-sdk header sdk:semver format does not match")
            expectation.fulfill()
        }

        poller.getFeatures(context: Context())
        wait(for: [expectation], timeout: timeout)
    }
    
    func testGivenBoostrappingTogglesWhenStartThenSetToggles() {
        let stubToggles = [
            Toggle(name: "Foo", enabled: false),
            Toggle(
                name: "Bar",
                enabled: true,
                variant: .init(
                    name: "Baz",
                    enabled: false,
                    featureEnabled: true,
                    payload: .init(type: "string", value: "FooBarBaz")
                )
            )
        ]
        
        let poller = createPoller(with: MockPollerSession())
        
        XCTAssertNil(poller.getFeature(name: "Foo"))
        XCTAssertNil(poller.getFeature(name: "Bar"))
        
        poller.start(bootstrapping: stubToggles, context: Context())
        
        XCTAssertEqual(poller.getFeature(name: "Foo"), stubToggles.first!)
        XCTAssertEqual(poller.getFeature(name: "Bar"), stubToggles.last!)
    }

    func testTimerNotInitializedWhenRefreshIntervalIsZero() {
        let poller = Poller(
            refreshInterval: 0,
            unleashUrl: unleashUrl,
            apiKey: apiKey,
            session: MockPollerSession(),
            appName: appName,
            connectionId: connectionId
        )
        
        XCTAssertNil(poller.timer, "Timer should not be initialized when refreshInterval is zero")
    }

    private func createPoller(
        with session: PollerSession,
        url: URL? = nil,
        bootstrap: Bootstrap = .toggles([])
    ) -> Poller {
        Poller(
            refreshInterval: nil,
            unleashUrl: url ?? unleashUrl,
            apiKey: apiKey,
            session: session,
            bootstrap: bootstrap,
            appName: appName,
            connectionId: connectionId
        )
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
