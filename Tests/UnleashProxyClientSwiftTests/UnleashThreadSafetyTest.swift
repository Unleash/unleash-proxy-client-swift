@testable import UnleashProxyClientSwift
import XCTest

class UnleashThreadSafetyTest: XCTestCase {
    private var shouldRunIntensiveTest: Bool {
        return ProcessInfo.processInfo.environment["UNLEASH_THREAD_SAFETY_TEST"] == "1"
    }

    func testThreadSafety() {
        // Skip the test unless the environment variable is set
        guard shouldRunIntensiveTest else {
            print("Skipping UnleashThreadSafetyTest - set UNLEASH_THREAD_SAFETY_TEST=1 to run")
            return
        }

        // This test demonstrates the thread safety of UnleashClient
        // by simulating concurrent access from multiple threads to the same client instance

        // Create an expectation to ensure the test doesn't hang
        let expectation = XCTestExpectation(description: "Thread safety test completed")

        // Create a shared client instance
        let client = UnleashClientBase(
            unleashUrl: "https://sandbox.getunleash.io/enterprise/api/frontend",
            clientKey: "SDKIntegration:development.f0474f4a37e60794ee8fb00a4c112de58befde962af6d5055b383ea3",
            appName: "testIntegration"
        )

        // Start the client on the main thread
        client.start()

        // Run the test with high iteration count to increase chances of detecting race conditions
        for _ in 0 ..< 10000 {
            // Update context with userId and isAuthenticated properties
            client.updateContext(context: ["userId": "1"], properties: ["isAuthenticated": "true"]) { _ in }

            // Background thread 1: Check if boolean parameter is enabled
            DispatchQueue.global(qos: .userInitiated).async {
                _ = client.isEnabled(name: "bool_parameter")
            }

            // Background thread 2: Start client with bootstrap toggles
            DispatchQueue.global(qos: .utility).async {
                client.start(bootstrap: .toggles([]), false) { _ in }
            }

            // Background thread 3: Get variant for string parameter
            DispatchQueue.global(qos: .default).async {
                _ = client.getVariant(name: "string_parameter")
            }
        }

        // Use a background queue to avoid blocking the main thread
        DispatchQueue.global().async {
            // Give background operations a chance to complete
            Thread.sleep(forTimeInterval: 2.0)

            // Clean up
            client.stop()

            // Mark the expectation as fulfilled
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled with a timeout
        wait(for: [expectation], timeout: 10.0) // 10 second timeout
    }
}
