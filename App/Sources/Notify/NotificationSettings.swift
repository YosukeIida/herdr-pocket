import SwiftUI
import UniformTypeIdentifiers
import HerdrKit

/// Settings → Notifications: permission, this phone's registration, and the
/// notifier on the box (install with your APNs key, test, status).
struct NotificationSection: View {
    @Environment(AppStore.self) private var store
    @State private var push = Push.shared
    @State private var notifier: NotifierState = .unknown
    @State private var showSetup = false
    @State private var testing = false

    enum NotifierState: Equatable { case unknown, notInstalled, noKey, stopped, running }

    var body: some View {
        Section {
            row("Permission", value: permissionText, ok: push.authorization == .authorized)
            row("This phone", value: push.registered(on: store.activeMachine) ? "Registered on \(store.machineTitle)" : (push.token == nil ? "No push token yet" : "Not registered"),
                ok: push.registered(on: store.activeMachine))
            row("Notifier on \(store.machineTitle)", value: notifierText, ok: notifier == .running)
            if push.authorization == .denied {
                Button("Allow in iOS Settings") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) { UIApplication.shared.open(url) }
                }
            } else if push.authorization == .notDetermined {
                Button("Allow notifications") { Task { await push.requestIfNeeded(); await push.upload(to: store) } }
            }
            Button(notifier == .running ? "Reinstall on \(store.machineTitle)…" : "Set up on \(store.machineTitle)…") { showSetup = true }
                .disabled(store.phase != .connected)
            if notifier == .running {
                Button { test() } label: {
                    HStack { Text("Send a test notification"); if testing { Spacer(); ProgressView() } }
                }
                .disabled(testing || !push.registered(on: store.activeMachine))
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("\(store.machineTitle) sends the notifications: it pushes to Apple directly when an agent needs you or finishes, so they arrive even when Herdr is closed.")
        }
        .task(id: store.phase) {
            await push.refreshAuthorization()
            if store.phase == .connected { await push.upload(to: store); await refresh() }
        }
        .sheet(isPresented: $showSetup, onDismiss: { Task { await refresh() } }) { NotifierSetup() }
    }

    private var permissionText: String {
        switch push.authorization {
        case .authorized, .provisional, .ephemeral: "Allowed"
        case .denied: "Off"
        default: "Not asked"
        }
    }

    private var notifierText: String {
        switch notifier {
        case .unknown: store.phase == .connected ? "Checking…" : "Not connected"
        case .notInstalled: "Not set up"
        case .noKey: "Needs an APNs key"
        case .stopped: "Installed, not running"
        case .running: "Running"
        }
    }

    private func row(_ title: String, value: String, ok: Bool) -> some View {
        HStack {
            Text(title).font(HF.ui(15.5)).foregroundStyle(HC.fg)
            Spacer()
            Text(value).font(HF.ui(14)).foregroundStyle(ok ? HC.done : HC.muted).multilineTextAlignment(.trailing)
        }
    }

    private func refresh() async {
        guard store.phase == .connected else { notifier = .unknown; return }
        let script = #"d="$HOME/.config/herdr-ios"; [ -f "$d/herdr-notify.py" ] || { echo none; exit 0; }; [ -f "$d/apns.json" ] || { echo nokey; exit 0; }; if systemctl --user is-active --quiet herdr-notify 2>/dev/null || pgrep -f herdr-notify.py >/dev/null; then echo running; else echo stopped; fi"#
        guard let r = try? await store.exec(argv: ["sh", "-c", script], cwd: nil, on: nil, timeout: 10, input: nil) else { return }
        switch String(decoding: r.stdout, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines) {
        case "running": notifier = .running
        case "stopped": notifier = .stopped
        case "nokey": notifier = .noKey
        default: notifier = .notInstalled
        }
    }

    private func test() {
        testing = true
        Task {
            await push.upload(to: store, force: true)
            let r = try? await store.exec(argv: ["sh", "-c", #"python3 "$HOME/.config/herdr-ios/herdr-notify.py" --test"#], cwd: nil, on: nil, timeout: 30, input: nil)
            testing = false
            if r?.code == 0 {
                store.toast("Test sent", body: "It should arrive in a few seconds. Lock the phone to see it as a notification.", level: "success")
            } else {
                let err = r.map { String(decoding: $0.stderr + $0.stdout, as: UTF8.self) } ?? "Not connected"
                store.toast("Test failed", body: String(err.suffix(200)), level: "error")
            }
        }
    }
}

/// Installs herdr-notify on the box with the person's APNs key.
private struct NotifierSetup: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var keyID = ""
    @State private var teamID = Push.shared.teamID ?? ""
    @State private var keyPEM: String?
    @State private var keyName: String?
    @State private var picking = false
    @State private var step: String?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button { picking = true } label: {
                        HStack {
                            Label(keyName ?? "Choose AuthKey_….p8", systemImage: "key")
                            Spacer()
                            if keyPEM != nil { Image(systemName: "checkmark").foregroundStyle(HC.done) }
                        }
                    }
                    TextField("Key ID", text: $keyID)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled()
                        .font(HF.mono(15))
                    TextField("Team ID", text: $teamID)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled()
                        .font(HF.mono(15))
                } header: {
                    Text("APNs key")
                } footer: {
                    Text("Create one at developer.apple.com → Certificates, IDs & Profiles → Keys, with Apple Push Notifications service enabled. It's stored only on \(store.machineTitle) (~/.config/herdr-ios, readable by you alone).")
                }
                Section {
                    Button { install() } label: {
                        HStack {
                            Text("Install on \(store.machineTitle)")
                            if let step { Spacer(); Text(step).foregroundStyle(HC.muted); ProgressView() }
                        }
                    }
                    .disabled(!canInstall)
                    if let error {
                        Label(error, systemImage: "exclamationmark.triangle.fill").foregroundStyle(HC.blocked).font(HF.ui(13.5))
                    }
                } footer: {
                    Text("Copies herdr-notify (a short Python script) to \(store.machineTitle), runs it as a systemd user service, and sends a test notification.")
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { dismiss() } } }
            .fileImporter(isPresented: $picking, allowedContentTypes: [UTType(filenameExtension: "p8") ?? .data, .data]) { result in
                guard case .success(let url) = result else { return }
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                guard let text = try? String(contentsOf: url, encoding: .utf8), text.contains("BEGIN PRIVATE KEY") else {
                    error = "That file isn't an APNs .p8 key."; return
                }
                keyPEM = text; keyName = url.lastPathComponent; error = nil
                // AuthKey_ABCDE12345.p8 names its key id.
                if keyID.isEmpty, let m = url.lastPathComponent.firstMatch(of: /AuthKey_([A-Z0-9]{10})/) { keyID = String(m.1) }
            }
        }
    }

    private var canInstall: Bool {
        step == nil && keyPEM != nil && keyID.count == 10 && teamID.count == 10 && store.phase == .connected
    }

    private func install() {
        guard let keyPEM, let script = Bundle.main.url(forResource: "herdr-notify", withExtension: "py").flatMap({ try? Data(contentsOf: $0) }) else {
            error = "The notifier script is missing from the app."; return
        }
        error = nil
        let apns: [String: Any] = ["key_id": keyID, "team_id": teamID, "bundle_id": Bundle.main.bundleIdentifier ?? "",
                                   "key_path": "~/.config/herdr-ios/AuthKey.p8"]
        let unit = """
        [Unit]
        Description=Herdr for iOS push notifications
        After=network-online.target

        [Service]
        ExecStart=/usr/bin/env python3 %h/.config/herdr-ios/herdr-notify.py
        Restart=always
        RestartSec=5

        [Install]
        WantedBy=default.target

        """
        Task {
            do {
                step = "Key"
                try await put("AuthKey.p8", Data(keyPEM.utf8), mode: "600")
                step = "Config"
                try await put("apns.json", try JSONSerialization.data(withJSONObject: apns, options: [.prettyPrinted, .sortedKeys]), mode: "600")
                step = "Script"
                try await put("herdr-notify.py", script, mode: "755")
                step = "Service"
                try await sh(#"mkdir -p "$HOME/.config/systemd/user" && cat > "$HOME/.config/systemd/user/herdr-notify.service""#, input: Data(unit.utf8))
                try await sh(#"if systemctl --user show-environment >/dev/null 2>&1; then systemctl --user daemon-reload && systemctl --user enable herdr-notify >/dev/null 2>&1; systemctl --user restart herdr-notify; else pkill -f herdr-notify.py; nohup python3 "$HOME/.config/herdr-ios/herdr-notify.py" >"$HOME/.config/herdr-ios/notify.log" 2>&1 & fi"#)
                step = "Test"
                await Push.shared.upload(to: store, force: true)
                try await sh(#"python3 "$HOME/.config/herdr-ios/herdr-notify.py" --test"#)
                step = nil
                store.toast("Notifications are on", body: "A test notification is on its way.", level: "success")
                dismiss()
            } catch {
                self.error = "\(step ?? "Install") failed: \(error.localizedDescription)"
                step = nil
            }
        }
    }

    private func put(_ name: String, _ data: Data, mode: String) async throws {
        try await sh(#"d="$HOME/.config/herdr-ios"; mkdir -p "$d" && chmod 700 "$d" && cat > "$d/$1" && chmod "$2" "$d/$1""#, args: [name, mode], input: data)
    }

    private func sh(_ script: String, args: [String] = [], input: Data? = nil) async throws {
        let r = try await store.exec(argv: ["sh", "-c", script, "sh"] + args, cwd: nil, on: nil, timeout: 30, input: input)
        guard r.code == 0 else {
            let msg = String(decoding: r.stderr + r.stdout, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            throw HerdrError(message: msg.isEmpty ? "exit \(r.code.map(String.init) ?? "signal")" : String(msg.suffix(300)))
        }
    }
}
