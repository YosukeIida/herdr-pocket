import SwiftUI
import UIKit
import HerdrKit

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("terminalFontSize") private var fontSize = 13.0
    @State private var editing: MachineConfig?
    @State private var confirmForget: MachineConfig?

    var body: some View {
        NavigationStack {
            Form {
                Section("Machines") {
                    ForEach(store.machines) { m in
                        HStack(spacing: 12) {
                            Image(systemName: "server.rack").foregroundStyle(HC.muted).frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(m.label).font(HF.ui(15.5, .medium)).foregroundStyle(HC.fg)
                                Text(verbatim: "\(m.user)@\(m.host):\(m.port)").font(HF.mono(11.5)).foregroundStyle(HC.dim)
                            }
                            Spacer()
                            if m.id == store.activeMachine?.id { ConnectionDot(phase: store.phase) }
                        }
                        .contentShape(.rect)
                        .onTapGesture { editing = m }
                        .swipeActions {
                            Button("Remove", role: .destructive) { store.removeMachine(m.id) }
                            if m.id != store.activeMachine?.id || store.phase != .connected {
                                Button("Connect") { store.connect(to: m) }.tint(HC.accent)
                            }
                        }
                    }
                    Button { editing = MachineConfig(label: "", host: "", user: "") } label: {
                        Label("Add machine", systemImage: "plus")
                    }
                    if store.phase == .connected {
                        Button("Disconnect", role: .destructive) { store.disconnect() }
                    } else if store.activeMachine != nil {
                        Button("Reconnect") { store.reconnect() }
                    }
                    if let m = store.activeMachine, let fp = store.hostKeyFingerprint(m) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Host key").font(HF.ui(13, .medium)).foregroundStyle(HC.muted)
                            Text(fp).font(HF.mono(11)).foregroundStyle(HC.fg).textSelection(.enabled).lineLimit(2)
                        }
                        Button("Forget host key", role: .destructive) { confirmForget = m }
                    }
                }
                .confirmationDialog("Forget the host key?", isPresented: Binding(get: { confirmForget != nil }, set: { if !$0 { confirmForget = nil } }),
                                    titleVisibility: .visible, presenting: confirmForget) { m in
                    Button("Forget", role: .destructive) { store.forgetHostKey(m); if store.phase != .connected { store.reconnect() } }
                } message: { m in
                    Text("Only after \(m.host) was reinstalled. The next key it presents will be trusted and pinned.")
                }

                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Graphite (dark)").tag("dark")
                        Text("Paper (light)").tag("light")
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Stepper(value: $fontSize, in: 9...20, step: 1) {
                            HStack {
                                Text("Terminal text")
                                Spacer()
                                Text("\(Int(fontSize)) pt").foregroundStyle(HC.muted).monospacedDigit()
                            }
                        }
                        Text("The quick brown fox → 0123 {}[]")
                            .font(HF.mono(fontSize))
                            .foregroundStyle(HC.fg)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    Text("Terminals mirror the desktop's size and scale down to fit (min 7 pt). Pinch to zoom; use Fit to phone in a terminal's menu to resize the program instead.")
                        .font(HF.ui(12.5)).foregroundStyle(HC.dim)
                }

                ModSettingsView()

                Section("About") {
                    LabeledContent("Herdr for iOS", value: appVersion)
                    if let h = store.hello {
                        LabeledContent("Core", value: h.coreName)
                        LabeledContent("herdr-core", value: h.version)
                        LabeledContent("Core id", value: String(h.coreID.prefix(12)))
                    } else {
                        LabeledContent("Core", value: "Not connected")
                    }
                    NavigationLink("Licenses") { LicensesView() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HC.canvas)
            .font(HF.ui(15.5))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done", systemImage: "checkmark") { dismiss() } }
            }
            .sheet(item: $editing) { m in
                NavigationStack {
                    ScrollView { MachineForm(machine: m).padding(16) }
                        .background(HC.canvas)
                        .navigationTitle(m.host.isEmpty ? "Add machine" : m.label)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { editing = nil } } }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}

struct LicensesView: View {
    private struct Entry: Identifiable { var id: String { title }; var title: String; var text: String }

    private var entries: [Entry] {
        func file(_ name: String, _ ext: String) -> String? {
            Bundle.main.url(forResource: name, withExtension: ext).flatMap { try? String(contentsOf: $0, encoding: .utf8) }
        }
        func asset(_ name: String) -> String? {
            NSDataAsset(name: name).flatMap { String(data: $0.data, encoding: .utf8) }
        }
        return [
            file("OFL", "txt").map { Entry(title: "Geist (SIL OFL 1.1)", text: $0) },
            file("OFL-JetBrainsMono", "txt").map { Entry(title: "JetBrains Mono (SIL OFL 1.1)", text: $0) },
            file("LICENSE-SymbolsNerdFont", "txt").map { Entry(title: "Symbols Nerd Font (MIT)", text: $0) },
            asset("License-Lucide").map { Entry(title: "Lucide icons (ISC)", text: $0) },
            asset("License-LobeHub").map { Entry(title: "LobeHub icons (MIT)", text: $0) },
            Entry(title: "Brand marks", text: "Brand icons from Simple Icons (CC0 1.0). Agent and brand marks are trademarks of their owners."),
            Entry(title: "SwiftTerm (MIT)", text: "SwiftTerm by Miguel de Icaza. https://github.com/migueldeicaza/SwiftTerm"),
            Entry(title: "Citadel (MIT)", text: "Citadel by Orlandos. https://github.com/orlandos-nl/Citadel"),
        ].compactMap { $0 }
    }

    var body: some View {
        List(entries) { e in
            NavigationLink(e.title) {
                ScrollView {
                    Text(e.text).font(HF.mono(11.5)).foregroundStyle(HC.muted).textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                }
                .background(HC.canvas)
                .navigationTitle(e.title)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .scrollContentBackground(.hidden)
        .background(HC.canvas)
        .navigationTitle("Licenses")
    }
}
