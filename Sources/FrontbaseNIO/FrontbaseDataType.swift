/// Supported Frontbase column data types when defining schemas.
public enum FrontbaseDataType {
   
    /// `INTEGER`.
    case integer
    
    /// `REAL`.
    case real
    
    /// `TEXT`.
    case text (size: Int32)
    
    /// `BLOB`.
    case blob

    /// `TIMESTAMP`.
    case timestamp

    /// `BIT`.
    case bits (size: Int32)

    /// `BIT VARYING`.
    case varyingbits (size: Int32)

    /// `NULL`.
    case null
    
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable]) -> String {
        switch self {
            case .integer: return "INTEGER"
            case .real: return "REAL"
            case .text (let size): return "CHARACTER VARYING(\(size))"
            case .blob: return "BLOB"
            case .timestamp: return "TIMESTAMP"
            case .bits (let size): return "BIT (\(size))"
            case .varyingbits (let size): return "BIT VARYING (\(size))"
            case .null: return "NULL"
        }
    }
}
