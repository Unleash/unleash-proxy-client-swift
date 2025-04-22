# Unleash Swift SDK

Unleash is a private, secure, and scalable [feature management platform](https://www.getunleash.io/) built to reduce the risk of releasing new features and accelerate software development. This client-side Swift SDK helps you integrate with Unleash and evaluate feature flags inside your application.

You can use this client with [Unleash Enterprise](https://www.getunleash.io/pricing?utm_source=readme&utm_medium=swift) or [Unleash Open Source](https://github.com/Unleash/unleash).

You can connect the SDK to Unleash in two ways:

- **Directly** to your Unleash instance using the [Frontend API](https://docs.getunleash.io/reference/front-end-api).
- **Using Unleash Edge**, a lightweight service acting as a caching and evaluation layer between the SDK and your main Unleash instance. [Unleash Edge](https://docs.getunleash.io/reference/unleash-edgefetches flag configurations, caches them in-memory, and handles evaluation locally for faster responses and high availability.

In both setups, the SDK retrieves feature flag configurations for the provided [context](https://docs.getunleash.io/docs/user_guide/unleash_context). The SDK caches the received flag configurations in memory and refreshes them periodically (at a configurable interval). This makes local evaluations like `isEnabled()` extremely fast.

> Note: If your current implementation relies on Unleash Proxy, please review our guide on how to [migrate to Unleash Edge](https://docs.getunleash.io/reference/unleash-edge/migration-guide).

## Requirements

- MacOS: 12.15
- iOS: 12

## Usage

To get started, import the SDK and initialize the Unleash client:

### iOS >= 13

```swift
import SwiftUI
import UnleashProxyClientSwift

// Setup Unleash in the context where it makes most sense

var unleash = UnleashProxyClientSwift.UnleashClient(
    unleashUrl: "https://<unleash-instance>/api/frontend",
    clientKey: "<client-side-api-token>", 
    refreshInterval: 15, 
    appName: "test", 
    context: ["userId": "c3b155b0-5ebe-4a20-8386-e0cab160051e"]
)

unleash.start()
```

### iOS >= 12

```swift
import SwiftUI
import UnleashProxyClientSwift

// Setup Unleash in the context where it makes most sense

var unleash = UnleashProxyClientSwift.UnleashClientBase(
    unleashUrl: "https://<unleash-instance>/api/frontend", 
    clientKey: "<client-side-api-token>", 
    refreshInterval: 15, 
    appName: "test", 
    context: ["userId": "c3b155b0-5ebe-4a20-8386-e0cab160051e"]
)

unleash.start()
```

In the example above we import the UnleashProxyClientSwift and instantiate the client. You need to provide the following parameters:

- `unleashUrl`: The full URL to either the [Unleash Frontend API](https://docs.getunleash.io/reference/front-end-api) or an [Unleash Edge instance](https://docs.getunleash.io/reference/unleash-edge) [String]
- `clientKey`: A [frontend API token](https://docs.getunleash.io/reference/api-tokens-and-client-keys#front-end-tokens) for authenticating with the Frontend API or Unleash Edge [String]
- `refreshInterval`: The polling interval in seconds, set to `0` to only poll once and disable a periodic polling [Int]
- `appName`: The application name identifier [String]
- `context`: Initial Unleash Context fields (like `userId`, `sessionId`, etc.), excluding `appName` and `environment` which are configured separately. [String: String]

Calling `unleash.start()` makes the initial request to retrieve the feature flag configuration and starts the background polling interval (if `refreshInterval > 0`).

> NOTE: Until the client fetches the initial configuration (signaled by the `ready` event), checking a feature flag might return the default value (often `false`). To ensure the configuration is loaded before checking flags, subscribe to the ready event. See the [Events](#events) section for details.

Once the configuration is loaded, you can check if a feature flag is enabled:

```swift
if unleash.isEnabled(name: "ios") {
    // do something
} else {
   // do something else
}
```

You can also set up [variants](https://docs.getunleash.io/docs/advanced/toggle_variants):

```swift
var variant = unleash.getVariant(name: "ios")
if variant.enabled {
    // do something
} else {
   // do something else
}
```

### Available options

The Unleash SDK accepts the following initialization options:

| option                | required | default                        | description                                                                                                                                                                                                                                               |
|-----------------------|----------|--------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| unleashUrl            | yes      | n/a                            | The Unleash Edge URL to connect to.                                                                                                                                                                              |
| clientKey             | yes      | n/a                            | The frontend token to use for authenticating with the Frontend API or Unleash Edge.                                                                                                                                                                                                                  |
| appName               | no       | unleash-swift-client           | The name of the application using this SDK. Sent with metrics to Unleash Edge and included in the Unleash Context.                                                                                                     |
| environment           | no       | default                        | The name of the environment. Sent with metrics to Unleash Edge and included in the Unleash Context.                                                                                                     |
| refreshInterval       | no       | 15                             | How often (in seconds) the SDK checks for updated flag configurations. Set to 0 to disable polling after initial fetch.                                                                                                                               |
| metricsInterval       | no       | 30                             | How often (in seconds) the SDK sends usage metrics back to Unleash Edge. |                                                                                                       |
| disableMetrics        | no       | false                          | Set this to `true` to disable usage metrics.                                                                                                                                                                                            |
| context               | no       | [:]                            | The initial context parameters excluding `appName` and `environment` which are specified as top level fields.                                                                                                                                             |
| poller                | no       | nil                            | A custom poller instance. If provided, the client ignores its own `refreshInterval`, `customHeaders`, `customHeadersProvider`, and `bootstrap` options. Use for advanced control or mocking.  |
| pollerSession         | no       | `URLSession.shared`            | Session object used for performing HTTP requests. You can provide a custom `PollerSession` for custom `URLSession` configuration or `URLRequest` interception.             |
| customHeaders         | no       | `[:]`                          | Additional headers to use when making HTTP requests to Unleash Edge. In case of name collisions with the default headers, the `customHeaders` value will be used.                                                                               |
| customHeadersProvider | no       | `DefaultCustomHeadersProvider` | Custom header provider for additional headers. In case of name collisions with the `customHeaders`, the `customHeadersProvider` value will be used.                                                                                                       |
| bootstrap             | no       | empty list of toggles          | Initial flag configurations provided to the Unleash client SDK. Can be a list of `Toggle` objects or the path to a JSON file matching the front-end API response format. Available immediately on init, before the first fetch. |

### Bootstrapping
You can provide the initial toggle state to the Unleash client SDK. This is useful when you have a known initial state for your feature toggles. This toggle state can be bootstrapped to the client via a list of toggles, or from a file matching a response from the [Frontend API](https://docs.getunleash.io/reference/front-end-api). For example:

#### Bootstrap from hard-coded list
```swift
// Note variant and payload can be optional.
let bootstrapList = Bootstrap
    .toggles(
        [
            Toggle(name: "Foo", enabled: true),
            Toggle(
                name: "Bar", 
                enabled: false, 
                variant: Variant(
                    name: "bar",
                    enabled: true,
                    featureEnabled: true,
                    payload: Payload(type: "string", value: "baz")
                )
            )
        ]
    )
```

#### Bootstrap from file matching Frontend API response
```json    
{
  "toggles": [
      {
        "name": "no-variant",
        "enabled": true
      },
      {
        "name": "disabled-with-variant-disabled-no-payload",
        "enabled": false,
        "variant": {
            "name": "foo",
            "enabled": false,
            "feature_enabled": false
        }
      },
      {
        "name": "enabled-with-variant-enabled-and-payload",
        "enabled": true,
        "variant": {
            "name": "bar",
            "enabled": true,
            "feature_enabled": true,
            "payload": {
                "type": "string",
                "value": "baz"
            }
        }
      }
  ]
}
```

```swift
guard let filePath = Bundle.main.path(forResource: "FeatureResponseFile", ofType: "json") else {
    // Handle missing file
}

let bootstrapFile = Bootstrap.jsonFile(path: filePath)
```

#### Using the bootstrap list of toggles
Whether from a hard-coded list, or a json file, the bootstrap toggles can be injected into the Unleash Edge or Proxy client either at initialisation time, or when calling start. For example:

```swift
import SwiftUI
import UnleashProxyClientSwift

// Setup Unleash in the context where it makes most sense

let unleash = UnleashClient(
    unleashUrl: "https://<unleash-instance>/api/frontend", 
    clientKey: "<client-side-api-token>",
    bootstrap: .toggles([Toggle(name: "Foo", enabled: true)])
)

// Toggles can be accessed now ahead of starting client
let isFooEnabled = unleash.isEnabled(name: "Foo") // true

// Or provide when starting in case of slow/faulty connection
unleash.start(bootstrap: .jsonFile("path/to/json/file"))

// Or using async-await concurrency (>= iOS13)
await unleash.start(bootstrap: .jsonFile("path/to/json/file"))
```

#### Important notices
- If you initialise the Unleash Edge client with a `Poller`, inject the bootstrap directly into the poller. **Any bootstrap data injected into the Unleash client options will be ignored when a custom poller is also provided.**
- Bootstrapped flag configurations are replaced entirely after the first successful fetch.
- If bootstrap flags are provided when calling start, the first fetch occurs after the configured `refreshInterval` (default 15 seconds).
- Calling `updateContext(...)` before the first fetch removes any bootstrapped flags.

### Update context

To update the context, use the following method:

```swift
var context: [String: String] = [:]
context["userId"] = "c3b155b0-5ebe-4a20-8386-e0cab160051e"
unleash.updateContext(context: context)
```

This will stop and start the polling interval in order to renew polling with new context values.

You can use any of the [predefined fields](https://docs.getunleash.io/reference/unleash-context#structure). If you need to support
[custom properties](https://docs.getunleash.io/reference/unleash-context#the-properties-field) pass them as the second argument:

```swift
var context: [String: String] = [:]
context["userId"] = "c3b155b0-5ebe-4a20-8386-e0cab160051e"
var properties: [String: String] = [:]
properties["customKey"] = "customValue";
unleash.updateContext(context: context, properties: properties)
```

### Custom PollerSession
If you want to use a custom `URLSession` or intercept `URLRequest` you can provide a custom `PollerSession` to the client.

```swift
class CustomPollerSession: PollerSession {
    func perform(_ request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        // Custom URLSession configuration
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30

        // Modify URLRequest if needed
        var modifiedRequest = request
        modifiedRequest.setValue("foo", forHTTPHeaderField: "bar")

        let session = URLSession(configuration: configuration)
        session.dataTask(with: modifiedRequest, completionHandler: completionHandler).resume()
    }
}

// Use when initializing Unleash client
var unleash = UnleashProxyClientSwift.UnleashClient(
    unleashUrl: unleashUrl,
    clientKey: clientKey,
    pollerSession: CustomPollerSession()
)
```

### Custom HTTP headers

If you want the client to send custom HTTP headers with all requests to the Unleash API you can define that by setting them via the `UnleashClientBase`.

Custom and dynamic custom headers does not apply to sensitive headers.
- `Content-Type`
- `If-None-Match`
- anything starting with `unleash-` (`unleash-appname`, `unleash-connection-id`, `unleash-sdk`, ...)

```swift
var unleash = UnleashProxyClientSwift.UnleashClientBase(
    unleashUrl: unleashUrl,
    clientKey: clientKey,
    refreshInterval: 15,
    appName: "test",
    context: ["userId": "c3b155b0-5ebe-4a20-8386-e0cab160051e"],
    customHeaders: ["X-Custom-Header": "CustomValue", "X-Another-Header": "AnotherValue"]
)
```

### Dynamic custom HTTP headers
If you need custom HTTP headers that change during the lifetime of the client, a provider can be defined via the `UnleashClientBase`.

```swift
public class MyCustomHeadersProvider: CustomHeadersProvider {
    public init() {}
    public func getCustomHeaders() -> [String: String] {
        let token = "Acquire or refresh token";
        return ["Authorization": token]
    }
}
```
```swift
let myCustomHeadersProvider: CustomHeadersProvider = MyCustomHeadersProvider()

var unleash = UnleashProxyClientSwift.UnleashClientBase(
        unleashUrl: unleashUrl,
        clientKey: clientKey,
        refreshInterval: 15,
        appName: "test",
        context: ["userId": "c3b155b0-5ebe-4a20-8386-e0cab160051e"],
        customHeadersProvider: myCustomHeadersProvider
)
```

## Events

The client emits events that you can subscribe to using the `subscribe(name:callback:)` method or the `UnleashEvent` enum.

### Standard events

- `ready` (`UnleashEvent.ready`): Emitted once the client has successfully fetched and cached the initial feature flag configurations.
- `update` (`UnleashEvent.update`): Emitted when a subsequent fetch results in a change to the feature flag configurations.
- `sent` (`UnleashEvent.sent`): Emitted when usage metrics have been successfully sent to the server.
- `error` (`UnleashEvent.error`): Emitted if an error occurs when trying to send metrics.

### Subscribing to standard events

```swift
func handleReady() {
    // do this when unleash is ready
}

unleash.subscribe(name: "ready", callback: handleReady)

func handleUpdate() {
    // do this when unleash is updated
}

unleash.subscribe(name: "update", callback: handleUpdate)
```

Alternatively you can use the enum `UnleashEvent`, for example:

```swift
unleash.subscribe(.ready, callback: handleUpdate)
```

### Impression data events

This SDK allows you to subscribe to [Impression Data](https://docs.getunleash.io/reference/impression-data) events. These events provide granular, real-time tracking of feature exposures. You must specifically [enable impression data](https://docs.getunleash.io/reference/impression-data#enabling-impression-data) for the feature flags you'd like to track.

When `isEnabled(name:)` or `getVariant(name:)` is called for a feature flag that has impression data enabled, the SDK creates an `ImpressionEvent` object that is broadcast internally using the event name `impression` (also accessible via the `UnleashEvent.impression` enum case).

### Subscribing to impression data events

```swift
import UnleashProxyClientSwift

// Define your handler that accepts the raw payload and casts to ImpressionEvent
func handleImpressionEvent(_ payload: Any?) {
    guard let impressionEvent = payload as? UnleashProxyClientSwift.ImpressionEvent else {
        // Optional: Log a warning if casting fails
        return
    }

    // Additional logic to send impression data to your analytics tool
}

// Subscribe to the impression event, providing the handler function
unleash.subscribe(.impression, callback: handleImpressionEvent)

// Or: unleash.subscribe(name: "impression", callback: handleImpressionEvent)

```

## Releasing

Note: To release the package you'll need to have [CocoaPods](https://cocoapods.org/) installed.

Update `Sources/Version/Version.swift` with the new version number. This version is used in `unleash-sdk` header as a version reported to Unleash server.

Then, add a Git tag matching the version number. Releasing the tag is sufficient for the Swift package manager, but you might also want to ensure CocoaPods users can also consume the code.

```sh
git tag -a 0.0.4 -m "v0.0.4"
```

Please make sure that the tag is pushed to the remote.

The next few commands assume that you have CocoaPods installed and available on your shell.

First, validate your session with CocoaPods with the following command:

```sh
pod trunk register <email> "Your name"
```

The email that owns this package is the general Unleash team email. CocoaPods will send a link to this email, click it to validate your shell session.

Bump the version number of the package, you can find this in `UnleashProxyClientSwift.podspec`, we use SemVer for this project. Once that's committed and merged to main:

Linting the podspec is always a good idea:

```sh
pod spec lint UnleashProxyClientSwift.podspec
```

Once that succeeds, you can do the actual release:

```sh
pod trunk push UnleashProxyClientSwift.podspec --allow-warnings
```

## Testing

In order to test this package you can run the `swift test` command. To test thread safety, run `swift test` with:

```
swift test --sanitize=thread
```

This gives you warnings in the console when you have any data races.

## Installation

Follow the following steps in order to install the unleash-proxy-client-swift:

1. In your Xcode project go to File -> Swift Packages -> Add Package Dependency
2. Supply the link to this repository
3. Set the appropriate package constraints (typically up to next major version)
4. Let Xcode find and install the necessary packages

Once you're done, you should see SwiftEventBus and UnleashProxyClientSwift listed as dependencies in the file explorer of your project.


## Upgrade guide from 1.x -> 2.x
In 2.0.0 the StorageProvider public interface [was changed](https://github.com/Unleash/unleash-proxy-client-swift/pull/113) to be more in line with other SDKs. Specifically the set method was changed to accept all flags at once. It now has the following interface: 
```
func set(values: [String: Toggle])
```

If you are running with your own StorageProvider implementation you'll need to make changes to your implementation.