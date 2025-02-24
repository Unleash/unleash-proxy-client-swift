import Foundation

public class DictionaryStorageProvider: StorageProvider {
    private var storage: [String: Toggle] = [:]
    private let queue = DispatchQueue(label: "com.unleash.storageprovider")

    public init() {}

    public func set(values: [String: Toggle]) {
        queue.async {
            self.storage = values
        }
    }

    public func value(key: String) -> Toggle? {
        queue.sync {
            return self.storage[key]
        }
    }
    
    public func clear() {
        queue.sync {
            self.storage = [:]
        }
    }
}
