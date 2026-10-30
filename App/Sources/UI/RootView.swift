import SwiftUI
import HerdrKit

struct RootView: View {
    @Environment(AppStore.self) private var store
    @AppStorage("appearance") private var appearance = "system"

    private enum Stage: Equatable { case onboarding, connecting, failed, main }

    /// Once we have a live picture of the box, keep showing it through
    /// reconnects (a banner says what's happening) instead of a blank screen.
    private var stage: Stage {
        if store.machines.isEmpty && store.terminals.isEmpty { return .onboarding }
        let hadSession = store.hello != nil || !store.terminals.isEmpty
        switch store.phase {
        case .connected: return .main
        case .connecting: return hadSession ? .main : .connecting
        case .failed: return hadSession ? .main : .failed
        // Idle with nothing to show (e.g. Cancel on the connecting screen): the
        // failure screen offers Connect and Edit machine instead of a dead spinner.
        case .idle: return hadSession ? .main : .failed
        }
    }

    var body: some View {
        ZStack {
            HC.canvas.ignoresSafeArea()
            switch stage {
            case .onboarding: OnboardingView()
            case .connecting: ConnectingView()
            case .failed: FailureView()
            case .main: MainView()
            }
        }
        .animation(.smooth(duration: 0.3), value: stage)
        .overlay(alignment: .top) { ToastOverlay() }
        .sensoryFeedback(trigger: blockedCount) { old, new in new > old ? .warning : nil }
        .tint(HC.accent)
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
        .task {
            #if DEBUG
            if AppStore.isDemo { store.loadDemo(); return }
            #endif
            if store.phase == .idle, let m = store.activeMachine { store.connect(to: m) }
        }
    }

    /// Cheap: no names or pane index, just the attention words.
    private var blockedCount: Int {
        store.terminals.values.lazy.filter { $0.isLive && $0.parent == nil && store.attention(of: $0.address) == .blocked }.count
    }
}

// MARK: Toasts

struct ToastOverlay: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            VStack(spacing: 8) {
                ForEach(store.toasts.suffix(3)) { toast in
                    ToastCapsule(toast: toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .task {
                            try? await Task.sleep(for: .seconds(toast.duration ?? (toast.level == "error" ? 6 : 3.5)))
                            withAnimation(.smooth) { store.toasts.removeAll { $0.id == toast.id } }
                        }
                        .onTapGesture {
                            withAnimation(.smooth) { store.toasts.removeAll { $0.id == toast.id } }
                            // An agent alert opens that agent.
                            if let a = toast.address { store.pendingOpen = a }
                        }
                        .accessibilityAddTraits(toast.address != nil ? .isButton : [])
                        .accessibilityHint(toast.address != nil ? "Opens the agent" : "")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .animation(.spring(duration: 0.35), value: store.toasts)
    }
}

private struct ToastCapsule: View {
    var toast: AppStore.Toast

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(tint).font(.system(size: 15, weight: .semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text(toast.title).font(HF.ui(14.5, .semibold)).foregroundStyle(HC.fg).lineLimit(1)
                if let body = toast.body, !body.isEmpty {
                    Text(body).font(HF.ui(12.5)).foregroundStyle(HC.muted).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .frame(maxWidth: 440)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .combine)
    }

    private var icon: String {
        switch toast.level {
        case "error": "exclamationmark.triangle.fill"
        case "warning", "blocked": "hand.raised.fill"
        case "success", "done": "checkmark.circle.fill"
        default: "bell.fill"
        }
    }
    private var tint: Color {
        switch toast.level {
        case "error", "warning", "blocked": HC.blocked
        case "success", "done": HC.done
        default: HC.accent
        }
    }
}
