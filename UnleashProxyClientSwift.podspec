Pod::Spec.new do |spec|
spec.name         = "UnleashProxyClientSwift"
spec.version      = "1.0.3"
spec.summary      = "Allows frontend clients to talk to unleash through the unleash edge, frontend API or the (deprecated) unleash proxy"
spec.homepage     = "https://www.getunleash.io"
spec.license      = { :type => "MIT", :file => "LICENSE" }
spec.author             = { "author" => "fredrik@getunleash.io" }
spec.documentation_url = "https://docs.getunleash.io/sdks/proxy-ios"
spec.platforms = { :ios => "12.0", :osx => "10.15" }
spec.swift_version = "5.1"
spec.source       = { :git => "https://github.com/Unleash/unleash-proxy-client-swift.git", :tag => "#{spec.version}" }
spec.source_files  = "Sources/UnleashProxyClientSwift/**/*.swift"
spec.xcconfig = { "SWIFT_VERSION" => "$(inherited)" }
spec.dependency 'SwiftEventBus'
end
