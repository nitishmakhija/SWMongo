//
// This source file is part of the MongoKitten open source project
//
// Copyright (c) 2016 - 2017 OpenKitten and the MongoKitten project authors
// Licensed under MIT
//
// See https://github.com/OpenKitten/MongoKitten/blob/mongokitten31/LICENSE.md for license information
// See https://github.com/OpenKitten/MongoKitten/blob/mongokitten31/CONTRIBUTORS.md for the list of MongoKitten project authors
//

import Foundation
import GeoJSON


// MARK: Equations

/// Equals
public func ==(key: String, pred: BSON.Primitive?) -> Query {
    if let pred = pred {
        return Query(aqt: .valEquals(key: key, val: pred))
    } else {
        return Query(aqt: .exists(key: key, exists: false))
    }
}

/// Does not equal
public func !=(key: String, pred: BSON.Primitive?) -> Query {
    if let pred = pred {
        return Query(aqt: .valNotEquals(key: key, val: pred))
    } else {
        return Query(aqt: .exists(key: key, exists: true))
    }
}

// MARK: Comparisons

/// MongoDB: `$gt`. Used like native swift `>`
///
/// Checks whether the `Value` in `key` is larger than the `Value` provided
///
/// - returns: A new `Query` requiring the `Value` in the `key` to be larger than the provided `Value`
public func >(key: String, pred: BSON.Primitive) -> Query {
    return Query(aqt: .greaterThan(key: key, val: pred))
}

/// MongoDB: `$gte`. Used like native swift `>=`
///
/// Checks whether the `Value` in `key` is larger than or equal to the `Value` provided
///
/// - returns: A new `Query` requiring the `Value` in the `key` to be larger than or equal to the provided `Value`
public func >=(key: String, pred: BSON.Primitive) -> Query {
    return Query(aqt: .greaterThanOrEqual(key: key, val: pred))
}

/// MongoDB: `$lt`. Used like native swift `<`
///
/// Checks whether the `Value` in `key` is smaller than the `Value` provided
///
/// - returns: A new `Query` requiring the `Value` in the `key` to be smaller than the provided `Value`
public func <(key: String, pred: BSON.Primitive) -> Query {
    return Query(aqt: .smallerThan(key: key, val: pred))
}

/// MongoDB: `$lte`. Used like normal Swift `<=`
///
/// Checks whether the `Value` in `key` is smaller than or equal to the `Value` provided
///
/// - returns: A new `Query` requiring the `Value` in the `key` to be smaller than or equal to the provided `Value`
public func <=(key: String, pred: BSON.Primitive) -> Query {
    return Query(aqt: .smallerThanOrEqual(key: key, val: pred))
}

/// MongoDB `$and`. Used like normal Swift `&&`.
///
/// Checks whether both these `Query` statements are true
///
/// - returns: A new `Query` that requires both the provided queries to be true
public func &&(lhs: Query, rhs: Query) -> Query {
    let lhs = lhs.aqt
    let rhs = rhs.aqt
    
    switch (lhs, rhs) {
    // To allow `(foo && bar) && (kitten && cat)`
    case (.and(var a), .and(let b)):
        a.append(contentsOf: b)
        return Query(aqt: .and(a))
    // To dynamically construct queries: `Query() && foo && bar` is equal to `foo && bar`
    case (.nothing, let query), (let query, .nothing):
        return Query(aqt: query)
    // For chaining: `foo && bar && kitten`
    case (.and(var a), let other):
        a.append(other)
        return Query(aqt: .and(a))
        // Workaround for Swift 4.1
    case (let other, .and(var a)):
        a.append(other)
        return Query(aqt: .and(a))
    default:
        return Query(aqt: .and([lhs, rhs]))
    }
}

/// MongoDB: `$or`. Used like normal Swift `||`.
///
/// Checks wither either of these `Query` statements is true
///
/// - returns: A new `Query` that is true when at least one of the two queries is true
public func ||(lhs: Query, rhs: Query) -> Query {
    let lhs = lhs.aqt
    let rhs = rhs.aqt
    
    switch (lhs, rhs) {
    // To allow `(foo || bar) || (kitten || cat)`
    case (.or(var a), .or(let b)):
        a.append(contentsOf: b)
        return Query(aqt: .or(b))
    // To dynamically construct queries: `Query() || foo || bar` is equal to `foo || bar`
    case (.nothing, let query), (let query, .nothing):
        return Query(aqt: query)
    // For chaining: `foo || bar || kitten`
    case (.or(var a), let other):
        a.append(other)
        return Query(aqt: .or(a))
        // Workaround for Swift 4.1
    case (let other, .or(var a)):
        a.append(other)
        return Query(aqt: .or(a))
    default:
        return Query(aqt: .or([lhs, rhs]))
    }
}

/// Whether the `Query` provided is false
///
/// - parameter query: The query to be checked as false
///
/// - returns: A new `Query` that will be inverting the provided `Query`
public prefix func !(query: Query) -> Query {
    switch query.aqt {
    // Nothing is no query, so it cannot be inverted
    case .nothing:
        return Query(aqt: .nothing)
    default:
        return Query(aqt: .not(query.aqt))
    }
}

/// MongoDB `$and`. Shorthand for `lhs = lhs && rhs`
///
/// Checks whether both these `Query` statements are true
public func &=(lhs: inout Query, rhs: Query) {
    lhs = lhs && rhs
}

infix operator ||=

/// MongoDB `$or`. Shorthand for `lhs = lhs || rhs`
///
/// Checks wither either of these `Query` statements is true
public func ||=(lhs: inout Query, rhs: Query) {
    lhs = lhs || rhs
}

extension String {
    /// MongoDB `$in` operator
    public func `in`(_ elements: [Primitive]) -> Query {
        return Query(aqt: .in(key: self, in: elements))
    }
}

/// Abstract Query Tree.
///
/// Made to be easily readable/usable so that an `AQT` instance can be easily translated to a `Document` as a Query or even possibly `SQL` in the future.
public indirect enum AQT {
    /// The types we support as raw `Int32` values
    ///
    /// The raw values are defined in https://docs.mongodb.com/manual/reference/operator/query/type/#op._S_type
    public enum AQTType: Int32, Equatable {
        /// -
        case precisely
        
        /// Any number. So a `.double`, `.int32` or `.int64`
        case number = -2
        
        /// A double
        case double = 1
        
        /// A string
        case string = 2
        
        /// A `Document` I.E. "ordered" `Dictionary`
        case document = 3
        
        /// A `Document` as Array
        case array = 4
        
        /// Binary data
        case binary = 5
        
        // 6 is the deprecated type `undefined`
        
        /// A 12-byte unique `ObjectId`
        case objectId = 7
        
        /// A booelan
        case boolean = 8
        
        /// NSDate represented as UNIX Epoch time
        case dateTime = 9
        
        /// Null
        case null = 10
        
        /// A regex with options
        case regex = 11
        
        // 12 is an unsupported DBPointer
        
        /// JavaScript Code
        case jsCode = 13
        
        // 14 is an unsupported `Symbol`
        
        /// JavaScript code executed within a scope
        case jsCodeWithScope = 15
        
        /// `Int32`
        case int32 = 16
        
        /// Timestamp as milliseconds since UNIX Epoch Time
        case timestamp = 17
        
        /// `Int64`
        case int64 = 18
        
        /// High precision decimal
        case decimal128 = 19
        
        /// The min-key
        case minKey = -1
        
        /// The max-key
        case maxKey = 127
    }
    
    /// Returns a Document that represents this AQT as a Query/Filter
    public var document: Document {
        switch self {
        case .typeof(let key, let type):
            if type == .number {
                let aqt = AQT.or([
                                  .typeof(key: key, type: .double),
                                  .typeof(key: key, type: .int32),
                                  .typeof(key: key, type: .int64)
                                  ])
                return aqt.document
                
            } else {
                return [key: ["$type": type.rawValue]]
            }
        case .exactly(let doc):
            return doc
        case .valEquals(let key, let val):
            return [key: ["$eq": val]]
        case .valNotEquals(let key, let val):
            return [key: ["$ne": val]]
        case .greaterThan(let key, let val):
            return [key: ["$gt": val]]
        case .greaterThanOrEqual(let key, let val):
            return [key: ["$gte": val]]
        case .smallerThan(let key, let val):
            return [key: ["$lt": val]]
        case .smallerThanOrEqual(let key, let val):
            return [key: ["$lte": val]]
        case .containsElement(let key, let aqt):
            return [key: ["$elemMatch": aqt.document]]
        case .and(let aqts):
            let expressions = aqts.map{ $0.document }
            
            return ["$and": Document(array: expressions) ]
        case .or(let aqts):
            let expressions = aqts.map{ $0.document }
            
            return ["$or": Document(array: expressions) ]
        case .not(let aqt):
            var query: Document = [:]
            
            for (key, value) in aqt.document {
                query[key] = [
                    "$not": value
                ]
            }
            
            return query
        case .contains(let key, let val, let options):
            return [key: RegularExpression(pattern: val, options: options)]
        case .startsWith(let key, let val):
            return [key: RegularExpression(pattern: "^" + val, options: .anchorsMatchLines)]
        case .endsWith(let key, let val):
            return [key: RegularExpression(pattern: val + "$", options: .anchorsMatchLines)]
        case .nothing:
            return [:]
        case .in(let key, let array):
            return [key: ["$in": Document(array: array)] as Document]
        case .near(let key, let point, let maxDistance, let minDistance):
            return GeometryOperator(key: key, operatorName: "$near", geometry: point, maxDistance: maxDistance, minDistance: minDistance).makeDocument()
        case .geoWithin(let key, let polygon):
            return GeometryOperator(key: key, operatorName: "$geoWithin", geometry: polygon).makeDocument()
        case .exists(let key, let exists):
            return [
                key: [ "$exists": exists ]
            ]
        case .geoIntersects(let key, let geometry):
            return GeometryOperator(key: key, operatorName: "$geoIntersects", geometry: geometry).makeDocument()
        case .nearSphere(let key, let point, let maxDistance, let minDistance):
            return GeometryOperator(key: key, operatorName: "$nearSphere", geometry: point, maxDistance: maxDistance, minDistance: minDistance).makeDocument()
        }
    }
    
    /// Parses the MongoDB query given `Document` into an AQT
    public init(parse document: Document) {
        guard document.count > 0 else {
            // well this one is simple
            self = .nothing
            return
        }
        
        guard document.count > 1 else {
            let pair = document.first!
            self = .init(parseKey: pair.key, value: pair.value)
            return
        }
        
        // Must be and then
        self = .and(document.map(AQT.init))
        
        // Fallback
        self = .exactly(document)
    }
    
    /// Parses a single MongoDB query piece
    public init(parseKey: String, value: Primitive) {
        switch (parseKey, value) {
        case ("$or", let document as Document):
            self = .or(document.map(AQT.init))
        case ("$and", let document as Document):
            self = .and(document.map(AQT.init))
        case (_, let document as Document) where document.count == 1 && document.keys.first == "$eq":
            self = .valEquals(key: parseKey, val: document.first!.value)
        case (_, let document as Document) where document.count == 1 && document.keys.first == "$neq":
            self = .valNotEquals(key: parseKey, val: document.first!.value)
        case (_, let document as Document) where document.count == 1 && document.keys.first == "$gt":
            self = .greaterThan(key: parseKey, val: document.first!.value)
        case (_, let document as Document) where document.count == 1 && document.keys.first == "$gte":
            self = .greaterThanOrEqual(key: parseKey, val: document.first!.value)
        case (_, let document as Document) where document.count == 1 && document.keys.first == "$lt":
            self = .smallerThan(key: parseKey, val: document.first!.value)
        case (_, let document as Document) where document.count == 1 && document.keys.first == "$lte":
            self = .smallerThanOrEqual(key: parseKey, val: document.first!.value)
        case (_, let document as Document) where document.count == 1 && document.type(at: "$in") == .arrayDocument:
            self = .in(key: parseKey, in: (document.first!.value as! Document).arrayRepresentation)
        case (_, let document as Document) where document.count == 1 && document.type(at: "$elemMatch") == .document:
            self = .containsElement(key: parseKey, match: AQT(parse: document[0] as! Document))
        default:
            // fallback
            self = .exactly([parseKey: value])
        }
    }
    
    /// Whether the type in `key` is equal to the AQTType https://docs.mongodb.com/manual/reference/operator/query/type/#op._S_type
    case typeof(key: String, type: AQTType)
    
    /// Does the `Value` within the `key` match this `Value`
    case valEquals(key: String, val: BSON.Primitive)
    
    /// The `Value` within the `key` does not match this `Value`
    case valNotEquals(key: String, val: BSON.Primitive)
    
    /// Whether the `Value` within the `key` is greater than this `Value`
    case greaterThan(key: String, val: BSON.Primitive)
    
    /// Whether the `Value` within the `key` is greater than or equal to this `Value`
    case greaterThanOrEqual(key: String, val: BSON.Primitive)
    
    /// Whether the `Value` within the `key` is smaller than this `Value`
    case smallerThan(key: String, val: BSON.Primitive)
    
    /// Whether the `Value` within the `key` is smaller than or equal to this `Value`
    case smallerThanOrEqual(key: String, val: BSON.Primitive)
    
    /// Whether a subdocument in the array within the `key` matches one of the queries/filters
    case containsElement(key: String, match: AQT)
    
    /// Whether all `AQT` Conditions are correct
    case and([AQT])
    
    /// Whether any of these `AQT` conditions is correct
    case or([AQT])
    
    /// Whether none of these `AQT` conditions are correct
    case not(AQT)
    
    /// Whether nothing needs to be matched. Is always true and just a placeholder
    case nothing
    
    /// Whether the String value within the `key` contains this `String`.
    case contains(key: String, val: String, options: NSRegularExpression.Options)
    
    /// Whether the String value within the `key` starts with this `String`.
    case startsWith(key: String, val: String)
    
    /// Whether the String value within the `key` ends with this `String`.
    case endsWith(key: String, val: String)
    
    /// A literal Document
    case exactly(Document)
    
    /// Value at this key exists, even if it is `Null`
    case exists(key: String, exists: Bool)
    
    /// Value is one of the given values
    case `in`(key: String, in: [BSON.Primitive])

    /// Match all documents containing a `key` with geospatial data that is near the specified GeoJSON `Point`.
    ///
    /// - `key` the field name
    /// - `point` the GeoJSON Point
    /// - `maxDistance` : the maximum distance from the `point`, in meters
    /// - `minDistance` : the minimum distance from the `point`, in meters
    ///
    /// - SeeAlso : https://docs.mongodb.com/manual/reference/operator/query/near/
    case near(key: String, point: Point, maxDistance: Double, minDistance: Double)

    /// Match all documents containing a `key` with geospatial data that exists entirely within the specified `Polygon`.
    /// - `key` the field name
    /// - `polygon` the GeoJSON Polygon
    /// - SeeAlso : https://docs.mongodb.com/manual/reference/operator/query/geoWithin/
    case geoWithin(key: String, polygon: GeoJSON.Polygon)

    /// Match all documents containing a `key` with geospatial data that intersects with the specified shape.
    /// - `key` the field name
    /// - `geometry` the GeoJSON Geometry
    /// - SeeAlso : https://docs.mongodb.com/manual/reference/operator/query/geoIntersects/
    case geoIntersects(key: String, geometry: Geometry)

    /// Match all documents containing a `key` with geospatial data that is near the specified GeoJSON point using spherical geometry.
    ///
    /// - `point` the GeoJSON Point
    /// - `maxDistance` : the maximum distance from the `point`, in meters
    /// - `minDistance` : the minimum distance from the `point`, in meters
    ///
    /// - SeeAlso : https://docs.mongodb.com/manual/reference/operator/query/nearSphere/
    case nearSphere(key: String, point: Point, maxDistance: Double, minDistance: Double)
}

extension AQT : Equatable {
    public static func ==(lhs: AQT, rhs: AQT) -> Bool {
        switch (lhs, rhs) {
        case (.typeof(let key1, let type1), .typeof(let key2, let type2)):
            return key1 == key2 && type1 == type2
            
        // String [something] Primitive type operators
        // "Matching a value of a protocol type is not yet supported", so that's why these are separate cases
        case (.valEquals(let key1, let val1), .valEquals(let key2, let val2)):
            return key1 == key2 && val1.makeBinary() == val2.makeBinary()
        case (.valNotEquals(let key1, let val1), .valNotEquals(let key2, let val2)):
            return key1 == key2 && val1.makeBinary() == val2.makeBinary()
        case (.greaterThan(let key1, let val1), .greaterThan(let key2, let val2)):
            return key1 == key2 && val1.makeBinary() == val2.makeBinary()
        case (.greaterThanOrEqual(let key1, let val1), .greaterThanOrEqual(let key2, let val2)):
            return key1 == key2 && val1.makeBinary() == val2.makeBinary()
        case (.smallerThan(let key1, let val1), .smallerThan(let key2, let val2)):
            return key1 == key2 && val1.makeBinary() == val2.makeBinary()
        case (.smallerThanOrEqual(let key1, let val1), .smallerThanOrEqual(let key2, let val2)):
            return key1 == key2 && val1.makeBinary() == val2.makeBinary()
        case (.containsElement(let key1, let aqt1), .containsElement(let key2, let aqt2)):
            return key1 == key2 && aqt1 == aqt2
            
        case (.and(let aqtArray1), .and(let aqtArray2)),
             (.or(let aqtArray1), .or(let aqtArray2)):
            return aqtArray1 == aqtArray2
        case (.not(let aqt1), .not(let aqt2)):
            return aqt1 == aqt2
        case (.nothing, .nothing):
            return true
        case (.contains(let key1, let val1, let options1), .contains(let key2, let val2, let options2)):
            return key1 == key2 && val1 == val2 && options1 == options2
        case (.startsWith(let key1, let val1), .startsWith(let key2, let val2)),
             (.endsWith(let key1, let val1), .endsWith(let key2, let val2)):
            return key1 == key2 && val1 == val2
        case (.exactly(let doc1), .exactly(let doc2)):
            return doc1 == doc2
        case (.exists(let key1, let exists1), .exists(let key2, let exists2)):
            return key1 == key2 && exists1 == exists2
        case (.in(let key1, let array1), .in(let key2, let array2)):
            return key1 == key2 && array1.makeBinary() == array2.makeBinary()
        case (.near(let key1, let point1, let maxDistance1, let minDistance1), .near(let key2, let point2, let maxDistance2, let minDistance2)),
             (.nearSphere(let key1, let point1, let maxDistance1, let minDistance1), .nearSphere(let key2, let point2, let maxDistance2, let minDistance2)):
            return key1 == key2 && point1 == point2 && maxDistance1 == maxDistance2 && minDistance1 == minDistance2
        case (.geoWithin(let key1, polygon: let polygon1), .geoWithin(let key2, polygon: let polygon2)):
            return key1 == key2 && polygon1 == polygon2
        case (.geoIntersects(let key1, let geometry1), .geoIntersects(let key2, let geometry2)):
            print("MongoKitten: AQT.geoIntersects == AQT.geoIntersects is not fully implemented")
            return key1 == key2 && geometry1.type == geometry2.type
        default: return false
        }
    }
}

/// A `Query` that consists of an `AQT` statement
public struct Query: ExpressibleByDictionaryLiteral, ValueConvertible, ExpressibleByStringLiteral {
    /// Initializes this Query with a String literal for a text search
    public init(stringLiteral value: String) {
        self = .textSearch(forString: value)
    }
    
    /// Initializes this Query with a String literal for a text search
    public init(unicodeScalarLiteral value: String) {
        self = .textSearch(forString: value)
    }
    
    /// Initializes this Query with a String literal for a text search
    public init(extendedGraphemeClusterLiteral value: String) {
        self = .textSearch(forString: value)
    }
    
    /// Returns the Document state of this Query
    public func makeDocument() -> Document {
        return self.queryDocument
    }
    
    /// The `Document` that can be sent to the MongoDB Server as a query/filter
    public func makePrimitive() -> BSON.Primitive {
        return self.queryDocument
    }

    /// Initializes an empty query, matching nothing
    public init() {
        self.aqt = .nothing
    }

    /// Creates a Query from a Dictionary Literal
    public init(dictionaryLiteral elements: (String, BSON.Primitive?)...) {
        if elements.count == 0 {
            self.aqt = .nothing
        } else {
            self.aqt = .exactly(Document(dictionaryElements: elements))
        }
    }
    
    /// The `Document` that can be sent to the MongoDB Server as a query/filter
    public var queryDocument: Document {
        return aqt.document
    }
    
    /// The `AQT` statement that's used as a query/filter
    public var aqt: AQT
    
    /// Initializes a `Query` with an `AQT` filter
    public init(aqt: AQT) {
        self.aqt = aqt
    }
    
    /// Initializes a Query from a Document and uses this Document as the Query
    public init(_ document: Document) {
        if document.count == 0 {
            self.aqt = .nothing
        } else {
            self.aqt = .exactly(document)
        }
    }
    
    /// Creates a textSearch for a specified string
    public static func textSearch(forString string: String, language: String? = nil, caseSensitive: Bool = false, diacriticSensitive: Bool = false) -> Query {
        var textSearch: Document = ["$text": [
            "$search": string,
            "$caseSensitive": caseSensitive,
            "$diacriticSensitive": diacriticSensitive
            ]
        ]
    
        if let language = language {
            textSearch["$language"] = language
        }
        
        return Query(textSearch)
    }
}
