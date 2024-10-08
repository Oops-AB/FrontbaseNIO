import CFrontbaseSupport
import Foundation

/// Supported Frontbase data types.
public enum FrontbaseData: Equatable, Encodable {
    /// `Bool`.
    case boolean (Bool)

    /// `Int`.
    case integer (Int64)
    
    /// `Double`.
    case float (Double)
    
    /// `Decimal`.
    case decimal (Decimal)

    /// `String`.
    case text (String)
    
    /// `Data`.
    case blob (FrontbaseBlob)

    /// `Date`.
    case timestamp (Date)

    /// `[UInt8]`.
    case bits ([UInt8])

    /// `NULL`.
    case null

    static private let timestampParsers = FrontbaseData.makeTimestampParsers()

    private static func makeTimestampParsers() -> [Int: DateFormatter] {
        return [
            19: makeTimestampParser (for: 19),
            21: makeTimestampParser (for: 21),
            22: makeTimestampParser (for: 22),
            23: makeTimestampParser (for: 23),
            24: makeTimestampParser (for: 24),
            25: makeTimestampParser (for: 25),
            26: makeTimestampParser (for: 26)
        ]
    }
    private static func makeTimestampParser (for length: Int) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = String ("yyyy-MM-dd HH:mm:ss.SSSSSS".prefix (length))
        formatter.timeZone = TimeZone (identifier: "UTC")

        return formatter
    }

    static private let timestampFormatter = FrontbaseTimestampFormatter (6)

    /// See `Encodable`.
    public func encode (to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
            case .boolean (let value): try container.encode (value)
            case .integer (let value): try container.encode (value)
            case .float (let value): try container.encode (value)
            case .decimal (let value): try container.encode (value)
            case .text (let value): try container.encode (value)
            case .blob (let value): try container.encode (value)
            case .null: try container.encodeNil()
            case .timestamp (let value): try container.encode (value)
            case .bits (let value): try container.encode (value)
        }
    }

    internal static func retrieve (from row: FBSRow, at columnIndex: UInt32, columnInfo: FBSColumnInfo, statement: FrontbaseStatement, resultSet: FBSResult) throws -> FrontbaseData {
        if fbsIsNull (row, columnIndex) {
            return .null
        } else {
            switch columnInfo.datatype {
                case FBS_PrimaryKey:
                    return .integer (fbsGetInteger (row, columnIndex))

                case FBS_Boolean:
                    return .boolean (fbsGetBoolean (row, columnIndex))

                case FBS_Integer:
                    return .integer (fbsGetInteger (row, columnIndex))

                case FBS_SmallInteger:
                    return .integer (fbsGetShortInteger (row, columnIndex))

                case FBS_Float:
                    return .float (fbsGetNumeric (row, columnIndex))

                case FBS_Real:
                    return .float (fbsGetReal (row, columnIndex))

                case FBS_Double:
                    return .float (fbsGetNumeric (row, columnIndex))

                case FBS_Numeric:
                    return .float (fbsGetNumeric (row, columnIndex))

                case FBS_Decimal:
                    if #available(macOS 12.0, *) {
                        let scale = fbsGetScale (resultSet, row, columnIndex)
                        if let decimal = Decimal (string: String (format: "%.\(scale)f", fbsGetDecimal (row, columnIndex)), locale: Locale (identifier: "en_us_POSIX")) {
                            return .decimal (decimal)
                        } else {
                            return .decimal (Decimal (fbsGetDecimal (row, columnIndex)))
                        }
                    } else {
                        return .decimal (Decimal (fbsGetDecimal (row, columnIndex)))
                    }

                case FBS_Character:
                    return .text (String (cString: fbsGetCharacter (row, columnIndex)))

                case FBS_VCharacter:
                    return .text (String (cString: fbsGetCharacter (row, columnIndex)))

                case FBS_Bit:
                    return .bits (convertBits (bytes: fbsGetBitBytes (row, columnIndex), count: fbsGetBitSize (row, columnIndex)))

                case FBS_VBit:
                    return .bits (convertBits (bytes: fbsGetBitBytes (row, columnIndex), count: fbsGetBitSize (row, columnIndex)))

                case FBS_Date:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_Time:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_TimeTZ:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_Timestamp:
                    return .timestamp (Date (timeIntervalSinceReferenceDate: fbsGetTimestamp(row, columnIndex)))

                case FBS_TimestampTZ:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_YearMonth:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_DayTime:
                    return .float (fbsGetDayTime (row, columnIndex))

                case FBS_CLOB:
                    var size: UInt32 = UInt32.max
                    let handle = fbsGetBlobHandle (row, columnIndex, &size)

                    return .blob (FrontbaseBlob (handle: String (cString: handle), size: size, connection: statement.connection))

                case FBS_BLOB:
                    var size: UInt32 = UInt32.max
                    let handle = fbsGetBlobHandle (row, columnIndex, &size)

                    return .blob (FrontbaseBlob (handle: String (cString: handle), size: size, connection: statement.connection))

                case FBS_TinyInteger:
                    return .integer (fbsGetTinyInteger (row, columnIndex))

                case FBS_LongInteger:
                    return .integer (fbsGetLongInteger (row, columnIndex))

                case FBS_CircaDate:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_AnyType:
                    return try retrieveAnyType (from: row, at: columnIndex, type: fbsGetAnyTypeType (row, columnIndex), statement: statement, resultSet: resultSet)

                default:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")
            }
        }
    }

    internal static func retrieveAnyType (from row: FBSRow, at columnIndex: UInt32, type: FBSDatatype, statement: FrontbaseStatement, resultSet: FBSResult) throws -> FrontbaseData {
        if fbsAnyTypeIsNull (row, columnIndex) {
            return .null
        } else {
            switch type {
                case FBS_PrimaryKey:
                    return .integer (fbsGetAnyTypeInteger (row, columnIndex))

                case FBS_Boolean:
                    return .boolean (fbsGetAnyTypeBoolean (row, columnIndex))

                case FBS_Integer:
                    return .integer (fbsGetAnyTypeInteger (row, columnIndex))

                case FBS_SmallInteger:
                    return .integer (fbsGetAnyTypeShortInteger (row, columnIndex))

                case FBS_Float:
                    return .float (fbsGetAnyTypeNumeric (row, columnIndex))

                case FBS_Real:
                    return .float (fbsGetAnyTypeReal (row, columnIndex))

                case FBS_Double:
                    return .float (fbsGetAnyTypeNumeric (row, columnIndex))

                case FBS_Numeric:
                    return .float (fbsGetAnyTypeNumeric (row, columnIndex))

                case FBS_Decimal:
                    if #available(macOS 12.0, *) {
                        let scale = fbsGetAnyTypeScale (resultSet, row, columnIndex)
                        if let decimal = Decimal (string: String (format: "%.\(scale)f", fbsGetAnyTypeDecimal (row, columnIndex)), locale: Locale (identifier: "en_us_POSIX")) {
                            return .decimal (decimal)
                        } else {
                            return .decimal (Decimal (fbsGetAnyTypeDecimal (row, columnIndex)))
                        }
                    } else {
                        return .decimal (Decimal (fbsGetAnyTypeDecimal (row, columnIndex)))
                    }

                case FBS_Character:
                    return .text (String (cString: fbsGetAnyTypeCharacter (row, columnIndex)))

                case FBS_VCharacter:
                    return .text (String (cString: fbsGetAnyTypeCharacter (row, columnIndex)))

                case FBS_Bit:
                    return .bits (convertBits (bytes: fbsGetAnyTypeBitBytes (row, columnIndex), count: fbsGetAnyTypeBitSize (row, columnIndex)))

                case FBS_VBit:
                    return .bits (convertBits (bytes: fbsGetAnyTypeBitBytes (row, columnIndex), count: fbsGetAnyTypeBitSize (row, columnIndex)))

                case FBS_Date:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_Time:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_TimeTZ:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_Timestamp:
                    return .timestamp (Date (timeIntervalSinceReferenceDate: fbsGetAnyTypeTimestamp(row, columnIndex)))

                case FBS_TimestampTZ:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_YearMonth:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_DayTime:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                case FBS_CLOB:
                    var size: UInt32 = UInt32.max
                    let handle = fbsGetAnyTypeBlobHandle (row, columnIndex, &size)

                    return .blob (FrontbaseBlob (handle: String (cString: handle), size: size, connection: statement.connection))

                case FBS_BLOB:
                    var size: UInt32 = UInt32.max
                    let handle = fbsGetAnyTypeBlobHandle (row, columnIndex, &size)

                    return .blob (FrontbaseBlob (handle: String (cString: handle), size: size, connection: statement.connection))

                case FBS_TinyInteger:
                    return .integer (fbsGetAnyTypeTinyInteger (row, columnIndex))

                case FBS_LongInteger:
                    return .integer (fbsGetAnyTypeLongInteger (row, columnIndex))

                case FBS_CircaDate:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")

                default:
                    throw FrontbaseError (reason: .error, message: "Unexpected column type.")
            }
        }
    }

    private static func convertBits (bytes: UnsafePointer<UInt8>, count: UInt32) -> [UInt8] {
        var result = [UInt8]()

        for index in 0 ..< Int (count) {
            result += [bytes[index]]
        }

        return result
    }
}

extension FrontbaseData: CustomStringConvertible {
    /// Description of data
    public var description: String {
        switch self {
            case .bits (let bits): return "X'\(bits.map { String (format: "%02X", $0) }.joined())'"
            case .boolean (let boolean): return boolean ? "true" : "false"
            case .blob (let blob): return blob.description
            case .float (let float): return float.description
            case .decimal (let decimal): return decimal.description
            case .integer (let int): return int.description
            case .null: return "null"
            case .text (let text): return "\"" + text + "\""
            case .timestamp (let timestamp): return timestamp.description
        }
    }
}

extension FrontbaseData {

    /// Data as SQL expression
    internal func sql (connection: FrontbaseConnection) -> String {
        switch self {
            case .bits (let bits): return "X'\(bits.map { String (format: "%02X", $0) }.joined())'"
            case .boolean (let boolean): return boolean ? "TRUE" : "FALSE"
            case .blob (let blob):
                do {
                    try blob.createHandle (connection: connection)
                    return blob.handle ?? "NO HANDLE"
                } catch {
                    return "NO HANDLE"
                }
            case .float (let float): return float.description
            case .integer (let int): return int.description
            case .decimal (let decimal): return decimal.description
            case .null: return "null"
            case .text (let text): return "'" + text.split (separator: "'", omittingEmptySubsequences: false).joined (separator: "''") + "'"
            case .timestamp (let timestamp): return "TIMESTAMP '\(FrontbaseData.timestampFormatter.string (from: timestamp))'"
        }
    }
}
