import CFrontbaseSupport
import Dispatch
import NIO
@testable import FrontbaseNIO
import XCTest

enum UtilitiesError: Error {
    case noTemporaryDirectory
}

struct TestDatabase {
    let storage: FrontbaseConnection.Storage
    let threadPool: NIOThreadPool

    internal init (name: String) {
        threadPool = NIOThreadPool (numberOfThreads: 1)
        fbsCreateDatabaseWithUrl ("frontbase://localhost/\(name)")
        fbsStartDatabaseWithUrl ("frontbase://localhost/\(name)")
        storage = .named (name: name, hostName: "localhost", username: "_system", password: "")
    }

    internal func newConnection (on eventLoop: EventLoop) throws -> FrontbaseConnection {
        return try FrontbaseConnection.open (storage: storage, threadPool: threadPool, logger: .init (label: "FrontbaseTests"), on: eventLoop).wait()
    }

    internal func destroyTest() {
        switch self.storage {
            case .named (let name, let hostName, _, _, _, _):
                fbsDeleteDatabaseWithUrl ("frontbase://\(hostName)/\(name)")

            default:
                print ("This was unexpected")
        }
    }
}

extension FrontbaseConnection {
    static func makeFilebasedTest() throws -> FrontbaseConnection {
        let group = MultiThreadedEventLoopGroup (numberOfThreads: 1)
        let threadPool = NIOThreadPool (numberOfThreads: 1)
        let conn = try FrontbaseConnection.open (storage: .file (name: "FrontbaseTests", pathName: try temporaryDirectory (template: "/tmp/FrontbaseTests-XXXXXXXXXX") + "/database.fb", username: "_system", password: "", databasePassword: ""), threadPool: threadPool, logger: .init (label: "FrontbaseTests"), on: group.next()).wait()
        return conn
    }

    static func temporaryDirectory (template: String) throws -> String {
        if let templatePointer = template.cString (using: .utf8) {
            let buffer = UnsafeMutablePointer<Int8>.allocate (capacity: templatePointer.count)

            buffer.assign (from: templatePointer, count: templatePointer.count)
            if let result = mkdtemp (buffer) {
                return String (cString: result)
            }
        }

        throw UtilitiesError.noTemporaryDirectory
    }

    func destroyTest() {
        do {
            try close().wait()
        } catch {
            print ("Failed to close database: \(error)")
        }

        switch self.storage {
            case .named (let name, let hostName, _, _, _, _):
                fbsDeleteDatabaseWithUrl ("frontbase://\(hostName)/\(name)")

            case.file (_, let pathName, _, _, _, _):
                if let endIndex = pathName.lastIndex (of: "/") {
                    let path = String (pathName[pathName.startIndex ..< endIndex])
                    do {
                        try FileManager.default.removeItem (atPath: path)
                    } catch {
                        print ("Unable to delete directory at \(path): \(error)")
                    }
            }
        }
    }

    static func makeNetworkedDatabase() throws -> TestDatabase {
        return TestDatabase (name: try temporaryDatabaseName (template: "FrontbaseTests-XXXXXXXXXX"))
    }

    static func temporaryDatabaseName (template: String) throws -> String {
        return template
    }
}

extension FrontbaseData {
    var blobData: Data? {
        switch (self) {
            case .blob (let blob):
                return blob.data()

            default:
                return nil
        }
    }

    var timestampDate: Date? {
        switch (self) {
            case .timestamp (let timestamp):
                return timestamp

            default:
                return nil
        }
    }
}
