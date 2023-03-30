import CFrontbaseSupport

#if compiler(>=5.5) && canImport(_Concurrency)
@available (macOS 12, iOS 15, *)
extension FrontbaseConnection {
    public func command (_ query: String, _ binds: [FrontbaseData] = []) async throws -> String? {
        self.logger.debug ("\(query) \(binds)")
        let promise = self.eventLoop.makePromise (of: String?.self)
        
        blockingIO.submit { state in
            do {
                let statement = try FrontbaseStatement (query: query, on: self)
                try statement.bind (binds)
                try statement.executeQuery()
                
                guard self.databaseConnection != nil else {
                    return promise.fail (FrontbaseError (reason: .error, message: "Connection has closed"))
                }

                promise.succeed (try statement.message())
            } catch {
                return promise.fail (error)
            }
        }
        
        return try await promise.futureResult.get()
    }
}
#endif
