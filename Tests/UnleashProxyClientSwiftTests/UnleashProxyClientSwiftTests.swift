    import XCTest
    @testable import UnleashProxyClientSwift

    final class unleash_proxy_client_swiftTests: XCTestCase {
        func testIsEnabled() {
            func dataGenerator() -> [String: UnleashProxyClientSwift.Toggle] {
                return generateBasicTestToggleMap()
            }
            
            let unleash = setup(dataGenerator: dataGenerator)
            
            XCTAssert(unleash.isEnabled(name: "Test") == true)
            XCTAssert(unleash.isEnabled(name: "TestTwo") == false)
            XCTAssert(unleash.isEnabled(name: "DoesNotExist") == false)
        }
        
        func testGetVariant() {
            func dataGenerator() -> [String: UnleashProxyClientSwift.Toggle] {
                return generateTestToggleMapWithVariant()
            }
            
            let unleash = setup(dataGenerator: dataGenerator)
        
            let variantA = unleash.getVariant(name: "Test")
            let variantB = unleash.getVariant(name: "TestTwo")
            let variantC = unleash.getVariant(name: "DoesNotExist")
           
            XCTAssert(variantA!.name == "TestA" && variantA!.enabled == true)
            XCTAssert(variantB!.name == "TestB" && variantB!.enabled == false)
            XCTAssert(variantC == nil)
        }
        
        func testTimer() {
            func dataGenerator() -> [String: UnleashProxyClientSwift.Toggle] {
                return generateTestToggleMapWithVariant()
            }
            
            let unleash = setup(dataGenerator: dataGenerator)
            
            XCTAssert(unleash.poller.timer != nil)
        }
        
        func testUpdateContext() {
            func dataGenerator() -> [String: UnleashProxyClientSwift.Toggle] {
                return generateTestToggleMapWithVariant()
            }
            
            let unleash = setup(dataGenerator: dataGenerator)
            
            var context: [String: String] = [:]
            context["userId"] = "uuid-123-test"
            context["sessionId"] = "uuid-234-test"
            unleash.updateContext(context: context)
            
            let url = unleash.poller.formatURL(context: unleash.context)
            
            XCTAssert(url.contains("appName=test") && url.contains("sessionId=uuid-234-test") && url.contains("userId=uuid-123-test") && url.contains("environment=dev"))
        }
    }
