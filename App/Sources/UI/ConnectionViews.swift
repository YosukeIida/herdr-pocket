import SwiftUI
import HerdrKit

// MARK: Onboarding

struct OnboardingView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 12) {
                        Image("HerdrMark").resizable().frame(width: 64, height: 64)
                            .clipShape(.rect(cornerRadius: 15))
                        Text("Herdr").font(HF.ui(30, .semibold, relativeTo: .largeTitle)).foregroundStyle(HC.fg)
                        Text("Your agents and terminals, from your pocket.\nConnect to a machine running herdr-core.")
                            .font(HF.ui(15)).foregroundStyle(HC.muted).multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    MachineForm(machine: store.machines.first ?? MachineConfig(), isFirstRun: true)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 40)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(HC.canvas)
        }
    }
}

/// Add / edit a machine. Shows the app's public key with a copyable install line.
struct MachineForm: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var machine: MachineConfig
    var isFirstRun = false
    @State private var password = ""
    @State private var portText = ""
    @State private var copied: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(title: "Machine")
            VStack(spacing: 0) {
                field("Name", text: $machine.label, prompt: "my-box")
                divider
                field("Host", text: $machine.host, prompt: "100.x.y.z or my-box.local", keyboard: .URL)
                divider
                field("Port", text: $portText, prompt: "22", keyboard: .numberPad)
                divider
                field("User", text: $machine.user, prompt: "username")
                divider
                Toggle(isOn: $machine.usePassword.animation(.smooth)) {
                    Text("Use a password").font(HF.ui(15.5)).foregroundStyle(HC.fg)
                }
                .padding(.horizontal, 14).frame(minHeight: HM.rowHeight)
                if machine.usePassword {
                    divider
                    HStack {
                        Text("Password").font(HF.ui(15.5)).foregroundStyle(HC.muted).frame(width: 84, alignment: .leading)
                        SecureField("Stored in the Keychain", text: $password)
                            .font(HF.ui(15.5)).textContentType(.password)
                    }
                    .padding(.horizontal, 14).frame(minHeight: HM.rowHeight)
                }
            }
            .herdrCard()

            if !machine.usePassword { keySection }

            Button(action: connect) {
                Text(isFirstRun ? "Connect" : "Save and connect")
                    .font(HF.ui(16.5, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(machine.host.trimmingCharacters(in: .whitespaces).isEmpty || machine.user.isEmpty)
            .padding(.top, 22)
        }
        .onAppear { portText = String(machine.port) }
    }

    @ViewBuilder private var keySection: some View {
        let key = store.publicKeyLine()
        SectionLabel(title: "This device's key")
        VStack(alignment: .leading, spacing: 12) {
            Text("Add this line to ~/.ssh/authorized_keys on \(machine.label.isEmpty ? "the machine" : machine.label):")
                .font(HF.ui(14)).foregroundStyle(HC.muted)
            Text(key.isEmpty ? "Generating key…" : key)
                .font(HF.mono(11.5))
                .foregroundStyle(HC.fg)
                .textSelection(.enabled)
                .lineLimit(4)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HC.canvas, in: .rect(cornerRadius: 8))
            HStack(spacing: 10) {
                Button {
                    copy(key, as: "key")
                } label: {
                    Label(copied == "key" ? "Copied" : "Copy key", systemImage: copied == "key" ? "checkmark" : "doc.on.doc")
                }
                Button {
                    copy(installLine(key), as: "line")
                } label: {
                    Label(copied == "line" ? "Copied" : "Copy command", systemImage: copied == "line" ? "checkmark" : "terminal")
                }
                Spacer(minLength: 0)
                ShareLink(item: key) { Image(systemName: "square.and.arrow.up") }
            }
            .buttonStyle(.glass)
            .font(HF.ui(14, .medium))
            .disabled(key.isEmpty)
            Text("The command appends the key with the right permissions:")
                .font(HF.ui(12.5)).foregroundStyle(HC.dim)
            Text(installLine(key.isEmpty ? "ssh-ed25519 AAAA… herdr-ios" : key))
                .font(HF.mono(10.5)).foregroundStyle(HC.muted).lineLimit(3).textSelection(.enabled)
        }
        .padding(14)
        .herdrCard()
    }

    private func installLine(_ key: String) -> String {
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '\(key)' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    }

    private func copy(_ s: String, as tag: String) {
        UIPasteboard.general.string = s
        withAnimation { copied = tag }
        Task { try? await Task.sleep(for: .seconds(2)); withAnimation { if copied == tag { copied = nil } } }
    }

    private func connect() {
        var m = machine
        m.host = m.host.trimmingCharacters(in: .whitespaces)
        m.user = m.user.trimmingCharacters(in: .whitespaces)
        if m.label.trimmingCharacters(in: .whitespaces).isEmpty { m.label = m.host }
        m.port = Int(portText) ?? 22
        store.saveMachine(m, password: m.usePassword && !password.isEmpty ? password : nil)
        store.connect(to: m)
        dismiss()
    }

    private var divider: some View {
        Rectangle().fill(HC.border).frame(height: HM.hairline).padding(.leading, 14)
    }

    private func field(_ label: String, text: Binding<String>, prompt: String, keyboard: UIKeyboardType = .default) -> some View {
        HStack {
            Text(label).font(HF.ui(15.5)).foregroundStyle(HC.muted).frame(width: 84, alignment: .leading)
            TextField(prompt, text: text)
                .font(HF.ui(15.5))
                .foregroundStyle(HC.fg)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .frame(minHeight: HM.rowHeight)
    }
}

// MARK: Connecting

struct ConnectingView: View {
    @Environment(AppStore.self) private var store

    private static let steps = ["Opening SSH", "Starting herdr-core", "Subscribing to events", "Reading the layout"]

    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            Image("HerdrMark").resizable().frame(width: 54, height: 54).clipShape(.rect(cornerRadius: 13))
            VStack(spacing: 6) {
                Text("Connecting to \(store.machineTitle)")
                    .font(HF.ui(19, .semibold)).foregroundStyle(HC.fg)
                if let m = store.activeMachine {
                    Text(verbatim: "\(m.user)@\(m.host):\(m.port)").font(HF.mono(12.5)).foregroundStyle(HC.dim)
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(Self.steps.enumerated()), id: \.offset) { i, step in
                    HStack(spacing: 12) {
                        stepMark(i)
                        Text(step).font(HF.ui(15)).foregroundStyle(i <= currentIndex ? HC.fg : HC.dim)
                    }
                }
                if currentIndex < 0, case .connecting(let s) = store.phase {
                    HStack(spacing: 12) { Spinner(color: HC.working, size: 14); Text(s).font(HF.ui(15)).foregroundStyle(HC.fg) }
                }
            }
            .padding(18)
            .frame(maxWidth: 320, alignment: .leading)
            .herdrCard()
            Spacer()
            Button("Cancel") { store.disconnect() }
                .buttonStyle(.glass)
                .font(HF.ui(15, .medium))
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
    }

    private var currentIndex: Int {
        if store.phase == .connected { return Self.steps.count }
        return store.connectStep
    }

    @ViewBuilder private func stepMark(_ i: Int) -> some View {
        if i < currentIndex {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(HC.connected).font(.system(size: 15))
                .frame(width: 16)
        } else if i == currentIndex {
            Spinner(color: HC.working, size: 14).frame(width: 16)
        } else {
            Circle().strokeBorder(HC.idle, lineWidth: 1.5).frame(width: 10, height: 10).frame(width: 16)
        }
    }
}

// MARK: Failure

struct FailureView: View {
    @Environment(AppStore.self) private var store
    @State private var editing = false
    @State private var confirmForget = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "bolt.horizontal.circle")
                    .font(.system(size: 44, weight: .light)).foregroundStyle(HC.blocked)
                    .padding(.top, 60)
                Text(store.phase == .idle ? "Not connected to \(store.machineTitle)" : "Couldn't reach \(store.machineTitle)")
                    .font(HF.ui(20, .semibold)).foregroundStyle(HC.fg)
                    .multilineTextAlignment(.center)
                if case .failed(let msg) = store.phase {
                    Text(msg).font(HF.ui(15)).foregroundStyle(HC.muted).multilineTextAlignment(.center)
                }
                if let m = store.activeMachine {
                    Text(verbatim: "\(m.user)@\(m.host):\(m.port)").font(HF.mono(12.5)).foregroundStyle(HC.dim)
                }
                if !store.diagnostics.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Diagnostics").herdrSectionHeader()
                        ScrollView {
                            Text(store.diagnostics)
                                .font(HF.mono(11.5)).foregroundStyle(HC.muted)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 220)
                    }
                    .padding(14)
                    .herdrCard()
                }
                GlassEffectContainer {
                    HStack(spacing: 12) {
                        Button { editing = true } label: { Label("Edit machine", systemImage: "server.rack") }
                            .buttonStyle(.glass)
                        Button { store.reconnect() } label: {
                            Label(store.phase == .idle ? "Connect" : "Retry", systemImage: "arrow.clockwise").padding(.horizontal, 8)
                        }
                        .buttonStyle(.glassProminent)
                    }
                    .font(HF.ui(15.5, .semibold))
                    .controlSize(.large)
                }
                .padding(.top, 6)
                if store.hostKeyMismatch, let m = store.activeMachine {
                    Button(role: .destructive) { confirmForget = true } label: {
                        Label("Forget host key", systemImage: "key.slash")
                    }
                    .buttonStyle(.glass)
                    .font(HF.ui(15, .medium))
                    .confirmationDialog("Forget \(m.host)'s host key?", isPresented: $confirmForget, titleVisibility: .visible) {
                        Button("Forget and reconnect", role: .destructive) {
                            store.forgetHostKey(m)
                            store.reconnect()
                        }
                    } message: {
                        Text("Pinned: \(store.hostKeyFingerprint(m) ?? "none"). Only do this if \(m.host) was reinstalled; the next key it presents will be trusted.")
                    }
                }
                Text("Check that the host is reachable (e.g. Tailscale is on), the key is in authorized_keys, and herdr-core is installed in ~/.local/bin.")
                    .font(HF.ui(13)).foregroundStyle(HC.dim).multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $editing) {
            NavigationStack {
                ScrollView { MachineForm(machine: store.activeMachine ?? MachineConfig()).padding(18) }
                    .background(HC.canvas)
                    .navigationTitle("Machine")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { editing = false } } }
            }
            .presentationDetents([.large])
        }
    }
}
