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
                // Why not a segmented Picker: iOS 26 draws it as a second capsule inside the toolbar's glass.
                ToolbarItem(placement: .topBarTrailing) {
                    let chat = mode == "chat"
                    Button(chat ? "Terminal" : "Chat", systemImage: chat ? "terminal" : "text.bubble") {
                        withAnimation(.smooth(duration: 0.25)) { mode = chat ? "terminal" : "chat" }
                    }
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
