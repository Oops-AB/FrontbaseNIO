import CFrontbaseSupport
import Foundation
import NIO
import Logging

/// A connection to a Frontbase database, created by `FrontbaseDatabase`.
///
///     let conn = try frontbaseDB.newConnection(on: ...).wait()
///
/// Use this connection to execute queries on the database.
///
///     try conn.query("VALUES server_name;").wait()
///
/// You can also build queries, using the available query builders.
///
///     let res = try conn.select()
///         .column(function: "server_name", as: "version")
///         .run().wait()
///
public final class FrontbaseConnection {

    /// Available Frontbase storage methods.
    public enum Storage {
        /// Named database, connected via FBExec
        case named (name: String, hostName: String, username: String, password: String, databasePassword: String? = nil, mode: SessionMode = .serializable (.pessimistic, .readWrite))

        /// File-based database, only supporting one simultaneous connection.
        case file (name: String, pathName: String, username: String, password: String, databasePassword: String? = nil, mode: SessionMode = .serializable (.pessimistic, .readWrite))
    }

    public enum SessionMode {
        public enum LockingMode: String {
            case pessimistic = "PESSIMISTIC"
            case optimistic = "OPTIMISTIC"
            case deferred = "DEFERRED"
        }

        public enum AccessMode: String {
            case readWrite = "READ WRITE"
            case readOnly = "READ ONLY"
        }

        case serializable (LockingMode, AccessMode)
        case repeatableRead (LockingMode, AccessMode)
        case readCommitted (LockingMode, AccessMode)
        case versioned (LockingMode, AccessMode)

        var sql: String {
            switch (self) {
                case .serializable (let lockingMode, let accessMode):
                    return "SET TRANSACTION ISOLATION LEVEL SERIALIZABLE, LOCKING \(lockingMode.rawValue), \(accessMode.rawValue);"

                case .repeatableRead (let lockingMode, let accessMode):
                    return "SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, LOCKING \(lockingMode.rawValue), \(accessMode.rawValue);"

                case .readCommitted (let lockingMode, let accessMode):
                    return "SET TRANSACTION ISOLATION LEVEL READ COMMITTED, LOCKING \(lockingMode.rawValue), \(accessMode.rawValue);"

                case .versioned (let lockingMode, let accessMode):
                    return "SET TRANSACTION ISOLATION LEVEL VERSIONED, LOCKING \(lockingMode.rawValue), \(accessMode.rawValue);"
            }
        }
    }

    public let eventLoop: EventLoop
    internal let storage: Storage
    internal var databaseConnection: FBSConnection?
    internal let threadPool: NIOThreadPool
    internal let connectionLogger: Logger
    public var logger: Logger {
        return self.connectionLogger
    }
    internal var blockingIO: NIOThreadPool

    /// When set to true, will execute statements with the auto commit flag set
    public var autoCommit = true

    public var isClosed: Bool {
        return databaseConnection == nil
    }

    public static func open (storage: Storage,
                             sessionName: String = ProcessInfo.processInfo.processName,
                             threadPool: NIOThreadPool,
                             logger: Logger = .init (label: "se.oops.vapor.frontbase.connection"),
                             on eventLoop: EventLoop
    ) -> EventLoopFuture<FrontbaseConnection> {
        let promise = eventLoop.makePromise(of: FrontbaseConnection.self)
        threadPool.submit { state in
            var errorMessage: UnsafePointer<Int8>? = nil
            var connection: FBSConnection? = nil
            var sessionMode: SessionMode = .serializable (.pessimistic, .readOnly)
            let systemUser = ProcessInfo.processInfo.environment["USER"] ?? ""

            switch storage {
            case .named (let databaseName, let hostName, let username, let password, let databasePassword, let mode):
                connection = withUnsafeMutablePointer (to: &errorMessage) { (errorMessagePointer: UnsafeMutablePointer<UnsafePointer<Int8>?>) -> FBSConnection? in
                    sessionMode = mode
                    return fbsConnectDatabaseOnHost (databaseName,
                                                     hostName,
                                                     databasePassword,
                                                     username.uppercased(),
                                                     password,
                                                     sessionName,
                                                     systemUser,
                                                     errorMessagePointer)
                }

            case .file (let databaseName, let filePath, let username, let password, let databasePassword, let mode):
                connection = withUnsafeMutablePointer (to: &errorMessage) { (errorMessagePointer: UnsafeMutablePointer<UnsafePointer<Int8>?>) -> FBSConnection? in
                    sessionMode = mode
                    return fbsConnectDatabaseAtPath (databaseName,
                                                     filePath,
                                                     databasePassword,
                                                     username.uppercased(),
                                                     password,
                                                     sessionName,
                                                     systemUser,
                                                     errorMessagePointer)
                }
            }

            if connection == nil, let message = errorMessage {
                logger.error ("Failed to connect to Frontbase database: \(storage) (\(String (cString: message)))")
                promise.fail (FrontbaseError (reason: .error, message: "Could not open database: \(storage) (\(String (cString: message)))"))
            } else if connection == nil {
                logger.error ("Failed to connect to Frontbase database: \(storage)")
                promise.fail (FrontbaseError (reason: .error, message: "Could not open database: \(storage)"))
            } else {
                let result = withUnsafeMutablePointer (to: &errorMessage) { (errorMessagePointer: UnsafeMutablePointer<UnsafePointer<Int8>?>) -> FBSResult? in
                    return fbsExecuteSQL (connection, sessionMode.sql, true, errorMessagePointer)
                }
                defer {
                    fbsCloseResult (result)
                }

                if let message = errorMessage {
                    logger.error ("Failed to set transaction isolation level on new connection to Frontbase database: \(storage)")
                    promise.fail (FrontbaseError (reason: .error, message: "Could set transaction isolation level on new connection (\(message))."))
                } else {
                    logger.debug ("Connected to Frontbase database: \(storage)")
                    promise.succeed (FrontbaseConnection (storage: storage, connection: connection!, threadPool: threadPool, logger: logger, on: eventLoop))
                }
            }
        }
        return promise.futureResult
    }

#if compiler(>=5.5) && canImport(_Concurrency)
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    @inlinable
    public static func open (storage: Storage,
                             sessionName: String = ProcessInfo.processInfo.processName,
                             threadPool: NIOThreadPool,
                             logger: Logger = .init (label: "se.oops.vapor.frontbase.connection"),
                             on eventLoop: EventLoop
    ) async throws -> FrontbaseConnection {
        return try await open (storage: storage, sessionName: sessionName, threadPool: threadPool, logger: logger, on: eventLoop).get()
    }
#endif

    internal init (storage: Storage, connection: FBSConnection, threadPool: NIOThreadPool, logger: Logger, on eventLoop: EventLoop) {
        self.storage = storage
        self.databaseConnection = connection
        self.threadPool = threadPool
        self.connectionLogger = logger
        self.eventLoop = eventLoop
        self.blockingIO = NIOThreadPool (numberOfThreads: 1)
        self.blockingIO.start()
    }

    /// Returns the last error message, if one exists.
    internal var errorMessage: String? {
        guard let connection = databaseConnection else {
            return nil
        }
        return String (cString: fbsErrorMessage (connection))
    }


    /// Executes the supplied SQL query on the connection, returning a `EventLoopFuture` with the rows returned by the query.
    ///
    ///     try conn.query ("SELECT * FROM users")
    ///         .map { row in
    ///             print (row)
    ///         }
    ///
    /// - parameters:
    ///     - query: SQL query to execute.
    ///     - binds: Values for the query placeholders.
    /// - returns: A `Future` that eventually will complete with the query rows.
    public func query (_ query: String, _ binds: [FrontbaseData] = []) -> EventLoopFuture<[FrontbaseRow]> {
        var rows: [FrontbaseRow] = []
        return self.query (query, binds) { row in
            rows.append (row)
        }.map { rows }
    }

    /// Executes the supplied SQL query on the connection, calling the supplied closure for each row returned.
    ///
    ///     try conn.query ("SELECT * FROM users") { row in
    ///         print (row)
    ///     }.wait()
    ///
    /// - parameters:
    ///     - query: SQL query to execute.
    ///     - binds: Values for the query placeholders.
    ///     - onRow: Closure to be executed for each row of the query response.
    /// - returns: A `Future` that signals completion of the query.
    public func query (_ query: String, _ binds: [FrontbaseData] = [], _ onRow: @escaping (FrontbaseRow) throws -> Void) -> EventLoopFuture<Void> {
        self.logger.debug ("\(query) \(binds)")
        let promise = self.eventLoop.makePromise (of: Void.self)

        blockingIO.submit { state in
            do {
                let statement = try FrontbaseStatement (query: query, on: self)
                try statement.bind (binds)
                try statement.executeQuery()
                var callbacks: [EventLoopFuture<Void>] = []

                guard self.databaseConnection != nil else {
                    return promise.fail (FrontbaseError (reason: .error, message: "Connection has closed"))
                }
                while let row = try statement.nextRow() {
                    let callback = self.eventLoop.submit {
                        try onRow (row)
                    }
                    callbacks.append (callback)
                }
                EventLoopFuture<Void>.andAllComplete (callbacks, on: self.eventLoop)
                    .cascade (to: promise)
            } catch {
                return promise.fail (error)
            }
        }
        return promise.futureResult
    }
    
    public func close() -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise (of: Void.self)
        self.threadPool.submit { state in
            if let connection = self.databaseConnection {
                fbsCloseConnection (connection)
            }
            self.eventLoop.submit {
                self.databaseConnection = nil
            }.cascade (to: promise)
        }
        return promise.futureResult
    }

    internal func blob (handle: String, size: UInt32) -> Data {
        return Data (bytes: fbsGetBlobData (databaseConnection, handle), count: Int (size))
    }

    internal func blob (data: Data) throws -> (String, FBSBlob) {
        return try data.withUnsafeBytes { bytes in
            if let blobHandle = fbsCreateBlobHandle (bytes.baseAddress, UInt32 (data.count), self.databaseConnection) {
                let handleString = String (cString: fbsGetBlobHandleString (blobHandle))

                return (handleString, blobHandle)
            } else {
                throw BlobError.createFailed
            }
        }
    }

    internal func release (blob: FBSBlob) {
        fbsReleaseBlobHandle (blob)
    }

    public func withTransaction<R> (_ closure: @escaping (_ connection: FrontbaseConnection) throws -> EventLoopFuture<R>) -> EventLoopFuture<R> {
        return self.query ("VALUES 0")
            .flatMap { (result: [FrontbaseRow]) -> EventLoopFuture<R> in
                guard self.autoCommit == true else {
                    return self.eventLoop.makeFailedFuture (FrontbaseError (reason: .openTransaction, message: "A transaction is already in progress"))
                }

                do {
                    self.autoCommit = false
                    return try closure (self)
                        .flatMap { (result: R) -> EventLoopFuture<R> in
                            self.autoCommit = true
                            return self.query ("COMMIT")
                                .map { _ in
                                    return result
                                }
                        }
                } catch {
                    return self.query ("ROLLBACK")
                        .flatMap { _ in
                            self.autoCommit = true
                            return self.eventLoop.makeFailedFuture (error)
                        }
                }
            }
    }

#if compiler(>=5.5) && canImport(_Concurrency)
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    @inlinable
    public func withTransaction<R> (_ closure: (_ connection: FrontbaseConnection) async throws -> R) async throws -> R {
        let _ = try await self.query ("VALUES 0").get()
        guard self.autoCommit == true else {
            throw FrontbaseError (reason: .openTransaction, message: "A transaction is already in progress")
        }
        self.autoCommit = false
        do {
            let result = try await closure (self)
            let _ = try await self.query ("COMMIT").get()
            self.autoCommit = true
            return result
        } catch {
            let _ = try await self.query ("ROLLBACK").get()
            self.autoCommit = true
            throw error
        }
    }
#endif

    deinit {
        assert (self.databaseConnection == nil, "FrontbaseConnection was not closed before deinitializing")
    }
}
