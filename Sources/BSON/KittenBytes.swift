import Foundation

internal struct KittenBytes : Hashable, Comparable {
    /// Useful when sorting KittenBytes strings
    public static func <(lhs: KittenBytes, rhs: KittenBytes) -> Bool {
        for (position, byte) in lhs.bytes.enumerated() {
            guard position < rhs.bytes.count else {
                return true
            }
            
            if byte < rhs.bytes[position] {
                return true
            }
            
            if byte > rhs.bytes[position] {
                return false
            }
        }
        
        return String(bytes: lhs.bytes, encoding: .utf8)! > String(bytes: rhs.bytes, encoding: .utf8)!
    }
    
    /// Useful when sorting KittenBytes strings
    public static func >(lhs: KittenBytes, rhs: KittenBytes) -> Bool {
        for (position, byte) in lhs.bytes.enumerated() {
            guard position < rhs.bytes.count else {
                return false
            }
            
            if byte > rhs.bytes[position] {
                return true
            }
            
            if byte < rhs.bytes[position] {
                return false
            }
        }
        
        return String(bytes: lhs.bytes, encoding: .utf8)! > String(bytes: rhs.bytes, encoding: .utf8)!
    }
    
    /// Equates two KittenBytes
    public static func ==(lhs: KittenBytes, rhs: KittenBytes) -> Bool {
        return lhs.bytes == rhs.bytes
    }
    
    public func hash(into hasher: inout Hasher) {
        guard bytes.count > 0 else {
            hasher.combine(0)
            return
        }
        bytes.forEach { hasher.combine($0) }
    }
    
    /// The underlying bytes
    public let bytes: [UInt8]
    
    /// Converts this to itself
    public var kittenBytes: KittenBytes { return self }
    
    /// Initializes it from binary
    public init(_ data: [UInt8]) {
        self.bytes = data
    }
}

