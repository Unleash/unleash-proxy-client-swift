    import XCTest
    @testable import UnleashProxyClientSwift

    final class unleash_proxy_client_swiftTests: XCTestCase {
        func testExample() {
            // This is an example of a functional test case.
            // Use XCTAssert and related functions to verify your tests produce the correct
            // results.
            //
            
            func handleReady() {
                XCTAssert(unleash.ready == false)
            }
            
            let unleash = UnleashProxyClientSwift.UnleashClient(unleashUrl: "https://app.unleash-hosted.com/hosted/api/proxy", clientKey: "dss22d", refreshInterval: 15, appName: "test", environment: "dev")
            
            unleash.start()
            unleash.subscribe(name: "ready", callback: handleReady)
            XCTAssert(unleash.ready == false)
        }
    }
