import CFrontbaseSupport

#if compiler(>=5.5) && canImport(_Concurrency)

/// Executes the supplied SQL query on the connection, returning columns and their types.
///
///     let structure = try await conn.structure ("SELECT * FROM users WHERE FALSE")
/// might give
///     `[ { column: "primaryKey", type: bits, isNullable: false }, { column: "name", type: text, isNullable: true } ]`
///
/// a where clause of `FALSE` is desirable if there is much data in the database, since the query is
/// actually executed and might be slow otherwise.
/// 
/// - parameters:
///     - query: SQL query to execute.
///     - binds: Values for the query placeholders.
/// - returns: An array of `StructureColumn`with attributes `name`, `type` and `isNullable` describing the columns in the result set..
@available (macOS 12, iOS 15, *)
extension FrontbaseConnection {
    public func structure (_ query: String, _ binds: [FrontbaseData] = []) async throws -> [StructureColumn] {
        self.logger.debug ("\(query) \(binds)")
        let promise = self.eventLoop.makePromise (of: [StructureColumn].self)

        blockingIO.submit { state in
            do {
                let statement = try FrontbaseStatement (query: query, on: self)
                try statement.bind (binds)
                try statement.executeQuery()

                guard self.databaseConnection != nil else {
                    return promise.fail (FrontbaseError (reason: .error, message: "Connection has closed"))
                }

                promise.succeed (try statement.structure())
            } catch {
                return promise.fail (error)
            }
        }

        return try await promise.futureResult.get()
    }
}
#endif
