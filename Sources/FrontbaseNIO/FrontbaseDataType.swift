/// Supported Frontbase column data types when defining schemas.
public enum FrontbaseDataType {

    ///  BOOLEAN
    case boolean

    /// `INTEGER`.
    case integer
    
    /// `REAL`.
    case real

    ///  DECIMAL
    case decimal

    /// `TEXT`.
    case text
    
    /// `BLOB`.
    case blob

    /// `TIMESTAMP`.
    case timestamp

    /// `BIT`.
    case bits

    /// `BIT VARYING`.
    case varyingbits

    /// `NULL`.
    case null
}

extension FrontbaseDataType: Equatable {}
