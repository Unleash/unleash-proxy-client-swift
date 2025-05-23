import XCTest
@testable import UnleashProxyClientSwift

// MARK: UnleashProxyClient tests
@available(iOS 13, *)
final class unleash_proxy_client_swiftTests: XCTestCase {
    func testIsEnabled() {
        func dataGenerator() -> [String: UnleashProxyClientSwift.Toggle] {
            return generateBasicTestToggleMap()
        }
        
        let unleash = setup(dataGenerator: dataGenerator)
        
        XCTAssert(unleash.isEnabled(name: "Test") == true)
        XCTAssert(unleash.isEnabled(name: "TestTwo") == false)
        XCTAssert(unleash.isEnabled(name: "DoesNotExist") == false)
        let expectedToggleMetrics = ["TestTwo": UnleashProxyClientSwift.ToggleMetrics(yes: 0, no: 1, variants: [:]), "DoesNotExist": UnleashProxyClientSwift.ToggleMetrics(yes: 0, no: 1, variants: [:]), "Test": UnleashProxyClientSwift.ToggleMetrics(yes: 1, no: 0, variants: [:])];
        XCTAssertEqual(unleash.metrics.bucket.toggles, expectedToggleMetrics);
    }
    
    func testGetVariant() {
        func dataGenerator() -> [String: UnleashProxyClientSwift.Toggle] {
            return generateTestToggleMapWithVariant()
        }
        
        let unleash = setup(dataGenerator: dataGenerator)
        
        let variantA = unleash.getVariant(name: "Test")
        let variantB = unleash.getVariant(name: "TestTwo")
        let variantC = unleash.getVariant(name: "DoesNotExist")
        
        XCTAssert(variantA.name == "TestA" && variantA.enabled == true)
        XCTAssert(variantB.name == "TestB" && variantB.enabled == false)
        XCTAssert(variantC.name == "disabled") // change this to empty variant - name: disabled - enabled: false - empty payload
        let expectedToggleMetrics = ["TestTwo": UnleashProxyClientSwift.ToggleMetrics(yes: 1, no: 0, variants: ["TestB": 1]), "DoesNotExist": UnleashProxyClientSwift.ToggleMetrics(yes: 0, no: 1, variants: ["disabled": 1]), "Test": UnleashProxyClientSwift.ToggleMetrics(yes: 1, no: 0, variants: ["TestA": 1])];
        XCTAssertEqual(unleash.metrics.bucket.toggles, expectedToggleMetrics);
        
    }
    
    func testTimer() {
        func dataGenerator() -> [String: UnleashProxyClientSwift.Toggle] {
            return generateTestToggleMapWithVariant()
        }
        
        let unleash = setup(dataGenerator: dataGenerator)
        
        XCTAssert(unleash.poller.timer != nil)
    }
    
    @MainActor
    func testTimerWithAsyncStart() async throws {
        func dataGenerator() -> [String: UnleashProxyClientSwift.Toggle] {
            generateTestToggleMapWithVariant()
        }
        
        let mockedPoller = MockPollerSession()
        let unleash = try await setup(
            dataGenerator: dataGenerator,
            session: mockedPoller
        )
        
        XCTAssert(unleash.poller.timer != nil)
    }
    
    @MainActor
    func testGivenBootstrapWhenAsyncStartThenPassedToPoller() async throws {
        let stubToggle = Toggle(name: "Foo", enabled: false)
        
        let unleash = try await setup(dataGenerator: { [:] })
        
        XCTAssertNil(unleash.poller.getFeature(name: stubToggle.name))
        
        try await unleash.start(bootstrap: .toggles([stubToggle]))
        XCTAssertEqual(
            unleash.poller.getFeature(name: "Foo"),
            Toggle(name: "Foo", enabled: false)
        )
    }
    
    func testUpdateContext() {
        func dataGenerator() -> [String: UnleashProxyClientSwift.Toggle] {
            return generateTestToggleMapWithVariant()
        }
        
        let stubPrintToConsoleAtStart = true
        let unleash = setup(
            dataGenerator: dataGenerator,
            printToConsole: stubPrintToConsoleAtStart
        )
        
        var context: [String: String] = [:]
        context["userId"] = "uuid-123-test"
        context["sessionId"] = "uuid-234-test"
        unleash.updateContext(context: context)
        
        let url = unleash.poller.formatURL(context: unleash.context)!.absoluteString
        
        XCTAssert(url.contains("appName=test") && url.contains("sessionId=uuid-234-test") && url.contains("userId=uuid-123-test") && url.contains("environment=dev"))
        XCTAssertEqual(Printer.showPrintStatements, stubPrintToConsoleAtStart)
    }
    
    @MainActor
    func testUpdateContextAsync() async throws {
        func dataGenerator() -> [String: UnleashProxyClientSwift.Toggle] {
            return generateTestToggleMapWithVariant()
        }
        
        let unleash = try await setup(dataGenerator: dataGenerator)
        
        var context: [String: String] = [:]
        context["userId"] = "uuid-123-test"
        context["sessionId"] = "uuid-234-test"
        try await unleash.updateContext(context: context)
        
        let url = unleash.poller.formatURL(context: unleash.context)!.absoluteString
        
        XCTAssert(url.contains("appName=test") && url.contains("sessionId=uuid-234-test") && url.contains("userId=uuid-123-test") && url.contains("environment=dev"))
    }
}

// MARK: UnleashProxyClientBase tests
final class unleash_proxy_client_base_swiftTests: XCTestCase {
    func testInitWithBootstrapAndNoPollerInitialisesPollerWithBootstrap() {
        let unleash = UnleashClientBase(
            unleashUrl: "https://app.unleash-hosted.com/hosted/api/proxy",
            clientKey: "SECRET",
            bootstrap: .toggles([Toggle(name: "Foo", enabled: false)])
        )
        
        XCTAssertEqual(
            unleash.poller.getFeature(name: "Foo"),
            Toggle(name: "Foo", enabled: false)
        )
    }
    
    func testGivenBootstrapWhenStartThenPassedToPoller() {
        let stubToggle = Toggle(name: "Foo", enabled: false)
        
        let unleash = setupBase(dataGenerator: { [:] })
        
        XCTAssertNil(unleash.poller.getFeature(name: stubToggle.name))
        
        unleash.start(bootstrap: .toggles([stubToggle]))
        XCTAssertEqual(
            unleash.poller.getFeature(name: "Foo"),
            Toggle(name: "Foo", enabled: false)
        )
    }
    
    func testIsEnabled() {
        func dataGenerator() -> [String: UnleashProxyClientSwift.Toggle] {
            generateBasicTestToggleMap()
        }
        
        let unleash = setupBase(dataGenerator: dataGenerator)
        
        XCTAssert(unleash.isEnabled(name: "Test") == true)
        XCTAssert(unleash.isEnabled(name: "TestTwo") == false)
        XCTAssert(unleash.isEnabled(name: "DoesNotExist") == false)
        let expectedToggleMetrics = [
            "TestTwo": UnleashProxyClientSwift.ToggleMetrics(yes: 0, no: 1, variants: [:]),
            "DoesNotExist": UnleashProxyClientSwift.ToggleMetrics(yes: 0, no: 1, variants: [:]),
            "Test": UnleashProxyClientSwift.ToggleMetrics(yes: 1, no: 0, variants: [:])
        ]
        XCTAssertEqual(unleash.metrics.bucket.toggles, expectedToggleMetrics)
    }
    
    func testGetVariant() {
        func dataGenerator() -> [String: UnleashProxyClientSwift.Toggle] {
            return generateTestToggleMapWithVariant()
        }
        
        let unleash = setupBase(dataGenerator: dataGenerator)
        
        let variantA = unleash.getVariant(name: "Test")
        let variantB = unleash.getVariant(name: "TestTwo")
        let variantC = unleash.getVariant(name: "DoesNotExist")
        
        XCTAssert(variantA.name == "TestA" && variantA.enabled == true)
        XCTAssert(variantB.name == "TestB" && variantB.enabled == false)
        XCTAssert(variantC.name == "disabled") // change this to empty variant - name: disabled - enabled: false - empty payload
        let expectedToggleMetrics = ["TestTwo": UnleashProxyClientSwift.ToggleMetrics(yes: 1, no: 0, variants: ["TestB": 1]), "DoesNotExist": UnleashProxyClientSwift.ToggleMetrics(yes: 0, no: 1, variants: ["disabled": 1]), "Test": UnleashProxyClientSwift.ToggleMetrics(yes: 1, no: 0, variants: ["TestA": 1])];
        XCTAssertEqual(unleash.metrics.bucket.toggles, expectedToggleMetrics);
        
    }
    
    func testTimer() {
        func dataGenerator() -> [String: UnleashProxyClientSwift.Toggle] {
            return generateTestToggleMapWithVariant()
        }
        
        let unleash = setupBase(dataGenerator: dataGenerator)
        
        XCTAssert(unleash.poller.timer != nil)
    }
    
    func testUpdateContext() {
        func dataGenerator() -> [String: UnleashProxyClientSwift.Toggle] {
            return generateTestToggleMapWithVariant()
        }
        
        let unleash = setupBase(dataGenerator: dataGenerator)
        
        var context: [String: String] = [:]
        context["userId"] = "uuid 123+test"
        context["sessionId"] = "uuid-234-test"
        context["customContextKeyWorksButPreferProperties"] = "someValue";
        var properties: [String: String] = [:]
        properties["customKey"] = "customValue";
        properties["custom+Key"] = "custom+Value";
        
        unleash.updateContext(context: context, properties: properties)
        
        let url = unleash.poller.formatURL(context: unleash.context)!.absoluteString
        
        XCTAssert(url.contains("appName=test"), url)
        XCTAssert(url.contains("sessionId=uuid-234-test"), url)
        XCTAssert(url.contains("userId=uuid%20123%2Btest"), url)
        XCTAssert(url.contains("environment=dev"), url)
        XCTAssert(url.contains("properties%5BcustomKey%5D=customValue"), url)
        XCTAssert(url.contains("properties%5BcustomContextKeyWorksButPreferProperties%5D=someValue"), url)
        XCTAssert(url.contains("properties%5Bcustom%2BKey%5D=custom%2BValue"), url)
    }
}
