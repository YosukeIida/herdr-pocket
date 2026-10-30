import XCTest
@testable import HerdrKit

/// A transport whose "core" is the test: it sees every write and injects bytes.
final class FakeTransport: ByteTransport, @unchecked Sendable {
    let lock = NSLock()
    var written = Data()
    var onBytes: (@Sendable (Data) -> Void)?
    var onClose: (@Sendable (Error?) -> Void)?
    var closed = false

    func start(onBytes: @escaping @Sendable (Data) -> Void, onStderr: @escaping @Sendable (Data) -> Void,
               onClose: @escaping @Sendable (Error?) -> Void) async throws {
        self.onBytes = onBytes; self.onClose = onClose
    }
    func write(_ data: Data) async throws { lock.withLock { written.append(data) } }
    func close() { lock.withLock { closed = true } }

    func feed(_ d: Data) { onBytes?(d) }
    func feed(_ f: Frame) { feed(f.encoded()) }
    func reply(_ id: Int, _ result: JSONValue) {
        feed(Frame(channel: 0, kind: 0, payload: (["jsonrpc": "2.0", "id": .number(Double(id)), "result": result] as JSONValue).encoded()))
    }

    /// Frames written after the hello line.
    func frames() throws -> [Frame] {
        let w = lock.withLock { written }
        guard let nl = w.firstIndex(of: 0x0a) else { return [] }
        var d = FrameDecoder(); d.append(Data(w[w.index(after: nl)...]))
        return try d.drain()
    }

    func waitFor(_ pred: @escaping ([Frame]) -> Bool) async throws -> [Frame] {
        for _ in 0..<200 {
            if let f = try? frames(), pred(f) { return f }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("timed out waiting for writes"); return try frames()
    }
}

final class ClientTests: XCTestCase {
    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec"]}}"# + "\n").utf8)

    func connected() async throws -> (HerdrClient, FakeTransport) {
        let t = FakeTransport()
        let c = HerdrClient(transport: t)
        c.callbackQueue = DispatchQueue(label: "test")
        async let hello = c.connect()
        try await Task.sleep(for: .milliseconds(50))
        // hello reply and the first frame arrive in one chunk
        t.feed(Self.helloLine + Frame(channel: 5, kind: 0, payload: Data("early".utf8)).encoded())
        let info = try await hello
        XCTAssertEqual(info.coreName, "devhub")
        let w = t.lock.withLock { t.written }
        XCTAssertTrue(String(decoding: w, as: UTF8.self).hasPrefix(#"{"jsonrpc":"2.0","id":0,"method":"hello","params":{"framed":true"#))
        return (c, t)
    }

    func testHelloChecks() {
        XCTAssertThrowsError(try HerdrClient.check(hello: ["result": ["generation": 1, "version": "0.1.9", "methods": []]]))
        XCTAssertThrowsError(try HerdrClient.check(hello: ["result": ["generation": 2, "version": "0.2.0", "methods": []]]))
        XCTAssertThrowsError(try HerdrClient.check(hello: ["error": ["code": -32000, "message": "nope"]]))
        XCTAssertTrue(HerdrClient.semverLess(HerdrClient.semver("0.1.9"), HerdrClient.semver("0.1.11")))
    }

    func testCallsOutOfOrderAndErrors() async throws {
        let (c, t) = try await connected()
        async let a = c.call("terminal.list")
        async let b = c.call("terminal.get", ["terminal": "t9"])
        let frames = try await t.waitFor { $0.filter { $0.channel == 0 }.count == 2 }
        let ids = frames.compactMap { try? JSONValue.parse($0.payload) }.compactMap { m -> (String, Int)? in
            guard let i = m["id"].int else { return nil }; return (m["method"].string ?? "", i) }
        let listID = try XCTUnwrap(ids.first { $0.0 == "terminal.list" }?.1)
        let getID = try XCTUnwrap(ids.first { $0.0 == "terminal.get" }?.1)
        t.feed(Frame(channel: 0, kind: 0, payload: Data(#"{"id":\#(getID),"jsonrpc":"2.0","error":{"code":-32000,"message":"no terminal t9","data":{"kind":"not_found","hint":"see hc ls"}}}"#.utf8)))
        t.reply(listID, ["terminals": []])
        let ra = try await a
        XCTAssertEqual(ra["terminals"], [])
        do { _ = try await b; XCTFail() } catch let e as HerdrError {
            XCTAssertEqual(e.kind, "not_found"); XCTAssertEqual(e.localizedDescription, "no terminal t9 (see hc ls)")
        }
    }

    func testAttachEarlyFramesCreditCloseEcho() async throws {
        let (c, t) = try await connected()
        async let s = c.attach(terminal: "t1", cols: 80, rows: 24, observe: true)
        let fr = try await t.waitFor { $0.contains { $0.channel == 0 } }
        let msg = try JSONValue.parse(fr.first { $0.channel == 0 }!.payload)
        XCTAssertEqual(msg["params"]["observe"], .bool(true))
        // more early data, then the reply naming channel 5
        t.feed(Frame(channel: 5, kind: 0, payload: Data("-paint".utf8)))
        t.reply(msg["id"].int!, ["channel": 5, "terminal": ["address": "t1", "state": "live"]])
        let stream = try await s
        XCTAssertEqual(stream.channel, 5)
        let got = expectation(description: "data")
        var received = Data()
        DispatchQueue(label: "test").sync {}   // nothing; handlers set below on the callback queue
        c.callbackQueue.sync {
            stream.onData = { d in received.append(d); if received.count == 11 { got.fulfill() } }
        }
        await fulfillment(of: [got], timeout: 2)
        XCTAssertEqual(String(decoding: received, as: UTF8.self), "early-paint")
        let credits = try await t.waitFor { $0.filter { $0.kind == FrameKind.credit }.count == 2 }.filter { $0.kind == FrameKind.credit }
        XCTAssertEqual(credits.map(\.channel), [5, 5])
        XCTAssertEqual(credits.map(\.payload), [Frame.le32(5), Frame.le32(6)])

        // detach: CLOSE sent once; the echo and late data are ignored
        c.callbackQueue.sync { stream.detach() }
        _ = try await t.waitFor { $0.contains { $0.kind == FrameKind.close && $0.channel == 5 } }
        t.feed(Frame(channel: 5, kind: 0, payload: Data("late".utf8)))
        t.feed(Frame(channel: 5, kind: FrameKind.close))
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(received.count, 11)
        XCTAssertTrue(c.isConnected)
    }

    func testCoreCloseAndLost() async throws {
        let (c, t) = try await connected()
        async let s = c.attach(terminal: "t2", cols: 80, rows: 24)
        let fr = try await t.waitFor { $0.contains { $0.channel == 0 } }
        let id = try JSONValue.parse(fr.first { $0.channel == 0 }!.payload)["id"].int!
        t.reply(id, ["channel": 6, "terminal": ["address": "t2", "state": "live"]])
        let stream = try await s
        let closed = expectation(description: "close")
        c.callbackQueue.sync { stream.onClose = { why in XCTAssertEqual(why["reason"], "exited"); closed.fulfill() } }
        t.feed(Frame(channel: 6, kind: FrameKind.close, payload: Data(#"{"reason":"exited","exit_code":0}"#.utf8)))
        await fulfillment(of: [closed], timeout: 2)

        // A pending call fails with lost when the transport ends.
        async let pending = c.call("terminal.list")
        _ = try await t.waitFor { $0.filter { $0.channel == 0 }.count == 2 }
        let disconnected = expectation(description: "disconnect")
        c.onDisconnect = { e in XCTAssertEqual(e.kind, "lost"); disconnected.fulfill() }
        t.onClose?(nil)
        do { _ = try await pending; XCTFail() } catch let e as HerdrError { XCTAssertEqual(e.kind, "lost") }
        await fulfillment(of: [disconnected], timeout: 2)
        do { _ = try await c.call("x"); XCTFail() } catch {}
    }

    func testTimeoutAndCancel() async throws {
        let (c, t) = try await connected()
        do { _ = try await c.call("slow", timeout: 0.1); XCTFail() } catch let e as HerdrError { XCTAssertEqual(e.kind, "timeout") }
        let task = Task { try await c.exec(argv: ["sleep", "9"]) }
        let fr = try await t.waitFor { $0.contains { (try? JSONValue.parse($0.payload))?["method"] == "machine.exec" } }
        let id = try JSONValue.parse(fr.first { (try? JSONValue.parse($0.payload))?["method"] == "machine.exec" }!.payload)["id"]
        task.cancel()
        let r = await task.result
        XCTAssertThrowsError(try r.get())
        let all = try await t.waitFor { $0.contains { (try? JSONValue.parse($0.payload))?["method"] == "$/cancelRequest" } }
        let cancel = try JSONValue.parse(all.first { (try? JSONValue.parse($0.payload))?["method"] == "$/cancelRequest" }!.payload)
        XCTAssertEqual(cancel["params"]["id"], id)
        XCTAssertEqual(cancel["id"], .null)
    }

    /// A cancelled attach whose reply arrives late: the client closes the
    /// channel it names (the core would otherwise keep a typing viewer) and
    /// drops the early frames it buffered.
    func testLateAttachReplyClosesChannel() async throws {
        let (c, t) = try await connected()
        let task = Task { try await c.attach(terminal: "t3", cols: 80, rows: 24) }
        let fr = try await t.waitFor { $0.contains { (try? JSONValue.parse($0.payload))?["method"] == "terminal.attach" } }
        let id = try XCTUnwrap(JSONValue.parse(fr.first { (try? JSONValue.parse($0.payload))?["method"] == "terminal.attach" }!.payload)["id"].int)
        task.cancel()
        _ = await task.result
        t.feed(Frame(channel: 9, kind: 0, payload: Data("paint".utf8)))
        t.reply(id, ["channel": 9, "terminal": ["address": "t3", "state": "live"]])
        _ = try await t.waitFor { $0.contains { $0.kind == FrameKind.close && $0.channel == 9 } }
        // Late data and the echo are swallowed; the connection stays up.
        t.feed(Frame(channel: 9, kind: 0, payload: Data("more".utf8)))
        t.feed(Frame(channel: 9, kind: FrameKind.close))
        try await Task.sleep(for: .milliseconds(30))
        XCTAssertTrue(c.isConnected)
        XCTAssertEqual(try t.frames().filter { $0.kind == FrameKind.close && $0.channel == 9 }.count, 1)
    }

    func testJSONNumbersOutOfRangeDontTrap() {
        XCTAssertNil(JSONValue.number(1e19).int)
        XCTAssertNil(JSONValue.number(1e20).uint64)
        XCTAssertEqual(JSONValue.number(-5).uint64, 0)
        XCTAssertEqual(JSONValue.number(42.9).int, 42)
        XCTAssertEqual(JSONValue.number(1.8e19).uint64, 18_000_000_000_000_000_000)
    }

    func testExecDecodesBase64AndStripsOwnMachine() async throws {
        let (c, t) = try await connected()
        async let r = c.exec(argv: ["echo", "hi"], on: "devhub", timeout: 7)
        let fr = try await t.waitFor { $0.contains { $0.channel == 0 } }
        let msg = try JSONValue.parse(fr.first { $0.channel == 0 }!.payload)
        XCTAssertEqual(msg["params"]["on"], .null)
        XCTAssertEqual(msg["params"]["timeout"], 7)
        t.reply(msg["id"].int!, ["code": 0, "stdout": .string(Data("hi\n".utf8).base64EncodedString()), "stderr": "", "timed_out": false])
        let res = try await r
        XCTAssertEqual(res, ExecResult(code: 0, stdout: Data("hi\n".utf8), stderr: Data(), timedOut: false))
    }

    func testSubscribeCreditsAndUpdates() async throws {
        let (c, t) = try await connected()
        async let s = c.subscribe(coalesce: 0)
        let fr = try await t.waitFor { $0.contains { $0.channel == 0 } }
        let id = try JSONValue.parse(fr.first { $0.channel == 0 }!.payload)["id"].int!
        t.feed(Frame(channel: 9, kind: 0, payload: Data(#"{"jsonrpc":"2.0","method":"event","params":{"seq":4,"type":"title","terminal":"t1","data":{"title":"early"}}}"#.utf8 + [0x0a])))
        t.reply(id, ["seq": 3, "channel": 9, "terminals": [["address": "t1", "state": "live", "title": "a"]]])
        let sub = try await s
        XCTAssertEqual(sub.snapshot.first?.title, "a")
        let got = expectation(description: "update")
        c.callbackQueue.sync { sub.onUpdate = { u in if u.terminals.first?.title == "late" { got.fulfill() } } }
        t.feed(Frame(channel: 9, kind: 0, payload: Data(#"{"jsonrpc":"2.0","method":"event","params":{"seq":5,"type":"title","terminal":"t1","data":{"title":"late"}}}"#.utf8 + [0x0a])))
        await fulfillment(of: [got], timeout: 2)
        let credits = try await t.waitFor { $0.filter { $0.kind == FrameKind.credit && $0.channel == 9 }.count >= 3 }
            .filter { $0.kind == FrameKind.credit }
        XCTAssertTrue(credits.contains { $0.payload == Frame.le32(1 << 20) })
    }
}
