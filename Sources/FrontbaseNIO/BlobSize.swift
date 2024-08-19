//
//  A special type that is decodable from a FrontBase BLOB, that will get the size
//  of the blob instead of the content, without loading the content.
//

import Foundation

struct BlobSize {
    let size: UInt32
}

extension BlobSize: CustomStringConvertible {
    var description: String {
        return size.description
    }
}
