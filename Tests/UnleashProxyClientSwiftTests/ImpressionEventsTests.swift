import XCTest
import SwiftEventBus
@testable import UnleashProxyClientSwift

class ImpressionEventsTests: XCTestCase {
    struct TestData {
        static let toggleWithImpressionData = Toggle(
            name: "test-toggle-impression",
            enabled: true,
            impressionData: true,
            variant: nil
        )
        
        static let toggleWithoutImpressionData = Toggle(
            name: "test-toggle-no-impression",
            enabled: true,
            impressionData: false,
            variant: nil
        )
        
        static let toggleWithVariant = Toggle(
            name: "test-toggle-variant",
            enabled: true,
            impressionData: true,
            variant: Variant(name: "test-variant", enabled: true)
        )
    }
    
    func setup(toggles: [Toggle] = []) -> UnleashClient {
        let client = UnleashClient(
            unleashUrl: "https://test-setup.com",
            clientKey: "test-setup-key",
            context: ["appName": "test-app", "environment": "test", "userId": "test-user"]
        )
        client.start(bootstrap: .toggles(toggles))
        return client
    }
    
    func testImpressionEventEmittedWhenImpressionDataEnabled() {
        let toggle = TestData.toggleWithImpressionData
        let client = setup(toggles: [toggle])
        let expectation = XCTestExpectation(description: "Impression event received for enabled test")
        
        client.subscribe(.impression) { object in
            guard let impressionEvent = object as? ImpressionEvent else {
                XCTFail("Expected ImpressionEvent")
                return
            }
    
            XCTAssertEqual(impressionEvent.toggleName, toggle.name)
            XCTAssertEqual(impressionEvent.enabled, toggle.enabled)

            XCTAssertNil(impressionEvent.variant)
            expectation.fulfill()
        }
        
        _ = client.isEnabled(name: toggle.name)
        wait(for: [expectation], timeout: 1.0)
        client.stop();
    }
    
    func testNoImpressionEventWhenImpressionDataDisabled() {
        let toggle = TestData.toggleWithoutImpressionData
        let client = setup(toggles: [toggle])
        
        let expectation = XCTestExpectation(description: "No impression event expected")
        expectation.isInverted = true
        client.subscribe(.impression) { _ in expectation.fulfill() }
        _ = client.isEnabled(name: toggle.name)
        wait(for: [expectation], timeout: 0.1)
        client.stop();
    }
    
    func testImpressionEventWithVariantData() {
        let toggle = TestData.toggleWithVariant
        let client = setup(toggles: [toggle])
        let expectation = XCTestExpectation(description: "Impression event received for variant test")
        

        client.subscribe(.impression) { object in
            guard let impressionEvent = object as? ImpressionEvent else {
                XCTFail("Expected ImpressionEvent, got \(String(describing: object))")
                return
            }
            
            print("impressionEventVariant: \(impressionEvent)")
            print("impressionEvent.toggleName: \(impressionEvent.toggleName)")
            print("testData.toggleName: \(TestData.toggleWithVariant.name)")
            XCTAssertEqual(impressionEvent.toggleName, TestData.toggleWithVariant.name)
            XCTAssertEqual(impressionEvent.enabled, toggle.enabled)
            XCTAssertNotNil(impressionEvent.variant)
            XCTAssertEqual(impressionEvent.variant?.name, toggle.variant?.name)
            expectation.fulfill()
        }
        
        _ = client.getVariant(name: toggle.name)
        wait(for: [expectation], timeout: 1.0)
        client.stop();
    }
    
    func testNoImpressionEventWhenToggleNotFound() {
        let nonExistentToggle = "non-existent-toggle"
        let client = setup(toggles: [])
    
        let expectation = XCTestExpectation(description: "No impression event expected")
        expectation.isInverted = true
        client.subscribe(.impression) { _ in expectation.fulfill() }
        _ = client.isEnabled(name: nonExistentToggle)
        wait(for: [expectation], timeout: 0.1)
        client.stop();
    }
} 