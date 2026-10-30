import Foundation

/// Frame kinds on the framed wire (SPEC.md §1, core `wire.rs`).
public enum FrameKind {
    public static let data: UInt8 = 0
    public static let credit: UInt8 = 1
    public static let close: UInt8 = 2
    public static let resize: UInt8 = 3
    public static let focus: UInt8 = 4
    public static let facts: UInt8 = 5
}

/// One frame: `channel u32 LE | kind u8 | len u32 LE | payload`.
public struct Frame: Equatable, Sendable {
    public static let headerSize = 9
    /// Largest payload the core accepts or sends (16 MiB).
    public static let maxPayload = 16 << 20

    public var channel: UInt32
    public var kind: UInt8
    public var payload: Data

    public init(channel: UInt32, kind: UInt8, payload: Data = Data()) {
        self.channel = channel; self.kind = kind; self.payload = payload
    }

    public func encoded() -> Data {
        var d = Data(capacity: Self.headerSize + payload.count)
        withUnsafeBytes(of: channel.littleEndian) { d.append(contentsOf: $0) }
        d.append(kind)
        withUnsafeBytes(of: UInt32(payload.count).littleEndian) { d.append(contentsOf: $0) }
        d.append(payload)
        return d
    }

    public static func credit(_ channel: UInt32, _ bytes: Int) -> Frame {
        Frame(channel: channel, kind: FrameKind.credit, payload: le32(UInt32(clamping: bytes)))
    }

    static func le32(_ v: UInt32) -> Data { withUnsafeBytes(of: v.littleEndian) { Data($0) } }
}

public struct FrameError: Error, Equatable, CustomStringConvertible {
    public var length: Int
    public var description: String { "frame of \(length) bytes is over the 16 MiB limit" }
}

/// Incremental frame parser: feed it bytes as they arrive, take whole frames
/// out. Frame boundaries may fall anywhere in the input.
public struct FrameDecoder: Sendable {
    private var buffer: [UInt8] = []
    private var head = 0

    public init() {}

    /// Bytes waiting for the rest of their frame.
    public var buffered: Int { buffer.count - head }

    public mutating func append(_ data: Data) {
        if head > 0, head >= buffer.count {
            buffer.removeAll(keepingCapacity: true); head = 0
        } else if head > 65_536, head * 2 > buffer.count {
            buffer.removeSubrange(0..<head); head = 0
        }
        buffer.append(contentsOf: data)
    }

    /// The next whole frame, nil if more bytes are needed. Throws on an
    /// oversized length (a protocol error: drop the connection).
    public mutating func next() throws -> Frame? {
        guard buffer.count - head >= Frame.headerSize else { return nil }
        let (channel, kind, len) = buffer.withUnsafeBytes { raw -> (UInt32, UInt8, Int) in
            let ch = raw.loadUnaligned(fromByteOffset: head, as: UInt32.self)
            let k = raw[head + 4]
            let l = raw.loadUnaligned(fromByteOffset: head + 5, as: UInt32.self)
            return (UInt32(littleEndian: ch), k, Int(UInt32(littleEndian: l)))
        }
        guard len <= Frame.maxPayload else { throw FrameError(length: len) }
        guard buffer.count - head >= Frame.headerSize + len else { return nil }
        let start = head + Frame.headerSize
        let payload = Data(buffer[start..<start + len])
        head = start + len
        return Frame(channel: channel, kind: kind, payload: payload)
    }

    /// Every whole frame currently buffered.
    public mutating func drain() throws -> [Frame] {
        var out: [Frame] = []
        while let f = try next() { out.append(f) }
        return out
    }
}
