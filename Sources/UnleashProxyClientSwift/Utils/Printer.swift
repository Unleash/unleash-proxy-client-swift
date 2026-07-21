//
//  Printer.swift
//
//
//  Created by Daniel Chick on 11/2/22.
//

import Foundation

class Printer {
    private static let lock = NSLock()
    private static var _showPrintStatements = false

    static var showPrintStatements: Bool {
        get {
            lock.lock()
            let value = _showPrintStatements
            lock.unlock()
            return value
        }
        set {
            lock.lock()
            _showPrintStatements = newValue
            lock.unlock()
        }
    }

    static func printMessage(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        lock.lock()
        let shouldPrint = _showPrintStatements
        lock.unlock()

        if shouldPrint {
            print(items, separator: separator, terminator: terminator)
        }
    }
}
