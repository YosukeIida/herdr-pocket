import Foundation

/// Untyped JSON, as the core speaks it. Keeps unknown fields so documents
/// written back to the core lose nothing.
public enum JSONValue: Equatable, Hashable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public subscript(key: String) -> JSONValue {
        get {
            if case .object(let o) = self { return o[key] ?? .null }
            return .null
        }
        set {
            var o = object ?? [:]
            o[key] = newValue
            self = .object(o)
        }
    }
    public subscript(index: Int) -> JSONValue {
        if case .array(let a) = self, a.indices.contains(index) { return a[index] }
        return .null
    }
    public var string: String? { if case .string(let s) = self { return s }; return nil }
    public var double: Double? { if case .number(let n) = self { return n }; return nil }
    public var int: Int? { double.flatMap { $0.isFinite ? Int(exactly: $0.rounded(.towardZero)) : nil } }
    public var uint64: UInt64? { double.flatMap { $0.isFinite ? UInt64(exactly: max(0, $0).rounded(.towardZero)) : nil } }
    public var bool: Bool? { if case .bool(let b) = self { return b }; return nil }
    public var array: [JSONValue]? { if case .array(let a) = self { return a }; return nil }
    public var object: [String: JSONValue]? { if case .object(let o) = self { return o }; return nil }
    public var isNull: Bool { self == .null }

    /// Removes `key` from an object (no-op otherwise).
    public mutating func removeValue(forKey key: String) {
        guard case .object(var o) = self else { return }
        o.removeValue(forKey: key)
        self = .object(o)
    }

    /// Compact JSON text, for logs and debugging.
    public var jsonString: String { String(decoding: encoded(), as: UTF8.self) }

    public init(any: Any?) {
        switch any {
        case nil, is NSNull: self = .null
        case let n as NSNumber:
            if CFGetTypeID(n) == CFBooleanGetTypeID() { self = .bool(n.boolValue) } else { self = .number(n.doubleValue) }
        case let s as String: self = .string(s)
        case let a as [Any]: self = .array(a.map { JSONValue(any: $0) })
        case let o as [String: Any]: self = .object(o.mapValues { JSONValue(any: $0) })
        default: self = .null
        }
    }

    public var any: Any {
        switch self {
        case .null: return NSNull()
        case .bool(let b): return b
        case .number(let n): return n.rounded() == n && abs(n) < 9e15 ? Int64(n) as Any : n
        case .string(let s): return s
        case .array(let a): return a.map { $0.any }
        case .object(let o): return o.mapValues { $0.any }
        }
    }

    public static func parse(_ data: Data) throws -> JSONValue {
        JSONValue(any: try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]))
    }
    public func encoded() -> Data {
        (try? JSONSerialization.data(withJSONObject: any, options: [.fragmentsAllowed, .withoutEscapingSlashes])) ?? Data("null".utf8)
    }
}

extension JSONValue: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral,
    ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral, ExpressibleByNilLiteral, ExpressibleByFloatLiteral {
    public init(stringLiteral v: String) { self = .string(v) }
    public init(integerLiteral v: Int) { self = .number(Double(v)) }
    public init(floatLiteral v: Double) { self = .number(v) }
    public init(booleanLiteral v: Bool) { self = .bool(v) }
    public init(arrayLiteral e: JSONValue...) { self = .array(e) }
    public init(dictionaryLiteral e: (String, JSONValue)...) { self = .object(Dictionary(e, uniquingKeysWith: { $1 })) }
    public init(nilLiteral: ()) { self = .null }
}
