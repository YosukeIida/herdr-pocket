import SwiftUI

@main
struct HerdrApp: App {
    @UIApplicationDelegateAdaptor(HerdrAppDelegate.self) private var appDelegate
    @State private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .onChange(of: scenePhase) { _, phase in store.scenePhaseChanged(phase) }
                .onAppear { HerdrAppDelegate.store = store }
                // After a good connection: ask for notifications once, and keep
                // this phone's push token registered on the box.
                .onChange(of: store.phase) { _, phase in
                    guard phase == .connected else { return }
                    Task {
                        await Push.shared.requestIfNeeded()
                        if !AppStore.isDemoMode { await Push.shared.upload(to: store) }
                    }
                }
        }
    }
}
