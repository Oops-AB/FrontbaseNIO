import CFrontbaseSupport
import Foundation

public class FrontbaseBlob {
    var handle: String?
    var connection: FrontbaseConnection?
    var content: Data?
    let size: UInt32?
    var blobHandle: FBSBlob?

    internal init (handle: String, size: UInt32, connection: FrontbaseConnection) {
        self.handle = handle
        self.size = size
        self.connection = connection
        self.blobHandle = nil
    }

    public init (data: Data) {
        self.handle = nil
        self.connection = nil
        self.content = data
        self.size = nil
        self.blobHandle = nil
    }

    deinit {
        if let connection = self.connection, let blobHandle = self.blobHandle {
            connection.release (blob: blobHandle)
        }
    }

    public func data() -> Data {
        if let data = content {
            return data
        } else if let connection = connection, let handle = handle, let size = size {
            let data = connection.blob (handle: handle, size: size)
            self.content = data
            return data
        } else {
            return Data()
        }
    }

    internal func createHandle (connection: FrontbaseConnection) throws {
        if self.connection == nil {
            self.connection = connection
        }
        if (self.handle == nil) && (self.content != nil) {
            let (handleString, blobHandle) = try connection.blob (data: content!)

            self.handle = handleString
            self.blobHandle = blobHandle
        }
    }

    public var description: String {
        if let handle = handle {
            return handle
        } else if let content = content {
            return "\(content.count) bytes of data"
        } else {
            return "Unknown blob"
        }
    }
}

extension FrontbaseBlob: Equatable {
    public static func == (left: FrontbaseBlob, right: FrontbaseBlob) -> Bool {
        return left.handle == right.handle
    }
}

extension FrontbaseBlob: Encodable {
    public func encode (to encoder: Encoder) throws {
        try self.handle.encode (to: encoder)
    }
}
