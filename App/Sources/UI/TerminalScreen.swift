import SwiftUI
import HerdrKit

/// Full-screen terminal. The SwiftTerm view sits in `TerminalHost` and is never
/// rebuilt by store changes: everything that reads the store lives in small
/// sibling views (title, banners, observers, key bar).
struct TerminalScreen: View {
    let address: String
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var controller: TerminalController

    init(address: String) {
        self.address = address
        let size = UserDefaults.standard.object(forKey: "terminalFontSize") as? Double ?? 13
        _controller = State(initialValue: TerminalController(address: address, fontSize: CGFloat(size)))
    }

    var body: some View {
        TerminalHost(controller: controller)
            .background(Color(uiColor: .herdr("background")))
            .ignoresSafeArea(.container, edges: .horizontal)
            .overlay(alignment: .top) { TerminalBanner(controller: controller) }
            .safeAreaInset(edge: .bottom, spacing: 0) { TerminalBottomBar(controller: controller, address: address) }
            .background { TerminalObservers(controller: controller, address: address) }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { TerminalTitle(address: address) }
                ToolbarItem(placement: .topBarTrailing) { TerminalMenu(controller: controller, address: address) }
            }
            .onAppear {
                controller.appear(store: store)
                store.visibleTerminal = address
                store.markSeen(address)
            }
            .onDisappear {
                controller.disappear()
                if store.visibleTerminal == address { store.visibleTerminal = nil }
            }
            .onChange(of: scenePhase) { _, p in
                controller.setSceneActive(p == .active)
                if p == .active { store.markSeen(address) }
            }
    }
}

/// Invisible: forwards store changes for this one terminal to the controller.
private struct TerminalObservers: View {
    let controller: TerminalController
    let address: String
    @Environment(AppStore.self) private var store

    var body: some View {
        let rec = store.terminals[address]
        let connected = store.phase == .connected
        Color.clear
            .onChange(of: connected) { _, c in controller.storeChanged(connected: c, record: store.terminals[address]) }
            .onChange(of: rec?.isLive) { _, _ in controller.storeChanged(connected: connected, record: rec) }
            .onChange(of: rec?.raw["pid"]) { _, _ in controller.storeChanged(connected: connected, record: rec) }
            .onChange(of: SizeKey(cols: rec?.cols ?? 0, rows: rec?.rows ?? 0)) { _, s in
                controller.recordSizeChanged(cols: s.cols, rows: s.rows)
            }
            .onChange(of: rec?.statusWord) { _, _ in store.markSeen(address) }
    }
    private struct SizeKey: Equatable { var cols: Int; var rows: Int }
}

// MARK: Title

struct TerminalTitle: View {
    @Environment(AppStore.self) private var store
    let address: String

    var body: some View {
        let att = store.attention(of: address)
        let rec = store.terminals[address]
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                ProgramIcon(program: store.programKey(of: address), size: 16)
                Text(store.displayName(of: address))
                    .font(HF.ui(15.5, .semibold))
                    .foregroundStyle(HC.fg)
                    .lineLimit(1)
                StatusMark(attention: att, compact: true)
            }
            if let rec {
                Text("\(store.tildePath(rec.cwd)) · \(address)")
                    .font(HF.ui(11.5)).foregroundStyle(HC.dim).lineLimit(1)
            }
        }
        .frame(maxWidth: 260)
        .accessibilityElement(children: .combine)
    }
}

// MARK: Menu

private struct TerminalMenu: View {
    let controller: TerminalController
    let address: String
    @Environment(AppStore.self) private var store
    @State private var confirmKill = false
    @State private var showFiles = false
    @State private var showChanges = false

    var body: some View {
        Menu {
            Button("Files", systemImage: "folder") { showFiles = true }
            Button("Changes", systemImage: "plusminus") { showChanges = true }
            Divider()
            Toggle(isOn: Binding(get: { controller.fitToPhone }, set: { controller.setFitToPhone($0) })) {
                Label("Fit to phone", systemImage: "iphone")
            }
            Button("Reset zoom", systemImage: "arrow.up.left.and.down.right.magnifyingglass") { controller.viewport.resetZoom() }
            Divider()
            Button("Interrupt", systemImage: "stop.circle") { interrupt() }
            Button("Reload screen", systemImage: "arrow.clockwise") { controller.retry() }
            Button("Copy address", systemImage: "doc.on.doc") { UIPasteboard.general.string = address }
            Divider()
            Button("Kill terminal", systemImage: "xmark.octagon", role: .destructive) { confirmKill = true }
        } label: {
            Image(systemName: "ellipsis")
        }
        .confirmationDialog("Kill \(store.displayName(of: address))?", isPresented: $confirmKill, titleVisibility: .visible) {
            Button("Kill", role: .destructive) {
                Task {
                    do { try await store.kill(address) } catch { store.toast("Couldn't kill", body: error.localizedDescription, level: "error") }
                }
            }
        } message: {
            Text("The program stops on \(store.machineTitle).")
        }
        .sheet(isPresented: $showFiles) { FilesSheet(folder: store.terminals[address]?.cwd ?? "") }
        .sheet(isPresented: $showChanges) { ChangesSheet(folder: store.terminals[address]?.cwd ?? "") }
    }

    private func interrupt() {
        Task {
            do { try await store.interrupt(address) } catch { controller.send([0x03]) }
        }
    }
}

// MARK: Banner

private struct TerminalBanner: View {
    let controller: TerminalController
    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            switch controller.phase {
            case .live:
                EmptyView()
            case .attaching:
                capsule { Spinner(color: HC.working, size: 13); Text("Attaching…") }
            case .restarting:
                capsule { Spinner(color: HC.working, size: 13); Text("Restarting…") }
            case .lost:
                capsule {
                    Spinner(color: HC.working, size: 13)
                    Text(store.phase == .connected ? "Reattaching…" : "Reconnecting to \(store.machineTitle)…")
                }
            case .ended(let reason):
                capsule {
                    Image(systemName: "stop.circle").foregroundStyle(HC.idle)
                    Text("Ended · \(reason)")
                    Button("Output") { controller.showHistory() }.buttonStyle(.glass).controlSize(.small)
                }
            case .failed(let msg):
                capsule {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(HC.blocked)
                    Text(msg).lineLimit(2)
                    Button("Retry") { controller.retry() }.buttonStyle(.glass).controlSize(.small)
                }
            }
        }
        .animation(.smooth, value: controller.phase)
    }

    private func capsule<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        HStack(spacing: 9) { c() }
            .font(HF.ui(14, .medium))
            .foregroundStyle(HC.fg)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .glassEffect(.regular, in: .capsule)
            .padding(.top, 8)
            .padding(.horizontal, 16)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: Bottom bar (key bar / quick actions / compose)

private struct TerminalBottomBar: View {
    let controller: TerminalController
    let address: String
    @Environment(AppStore.self) private var store
    @State private var composing = false
    @State private var draft = ""
    @State private var sending = false
    @State private var confirmInterrupt = false
    @FocusState private var composeFocused: Bool

    var body: some View {
        let rec = store.terminals[address]
        let isAgent = rec?.statusWord != nil || (ProgramCatalog.info(store.programKey(of: address))?.isAgent ?? false)
        let attention = store.attention(of: address)
        let blocked = attention == .blocked
        GlassEffectContainer(spacing: 8) {
            Group {
                if composing {
                    composeBar(isAgent: isAgent)
                } else if controller.keyboardVisible {
                    KeyBar(controller: controller)
                } else {
                    actions(isAgent: isAgent, blocked: blocked, working: attention == .working)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
        }
        // Fixed 44-pt controls: past this size the bar would push the terminal off-screen.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .confirmationDialog("Interrupt \(store.displayName(of: address))?", isPresented: $confirmInterrupt, titleVisibility: .visible) {
            Button("Interrupt", role: .destructive) { interrupt() }
        } message: {
            Text("Stops the agent's current turn.")
        }
        .animation(.smooth(duration: 0.25), value: composing)
        .animation(.smooth(duration: 0.25), value: controller.keyboardVisible)
    }

    // Keyboard hidden: big friendly actions. Interrupt sits on the far left,
    // away from Enter, and asks first (it's also in the … menu).
    private func actions(isAgent: Bool, blocked: Bool, working: Bool) -> some View {
        HStack(spacing: 8) {
            glassIcon("keyboard", label: "Show keyboard") { controller.showKeyboard() }
            if working {
                glassIcon("stop.fill", label: "Interrupt", tint: HC.blocked) { confirmInterrupt = true }
            }
            if isAgent {
                Button {
                    composing = true
                    composeFocused = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "text.bubble")
                        Text(blocked ? "Reply" : "Send prompt").lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .font(HF.ui(15, .medium))
                    .foregroundStyle(HC.muted)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .contentShape(.capsule)
                .glassEffect(.regular.interactive(), in: .capsule)
            } else {
                Spacer(minLength: 0)
            }
            if blocked {
                ForEach(quickReplies, id: \.key) { r in
                    glassText(r.key, label: r.label) { controller.send(r.key) }
                }
            }
            glassText("esc", label: "Escape") { controller.send([0x1b]) }
            glassIcon("return", label: "Enter") { controller.send([0x0d]) }
        }
    }

    /// Permission prompts: Claude Code and Codex show numbered menus
    /// ("1. Yes / 2. Yes, and don't ask again / 3. No (esc)"); others take y/n.
    private var quickReplies: [(key: String, label: String)] {
        switch store.programKey(of: address) {
        case "claude", "codex": [("1", "Option 1, yes"), ("2", "Option 2")]
        default: [("y", "Yes"), ("n", "No")]
        }
    }

    private func interrupt() {
        Task { do { try await store.interrupt(address) } catch { controller.send([0x03]) } }
    }

    private func composeBar(isAgent: Bool) -> some View {
        HStack(spacing: 8) {
            glassIcon("xmark", label: "Close") { composing = false; composeFocused = false }
            TextField(isAgent ? "Message \(store.displayName(of: address))" : "Command", text: $draft, axis: .vertical)
                .font(HF.ui(15.5))
                .lineLimit(1...5)
                .focused($composeFocused)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.send)
                .onSubmit(submit)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .rect(cornerRadius: 22))
            Button(action: submit) {
                Image(systemName: "arrow.up").font(.system(size: 17, weight: .bold)).frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(HC.accentFg)
            .contentShape(.circle)
            .glassEffect(.regular.tint(HC.accent).interactive(), in: .circle)
            .disabled(sending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send")
        }
    }

    /// Keeps the draft until the text is delivered; on failure it stays in the
    /// field and a toast says so (the phone may be reconnecting).
    private func submit() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !sending else { return }
        let isAgent = store.terminals[address]?.statusWord != nil
        sending = true
        Task {
            var sent = false
            if isAgent, (try? await store.send(address, text: text)) != nil { sent = true }
            if !sent, controller.phase == .live {
                controller.send(text); controller.send([0x0d]); sent = true
            }
            sending = false
            if sent {
                if draft.trimmingCharacters(in: .whitespacesAndNewlines) == text { draft = "" }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                store.toast("Not sent", body: "Not connected to \(store.machineTitle). Your text is still in the box.", level: "error")
            }
        }
    }

    private func glassIcon(_ symbol: String, label: String, tint: Color? = nil, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 16, weight: .semibold)).frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(tint ?? HC.fg)
        .contentShape(.circle)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }

    private func glassText(_ t: String, label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(t).font(HF.mono(14, .semibold)).frame(minWidth: 44, minHeight: 44).padding(.horizontal, 2)
        }
        .buttonStyle(.plain)
        .foregroundStyle(HC.fg)
        .contentShape(.capsule)
        .glassEffect(.regular.interactive(), in: .capsule)
        .accessibilityLabel(label)
    }
}

/// Glass key row above the software keyboard.
struct KeyBar: View {
    let controller: TerminalController

    var body: some View {
        HStack(spacing: 6) {
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    key("esc", label: "Escape") { controller.send([0x1b]) }
                    key("tab", label: "Tab") { controller.send([0x09]) }
                    toggle("ctrl", on: controller.ctrlLatched) { controller.ctrlLatched.toggle() }
                    toggle("alt", on: controller.altLatched) { controller.altLatched.toggle() }
                    symbol("arrow.left", label: "Left") { controller.arrow("D") }
                    symbol("arrow.up", label: "Up") { controller.arrow("A") }
                    symbol("arrow.down", label: "Down") { controller.arrow("B") }
                    symbol("arrow.right", label: "Right") { controller.arrow("C") }
                    key("^C", label: "Control C") { controller.send([0x03]) }
                    key("|", label: "Pipe") { controller.send("|") }
                    key("~", label: "Tilde") { controller.send("~") }
                    key("/", label: "Slash") { controller.send("/") }
                    key("-", label: "Dash") { controller.send("-") }
                    symbol("doc.on.clipboard", label: "Paste") { controller.paste() }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            symbol("keyboard.chevron.compact.down", label: "Hide keyboard") { controller.hideKeyboard() }
        }
    }

    private func key(_ t: String, label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(t).font(HF.mono(14, .medium)).frame(minWidth: 40, minHeight: 38).padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
        .foregroundStyle(HC.fg)
        .contentShape(.rect(cornerRadius: 10))
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 10))
        .accessibilityLabel(label)
    }

    private func toggle(_ t: String, on: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(t).font(HF.mono(14, on ? .bold : .medium)).frame(minWidth: 44, minHeight: 38).padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
        .foregroundStyle(on ? HC.accentFg : HC.fg)
        .contentShape(.rect(cornerRadius: 10))
        .glassEffect(on ? .regular.tint(HC.accent).interactive() : .regular.interactive(), in: .rect(cornerRadius: 10))
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func symbol(_ s: String, label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: s).font(.system(size: 14, weight: .semibold)).frame(minWidth: 40, minHeight: 38)
        }
        .buttonStyle(.plain)
        .foregroundStyle(HC.fg)
        .contentShape(.rect(cornerRadius: 10))
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 10))
        .accessibilityLabel(label)
    }
}
