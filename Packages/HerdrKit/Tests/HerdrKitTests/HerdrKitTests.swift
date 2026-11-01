import XCTest
@testable import HerdrKit

final class JSONTests: XCTestCase {
    func testNumbersAreNotBools() throws {
        let v = try JSONValue.parse(Data(#"{"a":1,"b":true,"c":0,"d":false}"#.utf8))
        XCTAssertEqual(v["a"].int, 1)
        XCTAssertEqual(v["b"].bool, true)
        XCTAssertEqual(v["c"], .number(0))
        XCTAssertEqual(v["d"], .bool(false))
    }
}

final class FrameTests: XCTestCase {
    func testEncodeMatchesSpecHex() {
        XCTAssertEqual(Frame.credit(3, 16384).encoded(), Data([3,0,0,0, 1, 4,0,0,0, 0x00,0x40,0,0]))
        XCTAssertEqual(Frame(channel: 3, kind: FrameKind.close).encoded(), Data([3,0,0,0, 2, 0,0,0,0]))
        XCTAssertEqual(Frame(channel: 3, kind: 0, payload: Data("ls\r".utf8)).encoded(), Data([3,0,0,0, 0, 3,0,0,0, 0x6c,0x73,0x0d]))
    }

    func testSplitFramesByteByByte() throws {
        let frames = [Frame(channel: 0, kind: 0, payload: Data(#"{"id":1}"#.utf8)),
                      Frame(channel: 7, kind: 0, payload: Data(repeating: 0xAB, count: 1000)),
                      Frame(channel: 7, kind: 2)]
        let wire = frames.map { $0.encoded() }.reduce(Data(), +)
        var d = FrameDecoder(), out: [Frame] = []
        for b in wire { d.append(Data([b])); while let f = try d.next() { out.append(f) } }
        XCTAssertEqual(out, frames)
        XCTAssertEqual(d.buffered, 0)
    }

    func testMergedFramesInOneChunk() throws {
        let frames = (0..<50).map { Frame(channel: UInt32($0 % 3), kind: 0, payload: Data(repeating: UInt8($0), count: $0 * 37)) }
        var d = FrameDecoder()
        d.append(frames.map { $0.encoded() }.reduce(Data(), +) + Data([1, 0]))   // plus a partial header
        XCTAssertEqual(try d.drain(), frames)
        XCTAssertEqual(d.buffered, 2)
    }

    func testOversizedFrameThrows() {
        var d = FrameDecoder()
        var h = Data([1,0,0,0, 0]); withUnsafeBytes(of: UInt32(17 << 20).littleEndian) { h.append(contentsOf: $0) }
        d.append(h)
        XCTAssertThrowsError(try d.next())
    }

    func testTerminalStreamResizePayload() {
        let s = TerminalStream(channel: 3, record: TerminalRecord(raw: [:]))
        var sent: [(UInt8, Data)] = []
        s.sink = { sent.append(($0, $1)) }
        s.resize(cols: 80, rows: 24)
        XCTAssertEqual(sent.first?.0, 3)
        XCTAssertEqual(sent.first?.1, Data([0x50, 0, 0x18, 0]))
    }
}

final class EventLinesTests: XCTestCase {
    let t7: JSONValue = ["address": "t7", "state": "live", "pid": 5, "turn": 1, "title": "x",
                         "foreground": ["pid": 6, "name": "claude", "argv": ["claude"], "cwd": "/w"], "status": .null]

    func lines(_ s: [String]) -> Data { Data((s.joined(separator: "\n") + "\n").utf8) }

    func testApplyKinds() {
        var e = EventLines(snapshot: ["seq": 10, "terminals": [t7, ["address": "t8", "state": "live"]]])
        var p = e.push(lines([
            #"{"jsonrpc":"2.0","method":"event","params":{"seq":11,"type":"status","terminal":"t7","data":{"status":{"state":"working","app":"claude-code"},"records":{},"reported":true}}}"#,
            #"{"jsonrpc":"2.0","method":"event","params":{"seq":12,"type":"turn","terminal":"t7","data":{"turn":2,"state":"idle"}}}"#,
            #"{"jsonrpc":"2.0","method":"event","params":{"seq":13,"type":"size","terminal":"t7","data":{"cols":100,"rows":30}}}"#,
            #"{"jsonrpc":"2.0","method":"event","params":{"seq":14,"type":"title","terminal":"t7","data":{"title":"Fixing"}}}"#,
            #"{"jsonrpc":"2.0","method":"heartbeat","params":{"seq":14}}"#,
        ]))
        XCTAssertTrue(p.terminals)
        XCTAssertEqual(p.lines, 5)
        XCTAssertEqual(p.events.map(\.type), ["status", "turn", "size", "title"])
        let r = TerminalRecord(raw: e.terminals[0])
        XCTAssertEqual(r.statusWord, "working"); XCTAssertEqual(r.statusApp, "claude-code")
        XCTAssertEqual(r.turn, 2); XCTAssertEqual(r.cols, 100); XCTAssertEqual(r.rows, 30); XCTAssertEqual(r.title, "Fixing")
        XCTAssertEqual(r.raw["reported"], .bool(true))

        // stale seq dropped
        p = e.push(lines([#"{"jsonrpc":"2.0","method":"event","params":{"seq":12,"type":"title","terminal":"t7","data":{"title":"old"}}}"#]))
        XCTAssertFalse(p.terminals); XCTAssertEqual(TerminalRecord(raw: e.terminals[0]).title, "Fixing")

        // lost keeps it live, clears pid and foreground
        _ = e.push(lines([#"{"jsonrpc":"2.0","method":"event","params":{"seq":15,"type":"lost","terminal":"t7","data":{"reason":"lost","exit_code":null,"signal":null,"finished_ms":5}}}"#]))
        XCTAssertEqual(e.terminals[0]["state"], "live"); XCTAssertEqual(e.terminals[0]["pid"], .null)
        XCTAssertEqual(e.terminals[0]["foreground"], .null); XCTAssertEqual(e.terminals[0]["reason"], "lost")
        XCTAssertEqual(TerminalRecord(raw: e.terminals[0]).cwd, "")

        // finished, removed, created, labels with record, unknown terminal ignored
        _ = e.push(lines([
            #"{"jsonrpc":"2.0","method":"event","params":{"seq":16,"type":"finished","terminal":"t8","data":{"reason":"exited","exit_code":0,"signal":null,"finished_ms":9}}}"#,
            #"{"jsonrpc":"2.0","method":"event","params":{"seq":17,"type":"created","terminal":"t9","data":{"address":"t9","state":"live"}}}"#,
            #"{"jsonrpc":"2.0","method":"event","params":{"seq":18,"type":"labels","terminal":"t9","data":{"labels":{"a":"b"},"record":{"address":"t9","state":"live","labels":{"a":"b"}}}}}"#,
            #"{"jsonrpc":"2.0","method":"event","params":{"seq":19,"type":"removed","terminal":"t7","data":{}}}"#,
            #"{"jsonrpc":"2.0","method":"event","params":{"seq":20,"type":"title","terminal":"t404","data":{"title":"?"}}}"#,
        ]))
        XCTAssertEqual(e.terminals.map { $0["address"].string! }, ["t8", "t9"])
        XCTAssertEqual(e.terminals[0]["state"], "finished")
        XCTAssertEqual(TerminalRecord(raw: e.terminals[1]).labels, ["a": "b"])
        XCTAssertEqual(e.live.map(\.address), ["t9"])
        XCTAssertEqual(e.seq, 20)
    }

    func testLineSplitAcrossPushesAndDocAndMissed() {
        var e = EventLines(snapshot: ["seq": 1, "terminals": []])
        let line = #"{"jsonrpc":"2.0","method":"event","params":{"seq":2,"type":"doc","data":{"name":"herdr-app","version":18}}}"# + "\n"
        let bytes = Array(line.utf8)
        var p = e.push(Data(bytes[0..<30]))
        XCTAssertTrue(p.docs.isEmpty)
        p = e.push(Data(bytes[30...]) + Data("garbage\n".utf8))
        XCTAssertEqual(p.docs, [DocChange(name: "herdr-app", machine: nil, version: 18)])
        XCTAssertFalse(p.terminals)
        p = e.push(lines([#"{"jsonrpc":"2.0","method":"missed","params":{"seq":57,"terminals":[{"address":"t1","state":"live"}]}}"#]))
        XCTAssertTrue(p.missed); XCTAssertEqual(e.seq, 57); XCTAssertEqual(e.terminals.count, 1)
    }
}

final class LayoutTests: XCTestCase {
    func fixture() throws -> JSONValue {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "sample-doc", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONValue.parse(Data(contentsOf: url))
    }

    func testParseFixture() throws {
        let spaces = Layout.spaces(from: try fixture())
        XCTAssertEqual(spaces.count, 4)
        XCTAssertEqual(spaces[0].name, ""); XCTAssertEqual(spaces[0].folder, "")
        XCTAssertEqual(spaces[0].tabs.first?.panes.first?.terminal, "t1")
        XCTAssertEqual(spaces[2].tabs.count, 6)
        XCTAssertTrue(spaces.allSatisfy { $0.id.hasPrefix("sp") && $0.tabs.allSatisfy { $0.id.hasPrefix("tb") } })
        XCTAssertEqual(spaces.flatMap(\.tabs).flatMap(\.panes).compactMap(\.terminal).count, 11)
        XCTAssertEqual(Layout.spaces(from: .null), [])
        XCTAssertEqual(Layout.spaces(from: ["spaces": [["id": "sp1"]]]), [SpaceRef(id: "sp1", name: "", folder: "", tabs: [])])
    }

    func testIDs() {
        let id = Layout.newID("tb")
        XCTAssertEqual(id.count, 34); XCTAssertTrue(id.hasPrefix("tb"))
        XCTAssertTrue(id.dropFirst(2).allSatisfy { "0123456789abcdef".contains($0) })
        XCTAssertNotEqual(Layout.newID("p"), Layout.newID("p"))
    }

    func testAddTabAfterSelectedAndPreservesUnknownFields() throws {
        var v = try fixture()
        var sp = v["spaces"].array!
        sp[2]["look"] = ["accent": "x"]                     // unknown field to preserve
        v["spaces"] = .array(sp)
        let space = Layout.spaces(from: v)[2]
        let tab = Layout.tabJSON(id: "tbNEW", name: "", paneID: "pNEW", terminal: "t99")
        let out = try Layout.addTab(v, space: space.id, after: space.tabs[1].id, tab: tab)
        let s2 = Layout.spaces(from: out)[2]
        XCTAssertEqual(s2.tabs.map(\.id)[2], "tbNEW")
        XCTAssertEqual(s2.tabs[2].panes, [PaneRef(id: "pNEW", terminal: "t99", mod: nil, modProps: .null)])
        XCTAssertEqual(out["spaces"][2]["look"], ["accent": "x"])
        XCTAssertEqual(out["spaces"][2]["tabs"][2]["root"]["id"], "tbNEW")
        XCTAssertThrowsError(try Layout.addTab(v, space: "spNOPE", after: nil, tab: tab))
    }

    func testAddSpaceToEmptyDoc() {
        let tab = Layout.tabJSON(id: "tb1", name: "", paneID: "p1", terminal: "t1")
        let out = Layout.addSpace(.null, id: "sp1", folder: "/w", tab: tab)
        XCTAssertEqual(Layout.spaces(from: out).map(\.id), ["sp1"])
        XCTAssertEqual(out["spaces"][0]["folder"], "/w")
    }

    func testRemoveLastPaneRemovesTabAndSpace() throws {
        let v = try fixture()
        let first = Layout.spaces(from: v)[0]
        let r = try Layout.removePane(v, pane: first.tabs[0].panes[0].id)
        XCTAssertEqual(r.removedTab, first.tabs[0].id)
        XCTAssertEqual(r.removedSpace, first.id)
        XCTAssertEqual(r.terminal, "t1")
        XCTAssertEqual(Layout.spaces(from: r.value).count, 3)

        let qd = Layout.spaces(from: v)[2]
        let r2 = try Layout.removePane(v, pane: qd.tabs[0].panes[0].id)
        XCTAssertNil(r2.removedSpace)
        XCTAssertEqual(Layout.spaces(from: r2.value)[2].tabs.count, 5)
    }

    func testRemovePaneWeightsAndCollapse() throws {
        // row[ a(w .5), column[ b, c ](w .5) ]: removing b collapses the column into c, keeping its size.
        let root: JSONValue = ["id": "tb1", "type": "row", "children": [
            ["id": "pa", "type": "block", "content": ["terminal": "t1"], "size": ["weight": 0.5], "title": "keep me"],
            ["id": "s1", "type": "column", "size": ["weight": 0.5], "children": [
                ["id": "pb", "type": "block", "content": ["terminal": "t2"]],
                ["id": "pc", "type": "block", "content": ["terminal": "t3"], "size": ["px": 200]],
            ]],
        ]]
        let doc: JSONValue = ["spaces": [["id": "sp1", "tabs": [["id": "tb1", "name": "", "root": root]]]]]
        let r = try Layout.removePane(doc, pane: "pb")
        let newRoot = r.value["spaces"][0]["tabs"][0]["root"]
        XCTAssertEqual(newRoot["id"], "tb1")
        XCTAssertEqual(newRoot["children"].array?.count, 2)
        XCTAssertEqual(newRoot["children"][1]["id"], "pc")
        XCTAssertEqual(newRoot["children"][1]["size"], ["weight": 0.5])   // took the column's slot size
        XCTAssertEqual(newRoot["children"][0]["title"], "keep me")

        // Removing the first child of a row gives its weight to the next one.
        let r2 = try Layout.removePane(r.value, pane: "pa")
        let root2 = r2.value["spaces"][0]["tabs"][0]["root"]
        XCTAssertEqual(root2["children"].array?.count, 1)                 // root never replaced
        XCTAssertEqual(root2["children"][0]["size"], ["weight": 1.0])
        XCTAssertThrowsError(try Layout.removePane(doc, pane: "nope"))
    }

    func testRemoveFromStackMovesActive() throws {
        let root: JSONValue = ["id": "tb1", "type": "row", "children": [
            ["id": "st", "type": "stack", "active": "pa", "children": [
                ["id": "pa", "type": "block", "content": ["terminal": "t1"]],
                ["id": "pb", "type": "block", "content": ["mod": "devhub", "props": ["view": "full"]]],
            ]]]]
        let doc: JSONValue = ["spaces": [["id": "sp1", "tabs": [["id": "tb1", "root": root]]]]]
        let r = try Layout.removePane(doc, pane: "pa")
        XCTAssertEqual(r.value["spaces"][0]["tabs"][0]["root"]["children"][0]["active"], "pb")
        XCTAssertEqual(Layout.spaces(from: r.value)[0].tabs[0].panes.first?.mod, "devhub")
    }

    func testRename() throws {
        let v = try fixture()
        let sp = Layout.spaces(from: v)[1]
        let out = try Layout.renameTab(try Layout.renameSpace(v, space: sp.id, to: "Home"), tab: sp.tabs[1].id, to: "Sec")
        let s = Layout.spaces(from: out)[1]
        XCTAssertEqual(s.name, "Home"); XCTAssertEqual(s.tabs[1].name, "Sec")
        XCTAssertEqual(Layout.locate(terminal: "t3", in: out)?.tab, sp.tabs[1].id)
    }
}

final class NamesTests: XCTestCase {
    func testFolderName() {
        XCTAssertEqual(Names.folderName("", home: "/home/dev"), "~")
        XCTAssertEqual(Names.folderName("/home/dev/", home: "/home/dev"), "~")
        XCTAssertEqual(Names.folderName("/home/dev/projects/webapp", home: "/home/dev"), "webapp")
        XCTAssertEqual(Names.folderName("/", home: "/home/dev"), "/")
        XCTAssertEqual(Names.folderName("/srv/app//", home: "/home/dev"), "app")
    }

    func testShownTitle() {
        XCTAssertEqual(Names.shownTitle("✳ Fix the tests"), "Fix the tests")
        XCTAssertEqual(Names.shownTitle("⠋ Building"), "Building")
        XCTAssertEqual(Names.shownTitle("✓ build"), "✓ build")
        XCTAssertEqual(Names.shownTitle("✳"), "✳")
        XCTAssertEqual(Names.shownTitle("✳Fix"), "✳Fix")
    }

    func testAgentLabelTelling() {
        let claude = Programs.identify(app: "claude-code", argv: [])
        let unnamed = TabRef(id: "tb", name: "", panes: [])
        XCTAssertEqual(Names.agentLabel(title: "✳ Global time slider", program: claude, tab: unnamed, tabIndex: 3), "Global time slider")
        XCTAssertEqual(Names.agentLabel(title: "dev@my-box: ~", program: claude, tab: unnamed, tabIndex: 3), "4")
        XCTAssertEqual(Names.agentLabel(title: "Claude Code", program: claude, tab: unnamed, tabIndex: 0), "1")
        XCTAssertEqual(Names.agentLabel(title: "~/projects", program: claude, tab: unnamed, tabIndex: 0), "1")
        let named = TabRef(id: "tb", name: "Newsletter", panes: [])
        XCTAssertEqual(Names.agentLabel(title: "Newsletter work", program: claude, tab: named, tabIndex: 1), "Newsletter")
        let progNamed = TabRef(id: "tb", name: "Claude Code", panes: [])
        XCTAssertEqual(Names.agentLabel(title: "Fix bug", program: claude, tab: progNamed, tabIndex: 1), "Fix bug")
    }

    func testSpaceAndTabNames() {
        let s = SpaceRef(id: "sp", name: "", folder: "/home/dev/x", tabs: [])
        XCTAssertEqual(Names.spaceName(s, firstTerminalCwd: "/home/dev", home: "/home/dev"), "~")
        XCTAssertEqual(Names.spaceName(s, firstTerminalCwd: nil, home: "/home/dev"), "x")
        XCTAssertEqual(Names.tabName(TabRef(id: "t", name: "", panes: []), index: 4), "5")
    }

    func testPrograms() {
        XCTAssertEqual(Programs.identify(app: "claude-code", argv: []).key, "claude")
        XCTAssertTrue(Programs.identify(app: "claude-code", argv: []).isAgent)
        XCTAssertEqual(Programs.identify(app: "mystery", argv: []).name, "mystery")
        let wrapped = ["sh", "-c", "\"$@\"; exec \"${SHELL:-sh}\" -i", "sh", "codex", "do it"]
        XCTAssertEqual(Programs.identify(app: nil, argv: wrapped).key, "codex")
        XCTAssertEqual(Programs.identify(app: nil, argv: ["/usr/bin/zsh"]).key, "shell")
        XCTAssertEqual(Programs.identify(app: nil, argv: ["-bash"]).name, "bash")
        XCTAssertEqual(Programs.identify(app: nil, argv: []).key, "shell")
        XCTAssertEqual(Programs.identify(app: nil, argv: ["node", "--x", "node_modules/.bin/vite.js", "dev"]).key, "vite")
        XCTAssertEqual(Programs.identify(app: nil, argv: ["python3", "-m", "http.server"]).key, "python")
        XCTAssertEqual(Programs.identify(app: nil, argv: ["btop"]).key, "htop")
        let other = Programs.identify(app: nil, argv: ["frobnicate"])
        XCTAssertEqual(other.key, "program"); XCTAssertEqual(other.name, "frobnicate")
        XCTAssertEqual(other.tile, Programs.identify(app: nil, argv: ["frobnicate"]).tile)
        XCTAssertEqual(Programs.agentKey("claude-code"), "claude")
    }
}

final class AttentionTests: XCTestCase {
    func testSeenStateMachine() {
        var a = AttentionTracker()
        a.setWord("t1", "idle", looking: false)
        XCTAssertEqual(a.display("t1"), .idle)                 // first sighting = seen
        a.setWord("t1", "working", looking: false)
        XCTAssertEqual(a.display("t1"), .working)
        a.setWord("t1", "done", looking: false)
        XCTAssertEqual(a.display("t1"), .done)                 // finished unwatched
        a.markSeen(["t1"])
        XCTAssertEqual(a.display("t1"), .idle)
        a.setWord("t1", "blocked", looking: true)
        XCTAssertEqual(a.display("t1"), .blocked)
        a.setWord("t1", "idle", looking: true)
        XCTAssertEqual(a.display("t1"), .idle)                 // finished while looking
        a.setWord("t1", "error", looking: false)
        XCTAssertEqual(a.display("t1"), .blocked)
        a.setWord("t1", nil, looking: false)
        XCTAssertEqual(a.display("t1"), .none)
        XCTAssertEqual(a.display("t404"), .none)
        a.setWord("t2", "weird-word", looking: false)
        XCTAssertEqual(a.display("t2"), .idle)
    }

    func testAlerts() {
        XCTAssertEqual(AttentionTracker.alert(prev: "working", new: "blocked", looking: true), .blocked)
        XCTAssertEqual(AttentionTracker.alert(prev: "blocked", new: "error", looking: false), nil)
        XCTAssertEqual(AttentionTracker.alert(prev: "working", new: "idle", looking: false), .done)
        XCTAssertEqual(AttentionTracker.alert(prev: "working", new: "idle", looking: true), nil)
        XCTAssertEqual(AttentionTracker.alert(prev: "working", new: nil, looking: false), nil)
        XCTAssertEqual(AttentionTracker.alert(prev: "idle", new: "done", looking: false), nil)
    }

    func testRollupAndRestoreTurnRule() throws {
        XCTAssertEqual(Attention.rollup([.idle, .working, .done]), .done)
        XCTAssertEqual(Attention.rollup([]), .none)
        var saved = AttentionTracker()
        saved.setWord("t6", "done", looking: false, turn: 2)
        saved.setWord("t7", "idle", looking: false, turn: 1)
        saved.setWord("t8", "working", looking: false, turn: 1)
        let data = try JSONEncoder().encode(saved)
        let restoredSaved = try JSONDecoder().decode(AttentionTracker.self, from: data)
        let rec = { (a: String, w: String, turn: Int) in TerminalRecord(raw: ["address": .string(a), "state": "live", "turn": .number(Double(turn)), "status": ["state": .string(w)]]) }
        var now = AttentionTracker()
        now.restore(restoredSaved, current: [rec("t6", "done", 2), rec("t7", "idle", 3), rec("t8", "idle", 2), rec("t9", "idle", 5)])
        XCTAssertEqual(now.display("t6"), .idle)               // seen kept, same word, same turn
        XCTAssertEqual(now.display("t7"), .done)               // turn grew while away
        XCTAssertEqual(now.display("t8"), .done)               // finished while away
        XCTAssertEqual(now.display("t9"), .idle)               // first sighting
    }
}

final class PairingTests: XCTestCase {
    private func code(_ obj: [String: Any]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: obj)
        let b64 = data.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return PairingOffer.prefix + b64
    }
    private let k = Data(repeating: 7, count: 51).base64EncodedString()
    private let s = Data(repeating: 9, count: 32).base64EncodedString()

    func testDecodesWhatPairShPrints() throws {
        let o = try PairingOffer.decode(code(["v": 2, "h": "100.64.0.9", "p": 2222, "u": "me", "k": k, "s": s]) + "\n")
        XCTAssertEqual(o, PairingOffer(host: "100.64.0.9", port: 2222, user: "me", hostKey: "ssh-ed25519 " + k, seed: Data(repeating: 9, count: 32)))
    }

    func testRejectsOtherTextAndIncompleteOffers() {
        XCTAssertThrowsError(try PairingOffer.decode("orca://pair?code=abc"))
        XCTAssertThrowsError(try PairingOffer.decode(PairingOffer.prefix + "!!!"))
        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "h": "h", "u": "u", "k": k, "s": s])))
        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "", "u": "u", "k": k, "s": s])))
        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "h", "u": "u", "k": "AAAA", "s": s])))
        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "h", "p": 0, "u": "u", "k": k, "s": s])))
        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "h", "u": "u", "k": k, "s": "nope"])))
    }
}
