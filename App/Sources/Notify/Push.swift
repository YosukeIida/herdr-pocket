import SwiftUI
import UserNotifications
import HerdrKit

/// Push notifications. The box sends them (herdr-notify, a small script the
/// app installs there): iOS closes our SSH connection in the background, so
/// only the box can see an agent start waiting. This side asks permission,
/// gets the device token, hands it to the box over the open connection, and
/// opens the agent when a notification is tapped.
@MainActor @Observable
final class Push {
    static let shared = Push()

    private(set) var authorization: UNAuthorizationStatus = .notDetermined
    private(set) var token: String?
    /// Machine id -> token last handed to that box.
    private var uploaded: [String: String] = UserDefaults.standard.dictionary(forKey: "push.uploaded") as? [String: String] ?? [:]

    /// One stable id per install names this phone's file on the box.
    let deviceID: String = {
        if let id = UserDefaults.standard.string(forKey: "push.deviceID") { return id }
        let id = UUID().uuidString.lowercased()
        UserDefaults.standard.set(id, forKey: "push.deviceID")
        return id
    }()

    /// "sandbox" for development-signed builds, else "production" (from the
    /// embedded provisioning profile's aps-environment).
    let environment: String = {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let raw = try? Data(contentsOf: url),
              let start = raw.range(of: Data("<?xml".utf8)), let end = raw.range(of: Data("</plist>".utf8)),
              let plist = try? PropertyListSerialization.propertyList(from: raw[start.lowerBound..<end.upperBound], format: nil) as? [String: Any],
              let ent = plist["Entitlements"] as? [String: Any]
        else { return "sandbox" }   // simulator / no profile
        return (ent["aps-environment"] as? String) == "production" ? "production" : "sandbox"
    }()

    /// The signing team, to prefill the APNs setup.
    let teamID: String? = {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let raw = try? Data(contentsOf: url),
              let start = raw.range(of: Data("<?xml".utf8)), let end = raw.range(of: Data("</plist>".utf8)),
              let plist = try? PropertyListSerialization.propertyList(from: raw[start.lowerBound..<end.upperBound], format: nil) as? [String: Any]
        else { return nil }
        return (plist["TeamIdentifier"] as? [String])?.first
    }()

    func refreshAuthorization() async {
        authorization = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Ask once (after the first good connection), then register for a token.
    func requestIfNeeded() async {
        await refreshAuthorization()
        if authorization == .notDetermined {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorization()
        }
        if authorization == .authorized || authorization == .provisional || authorization == .ephemeral {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func didRegister(_ deviceToken: Data) {
        token = deviceToken.map { String(format: "%02x", $0) }.joined()
    }

    /// Writes this phone's token to the box (~/.config/herdr-ios/devices/<id>.json).
    func upload(to store: AppStore, force: Bool = false) async {
        guard let token, store.phase == .connected, let machine = store.activeMachine else { return }
        let key = machine.id.uuidString
        if !force && uploaded[key] == token { return }
        let body: [String: Any] = ["token": token, "env": environment, "name": UIDevice.current.name,
                                   "bundle": Bundle.main.bundleIdentifier ?? "", "updated": Int(Date().timeIntervalSince1970)]
        guard let json = try? JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted, .sortedKeys]) else { return }
        do {
            let r = try await store.exec(argv: ["sh", "-c", #"mkdir -p "$HOME/.config/herdr-ios/devices" && cat > "$HOME/.config/herdr-ios/devices/$1.json""#, "sh", deviceID],
                                         cwd: nil, on: nil, timeout: 15, input: json)
            if r.code == 0 {
                uploaded[key] = token
                UserDefaults.standard.set(uploaded, forKey: "push.uploaded")
            }
        } catch {}
    }

    func registered(on machine: MachineConfig?) -> Bool {
        guard let machine, let token else { return false }
        return uploaded[machine.id.uuidString] == token
    }
}

/// Registers for pushes and routes taps to the agent they're about.
final class HerdrAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    @MainActor static weak var store: AppStore?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in
            Push.shared.didRegister(deviceToken)
            if let store = Self.store { await Push.shared.upload(to: store) }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("push registration failed: \(error)")
    }

    /// In the app, the store's own toasts already say it: no system banner.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        []
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        guard let t = (info["herdr"] as? [String: Any])?["t"] as? String else { return }
        await MainActor.run { Self.store?.pendingOpen = t }
    }
}
