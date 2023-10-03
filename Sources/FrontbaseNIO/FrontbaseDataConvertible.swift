import Foundation

/// Capable of converting to and from `FrontbaseData`.
public protocol FrontbaseDataConvertible {
    /// Creates `Self` from `FrontbaseData`.
    init? (frontbaseData: FrontbaseData)
    
    /// Converts `self` to `FrontbaseData`.
    var frontbaseData: FrontbaseData? { get }
}

extension Data: FrontbaseDataConvertible {
    /// See `FrontbaseDataConvertible.init?(:)`
    public init? (frontbaseData: FrontbaseData) {
        guard case .blob (let blob) = frontbaseData else {
            return nil
        }
        self = blob.data()
    }
    
    /// See `FrontbaseDataConvertible.frontbaseData`.
    public var frontbaseData: FrontbaseData? {
        return .blob (FrontbaseBlob (data: self))
    }
}

extension UUID: FrontbaseDataConvertible {
    /// See `FrontbaseDataConvertible.init?(:)`
    public init? (frontbaseData: FrontbaseData) {
        switch frontbaseData {
            case .text (let string):
                guard let uuid = UUID (uuidString: string) else {
                    return nil
                }
                self = uuid

            case .bits (let bits):
                let bits = bits
                switch bits.count {
                    case 16:
                        self = UUID (uuid: (
                            bits[0], bits[1], bits[2], bits[3], bits[4], bits[5], bits[6], bits[7],
                            bits[8], bits[9], bits[10], bits[11], bits[12], bits[13], bits[14], bits[15]
                        ))
                    case 12:
                        self = UUID (uuid: (
                            bits[0], bits[1], bits[2], bits[3], bits[4], bits[5], bits[6], bits[7],
                            bits[8], bits[9], bits[10], bits[11], 0, 0, 0, 0
                        ))
                    default:
                        return nil
                }
            case .blob (let blob):
                let data = blob.data()
                guard data.count == 16 else {
                    return nil
                }
                self = UUID (uuid: (
                    data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7],
                    data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15]
                ))
            default:
                return nil
        }
    }
    
    /// See `FrontbaseDataConvertible.frontbaseData`.
    public var frontbaseData: FrontbaseData? {
        return .bits([
            uuid.0, uuid.1, uuid.2, uuid.3, uuid.4, uuid.5, uuid.6, uuid.7,
            uuid.8, uuid.9, uuid.10, uuid.11, uuid.12, uuid.13, uuid.14, uuid.15
        ])
    }
}

extension Date: FrontbaseDataConvertible {
    /// See `FrontbaseDataConvertible.init?(:)`
    public init? (frontbaseData: FrontbaseData) {
        guard case .timestamp (let timestamp) = frontbaseData else {
            return nil
        }
        self = timestamp
    }

    /// See `FrontbaseDataConvertible.frontbaseData`.
    public var frontbaseData: FrontbaseData? {
        return .timestamp (self)
    }
}

extension String: FrontbaseDataConvertible {
    /// See `FrontbaseDataConvertible.init?(:)`
    public init? (frontbaseData: FrontbaseData) {
        guard case .text (let string) = frontbaseData else {
            return nil
        }
        self = string
    }
    
    /// See `FrontbaseDataConvertible.frontbaseData`.
    public var frontbaseData: FrontbaseData? {
        return .text (self)
    }
}

extension URL: FrontbaseDataConvertible {
    /// See `FrontbaseDataConvertible.init?(:)`
    public init? (frontbaseData: FrontbaseData) {
        guard case .text (let string) = frontbaseData else {
            return nil
        }
        guard let url = URL (string: string) else {
            return nil
        }
        self = url
    }
    
    /// See `FrontbaseDataConvertible.frontbaseData`.
    public var frontbaseData: FrontbaseData? {
        return .text (description)
    }
}


extension FixedWidthInteger {
    /// See `FrontbaseDataConvertible.init?(:)`
    public init? (frontbaseData: FrontbaseData) {
        switch frontbaseData {
            case .integer (let int):
                guard int <= Self.max else {
                    return nil
                }
                guard int >= Self.min else {
                    return nil
                }
                self = numericCast (int)
            case .float (let float):
                let int = Self.init (float)
                guard int <= Self.max else {
                    return nil
                }
                guard int >= Self.min else {
                    return nil
                }
                self = numericCast (int)
            default:
                return nil
        }
    }
    
    /// See `FrontbaseDataConvertible.frontbaseData`.
    public var frontbaseData: FrontbaseData? {
        return .integer (numericCast(self))
    }
}

extension Array: FrontbaseDataConvertible where Element == UInt8 {
    /// See `FrontbaseDataConvertible.init?(:)`
    public init? (frontbaseData: FrontbaseData) {
        guard case .bits (let bits) = frontbaseData else {
            return nil
        }
        self = bits
    }
    
    /// See `FrontbaseDataConvertible.frontbaseData`.
    public var frontbaseData: FrontbaseData? {
        return .bits (self)
    }
}

extension Int8: FrontbaseDataConvertible { }
extension Int16: FrontbaseDataConvertible { }
extension Int32: FrontbaseDataConvertible { }
extension Int64: FrontbaseDataConvertible { }
extension Int: FrontbaseDataConvertible { }
extension UInt8: FrontbaseDataConvertible { }
extension UInt16: FrontbaseDataConvertible { }
extension UInt32: FrontbaseDataConvertible { }
extension UInt64: FrontbaseDataConvertible { }
extension UInt: FrontbaseDataConvertible { }

extension BinaryFloatingPoint {
    /// See `FrontbaseDataConvertible.init?(:)`
    public init? (frontbaseData: FrontbaseData) {
        switch frontbaseData {
            case .integer (let int):
                self = .init (int)
            case .float (let double):
                self = .init (double)
            default:
                return nil
        }
    }
    
    /// See `FrontbaseDataConvertible.frontbaseData`.
    public var frontbaseData: FrontbaseData? {
        switch self {
            case let double as Double:
                return .float (double)
            case let float as Float:
                return .float (.init (float))
            default:
                return nil
        }
    }
}

extension Double: FrontbaseDataConvertible { }
extension Float: FrontbaseDataConvertible { }

extension Decimal: FrontbaseDataConvertible {
    public init? (frontbaseData: FrontbaseData) {
        switch frontbaseData {
            case .integer (let integer):
                self = .init (integer)

            case .float (let double):
                self = .init (double)

            default:
                return nil
        }
    }
    
    public var frontbaseData: FrontbaseData? {
        return .decimal (self)
    }
}

extension Bool: FrontbaseDataConvertible {
    /// See `FrontbaseDataConvertible.init?(:)`
    public init? (frontbaseData: FrontbaseData) {
        switch frontbaseData {
            case .boolean (let boolean):
                self = .init (boolean)
            case .integer (let int):
                self = .init (int != 0)
            case .float (let double):
                self = .init (double != 0.0)
            default:
                return nil
        }
    }

    /// See `FrontbaseDataConvertible.frontbaseData`.
    public var frontbaseData: FrontbaseData? {
        return .boolean (self)
    }
}

public struct Bit96 {
    let bits: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

    public init (bits: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)) {
        self.bits = bits
    }
}

extension Bit96: Codable {

    public init (from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.bits = (try container.decode (UInt8.self), try container.decode (UInt8.self), try container.decode (UInt8.self), try container.decode (UInt8.self),
                     try container.decode (UInt8.self), try container.decode (UInt8.self), try container.decode (UInt8.self), try container.decode (UInt8.self),
                     try container.decode (UInt8.self), try container.decode (UInt8.self), try container.decode (UInt8.self), try container.decode (UInt8.self))
    }

    public func encode (to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try Mirror (reflecting: bits).children.forEach { try container.encode ($0.value as! UInt8) }
    }
}

extension Array where Element == UInt8 {
    public init (_ bit96: Bit96) {
        self.init (Mirror (reflecting: bit96.bits).children.map { $0.value as! Element })
    }
}

extension Bit96: FrontbaseDataConvertible {
    /// See `FrontbaseDataConvertible.init?(:)`
    public init? (frontbaseData: FrontbaseData) {
        guard case .bits (let bits) = frontbaseData else {
            return nil
        }
        switch bits.count {
        case 12:
            self = Bit96(bits: (
                bits[0], bits[1], bits[2], bits[3],
                bits[4], bits[5], bits[6], bits[7],
                bits[8], bits[9], bits[10], bits[11]
            ))
        default:
            return nil
        }
    }
    
    /// See `FrontbaseDataConvertible.frontbaseData`.
    public var frontbaseData: FrontbaseData? {
        let (component1, component2, component3, component4, component5, component6, component7, component8, component9, component10, component11, component12) = bits
        return .bits([
            component1, component2, component3, component4,
            component5, component6, component7, component8,
            component9, component10, component11, component12
        ])
    }
}

extension Bit96: Equatable {
    public static func == (lhs: Bit96, rhs: Bit96) -> Bool {
        let (left1, left2, left3, left4, left5, left6, left7, left8, left9, left10, left11, left12) = lhs.bits
        let (right1, right2, right3, right4, right5, right6, right7, right8, right9, right10, right11, right12) = rhs.bits

        return (left1 == right1) && (left2 == right2) && (left3 == right3) && (left4 == right4) &&
               (left5 == right5) && (left6 == right6) && (left7 == right7) && (left8 == right8) &&
               (left9 == right9) && (left10 == right10) && (left11 == right11) && (left12 == right12)
    }
    
    
}
