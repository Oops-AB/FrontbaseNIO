import CFrontbaseSupport
import Foundation

/// Errors that can be thrown while using Frontbase
public struct FrontbaseError: Error, CustomStringConvertible, LocalizedError {
    internal let reason: Reason
    public let message: String

    public var description: String {
        return "\(self.reason): \(self.message)"
    }

    public var errorDescription: String? {
        return self.description
    }

    internal init (reason: Reason, message: String) {
        self.reason = reason
        self.message = message
    }

    internal init (statusCode: Int32, connection: FrontbaseConnection) {
        self.reason = .init(statusCode: statusCode)
        self.message = connection.errorMessage ?? "Unknown"
    }
}

/// Reasons.
internal enum Reason {
    case error
    case intern
    case permission
    case abort
    case busy
    case locked
    case noMemory
    case readOnly
    case interrupt
    case ioError
    case corrupt
    case notFound
    case full
    case cantOpen
    case proto
    case empty
    case schema
    case tooBig
    case constraint
    case mismatch
    case misuse
    case noLFS
    case auth
    case format
    case range
    case notADatabase
    case notice
    case warning
    case row
    case done
    case connection
    case close
    case prepare
    case bind
    case execute
    case ifExistsNotSupported
    case openTransaction

    init(statusCode: Int32) {
        switch statusCode {
            default:
                self = .error
        }
    }
}
