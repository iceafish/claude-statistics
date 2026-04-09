import SwiftUI

@MainActor
final class AppState: ObservableObject {
    let store = SessionDataStore()
    lazy var sessionViewModel = SessionViewModel(store: store)
    let usageViewModel = UsageViewModel()
    let profileViewModel = ProfileViewModel()
    let updaterService = UpdaterService()

    init() {
        store.start()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController!
    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        LanguageManager.setup()
        statusBarController = StatusBarController(appState: appState)
    }
}

@main
struct ClaudeStatisticsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible scene — everything is managed by StatusBarController
        Settings { EmptyView() }
    }
}
