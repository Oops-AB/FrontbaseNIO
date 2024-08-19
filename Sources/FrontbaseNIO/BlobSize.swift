//
//  A special type that is decodable from a FrontBase BLOB, that will get the size
//  of the blob instead of the content, without loading the content.
//

import Foundation

public struct BlobSize {
    public let size: UInt32
}

extension BlobSize: Decodable {}

extension BlobSize: CustomStringConvertible {
    public var description: String {
        return size.description
    }
}
