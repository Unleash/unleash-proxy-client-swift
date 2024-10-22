@testable import UnleashProxyClientSwift

import Foundation
import XCTest

final class BootstrapTests: XCTestCase {
    /// GIVEN a Bootstrap .toggles, WHEN access toggles returns input toggles
    func testTogglesWhenBootstrapToggles() {
        let stubToggle = Toggle(name: "foo", enabled: true)
        let bootstrap = Bootstrap.toggles([stubToggle])
        
        XCTAssertEqual(bootstrap.toggles, [stubToggle])
    }
    
    
    /// GIVEN a Bootstrap jsonFile, WHEN file does not exist, THEN toggles returns empty array
    func testTogglesWhenJsonFileDoesNotExist() {
        let bootstrap = Bootstrap.jsonFile(path: "")
        XCTAssertTrue(bootstrap.toggles.isEmpty)
    }
    
    /// GIVEN a Bootstrap jsonFile, WHEN file exists, THEN toggles returns expected toggles
    func testTogglesWhenJsonFileExists() throws {
        let path = try XCTUnwrap(
            Bundle.module
                .path(forResource: "FeatureResponseStub", ofType: "json")
        )
        
        let bootstrap = Bootstrap.jsonFile(path: path)
        
        let expectedToggles = [
            Toggle(name: "no-variant", enabled: true, variant: nil),
            Toggle(
                name: "disabled-with-variant-disabled-no-payload",
                enabled: false,
                variant: .init(name: "foo", enabled: false, featureEnabled: false)
            ),
            Toggle(
                name: "enabled-with-variant-enabled-and-payload",
                enabled: true,
                variant: .init(
                    name: "bar",
                    enabled: true,
                    featureEnabled: true,
                    payload: .init(type: "string", value: "baz")
                )
            )
        ]
        
        XCTAssertEqual(bootstrap.toggles, expectedToggles)
    }
}
