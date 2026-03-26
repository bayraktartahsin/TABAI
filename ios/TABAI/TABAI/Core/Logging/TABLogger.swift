import Foundation
import os

enum TABLogger {
    private static let logger = Logger(subsystem: "com.tabai", category: "general")

    static func debug(_ message: String) {
        #if DEBUG
        logger.debug("\(message, privacy: .private)")
        #endif
    }

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
