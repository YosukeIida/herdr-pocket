import SwiftUI
import HerdrKit

/// An agent's page: its conversation (Chat) or its live terminal. Chat is
/// offered for Claude Code and Codex, whose transcripts the box can read; the choice is
/// app-wide and remembered.
struct AgentScreen: View {
    let address: String
    @Environment(AppStore.self) private var store
    @AppStorage("agentViewMode") private var mode = "chat"

    var body: some View {
        let canChat = ["claude", "codex"].contains(store.programKey(of: address))
        Group {
            if canChat && mode == "chat" {
                ChatScreen(address: address)
            } else {
                TerminalScreen(address: address)
            }
        }
        .toolbar {
            if canChat {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("View", selection: $mode.animation(.smooth(duration: 0.25))) {
                        Image(systemName: "text.bubble").tag("chat").accessibilityLabel("Chat")
                        Image(systemName: "terminal").tag("terminal").accessibilityLabel("Terminal")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 92)
                }
            }
        }
    }
}

private struct ChatScreen: View {
    let address: String
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ChatView(address: address)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { TerminalTitle(address: address) } }
            .onAppear {
                store.visibleTerminal = address
                store.markSeen(address)
            }
            .onDisappear { if store.visibleTerminal == address { store.visibleTerminal = nil } }
            .onChange(of: store.terminals[address]?.statusWord) { _, _ in store.markSeen(address) }
            .onChange(of: scenePhase) { _, p in if p == .active { store.markSeen(address) } }
    }
}
