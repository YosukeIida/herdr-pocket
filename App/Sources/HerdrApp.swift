import SwiftUI

@main
struct HerdrApp: App {
    @State private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .onChange(of: scenePhase) { _, phase in store.scenePhaseChanged(phase) }
        }
    }
}
