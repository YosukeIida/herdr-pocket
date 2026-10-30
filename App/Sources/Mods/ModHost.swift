import SwiftUI

// CONTRACT (owned by the mod-host builder).
struct ModInfo: Identifiable, Hashable {
    var id: String { name }
    var name: String        // folder name, e.g. "devhub"
    var title: String       // mod.json title
    var block: String? = nil // its block id in the desktop layout, when not its name
}

enum ModCatalog {
    /// Bundled mod files live in the Mods folder reference.
    static func file(_ name: String, _ ext: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Mods")
            ?? Bundle.main.url(forResource: name, withExtension: ext)
    }

    /// Mods bundled into the app (App/Resources/Mods/<name>.js + <name>.json).
    static func all() -> [ModInfo] { cached }

    private static let cached: [ModInfo] = {
        guard let url = ModCatalog.file("_catalog", "json"),
              let data = try? Data(contentsOf: url),
              let list = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else { return [] }
        return list.compactMap { e in
            guard let name = e["name"] as? String, !name.isEmpty,
                  ModCatalog.file(name, "js") != nil else { return nil }
            return ModInfo(name: name, title: (e["title"] as? String) ?? name,
                           block: (e["block"] as? String).flatMap { $0.isEmpty ? nil : $0 })
        }
    }()
}

/// Renders one mod copy. props: nil for the compact (sidebar) copy, or e.g. {"view":"full"}.
struct ModPanelView: View {
    var mod: String
    var props: [String: Any]? = nil
    var body: some View { ModPanelHost(mod: mod, propsJSON: ModKeys.propsJSON(props)) }
}

/// Hosts a copy: links the hub to the store, starts the runtime, renders its
/// tree and presents the sheets it asks for. Keyed by the props' JSON so the
/// view identity is stable across parent re-renders.
private struct ModPanelHost: View {
    let mod: String
    let propsJSON: String

    @Environment(AppStore.self) private var store
    @Environment(\.colorScheme) private var scheme
    @State private var runtime: ModRuntime?

    private var props: [String: Any]? {
        guard propsJSON != "null", let d = propsJSON.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: d)) as? [String: Any]
    }

    var body: some View {
        let hub = ModHub.shared
        Group {
            if let runtime {
                ModRuntimeView(runtime: runtime, compact: props == nil)
                    .sheet(item: hub.sheetBinding(for: runtime.key)) { sheet in
                        ModSheetView(sheet: sheet)
                    }
            } else {
                Color.clear.frame(height: 1)
            }
        }
        .onAppear {
            hub.attach(store)
            hub.setDark(scheme == .dark)
            let r = hub.runtime(mod: mod, props: props)
            runtime = r
            hub.retain(r)
            r.startIfReady()
        }
        .onChange(of: scheme) { _, s in hub.setDark(s == .dark) }
        .onDisappear {
            // Full copies go away with their sheet; compact copies keep running.
            if let r = runtime, r.props != nil { hub.release(r) }
        }
    }
}

/// A full copy presented as a glass sheet. The mod draws its own title bar,
/// so the sheet's navigation bar carries only Done (no second title).
struct ModSheetView: View {
    var mod: String
    var props: [String: Any]?
    @Environment(\.dismiss) private var dismiss

    init(sheet: ModSheet) { mod = sheet.mod; props = sheet.props }
    init(mod: String, props: [String: Any]? = ["view": "full"]) { self.mod = mod; self.props = props }

    var body: some View {
        NavigationStack {
            ModPanelView(mod: mod, props: props)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(HC.background)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark") { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct ModRuntimeView: View {
    let runtime: ModRuntime
    let compact: Bool

    var body: some View {
        switch runtime.phase {
        case .waiting:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text(ModHub.shared.isConnected ? "Starting…" : "Waiting for the machine…")
                    .font(HF.ui(12.5)).foregroundStyle(HC.dim)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        case .failed(let msg):
            VStack(alignment: .leading, spacing: 4) {
                Text("This mod could not start").font(HF.ui(13, .semibold)).foregroundStyle(HC.fg)
                Text(msg).font(HF.ui(11.5)).foregroundStyle(HC.blocked).lineLimit(4)
                Button("Retry") { runtime.restart() }.font(HF.ui(12.5, .medium)).buttonStyle(.glass)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        case .running:
            if let tree = runtime.tree {
                ModNodeView(node: tree, text: .root, ctx: ModRenderContext(runtime: runtime, compact: compact),
                            parentDir: "col", stretch: true)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}

/// Settings for the mods: the Linear API key (read by linear as
/// ~/.config/herdr-secrets/linear-api-key on the desktop) and a reload button.
struct ModSettingsView: View {
    @State private var linearKey = ""
    @State private var saved = false
    @State private var hasKey = ModSecrets.get("linear-api-key") != nil

    var body: some View {
        Section {
            SecureField(hasKey ? "Linear key saved — paste to replace" : "Linear API key (lin_api_…)", text: $linearKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(HF.mono(13))
            HStack {
                Button("Save key") {
                    ModHub.shared.setSecret("linear-api-key", linearKey)
                    hasKey = !linearKey.trimmingCharacters(in: .whitespaces).isEmpty
                    linearKey = ""
                    saved = true
                }
                .disabled(linearKey.trimmingCharacters(in: .whitespaces).isEmpty)
                if hasKey {
                    Spacer()
                    Button("Remove", role: .destructive) {
                        ModHub.shared.setSecret("linear-api-key", nil)
                        hasKey = false
                    }
                }
            }
            Button("Reload mods") { ModHub.shared.reloadAll() }
        } header: {
            Text("Mods")
        } footer: {
            Text(saved ? "Saved in the Keychain on this device." : "Mods run on this phone and read live data from the machine. The Linear key stays in this device's Keychain.")
        }
    }
}
