import XCTest
@testable import UnleashProxyClientSwift

class UnleashIntegrationTests: XCTestCase {

    var unleashClient: UnleashProxyClientSwift.UnleashClientBase!
    let featureName = "enabled-feature"
    
    override func setUpWithError() throws {
        unleashClient = UnleashProxyClientSwift.UnleashClientBase(
            unleashUrl: "https://sandbox.getunleash.io/enterprise/api/frontend",
            clientKey: "SDKIntegration:development.f0474f4a37e60794ee8fb00a4c112de58befde962af6d5055b383ea3",
            refreshInterval: 15,
            appName: "testIntegration"
        )
    }

    override func tearDownWithError() throws {
        unleashClient.stop()
    }

    func testEnabledFeatureWithVariant() {
        let expectation = self.expectation(description: "Waiting for client ready")

        unleashClient.subscribe(name: "ready", callback: {
            XCTAssertTrue(self.unleashClient.isEnabled(name: self.featureName), "Feature should be enabled")
            
            let variant = self.unleashClient.getVariant(name: self.featureName)
            XCTAssertNotNil(variant, "Variant should not be nil")
            XCTAssertTrue(variant.enabled, "Variant should be enabled")
            
            expectation.fulfill()
        })

        unleashClient.start()

        wait(for: [expectation], timeout: 40)
    }
    
}
