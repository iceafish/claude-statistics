import SwiftUI

@MainActor
final class AppState: ObservableObject {
    let store = SessionDataStore()
    lazy var sessionViewModel = SessionViewModel(store: store)
    let usageViewModel = UsageViewModel()
    let profileViewModel = ProfileViewModel()
    let updaterService = UpdaterService()
    let notificationService = UsageResetNotificationService.shared
    let zaiUsageViewModel = ZaiUsageViewModel()
    let openAIUsageViewModel = OpenAIUsageViewModel()

    init() {
        store.start()
        notificationService.configure()
        zaiUsageViewModel.setup()
        openAIUsageViewModel.setup()
    }

    func setupZai() {
        zaiUsageViewModel.setup()
    }

    func setupOpenAI() {
        openAIUsageViewModel.setup()
    }
}

struct MenuBarLabel: View {
    @ObservedObject var usageViewModel: UsageViewModel
    @ObservedObject var zaiUsageViewModel: ZaiUsageViewModel
    @ObservedObject var openAIUsageViewModel: OpenAIUsageViewModel
    @AppStorage("zaiUsageEnabled") private var zaiUsageEnabled = false
    @AppStorage("openAIUsageEnabled") private var openAIUsageEnabled = false

    var body: some View {
        if menuBarItems.isEmpty {
            Text("--")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .fixedSize()
        } else {
            // MenuBarExtra labels reliably render a single Text view; nested stacks
            // can collapse down to only the first segment in the status bar.
            menuBarDisplayText
                .lineLimit(1)
                .fixedSize()
        }
    }

    private var menuBarItems: [MenuBarUsageItem] {
        MenuBarUsageSelection.items(
            claudeFiveHourPercent: usageViewModel.menuBarFiveHourPercent,
            zaiFiveHourPercent: zaiUsageViewModel.fiveHourPercent,
            openAIFiveHourPercent: openAIUsageViewModel.currentWindowPercent,
            zaiEnabled: zaiUsageEnabled,
            openAIEnabled: openAIUsageEnabled
        )
    }

    private func color(for role: MenuBarUsageColorRole) -> Color {
        switch role {
        case .green:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }

    private var menuBarDisplayText: Text {
        menuBarItems.enumerated().reduce(Text("")) { partial, entry in
            let (index, item) = entry
            let spacing = index == 0 ? Text("") : Text(" ")
            return partial
                + spacing
                + Text(item.providerLabel)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                + Text(" ")
                + Text(item.percentText)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(color(for: item.colorRole))
        }
    }
}

@main
struct ClaudeStatisticsApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("appLanguage") private var appLanguage = "auto"

    private var currentLocale: Locale {
        switch appLanguage {
        case "en": Locale(identifier: "en")
        case "zh-Hans": Locale(identifier: "zh-Hans")
        default: Locale.current
        }
    }

    init() {
        LanguageManager.setup()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                usageViewModel: appState.usageViewModel,
                profileViewModel: appState.profileViewModel,
                sessionViewModel: appState.sessionViewModel,
                store: appState.store,
                updaterService: appState.updaterService,
                notificationService: appState.notificationService,
                zaiUsageViewModel: appState.zaiUsageViewModel,
                openAIUsageViewModel: appState.openAIUsageViewModel
            )
            .environment(\.locale, currentLocale)
            .onAppear {
                appState.setupZai()
                appState.setupOpenAI()
            }
        } label: {
            MenuBarLabel(
                usageViewModel: appState.usageViewModel,
                zaiUsageViewModel: appState.zaiUsageViewModel,
                openAIUsageViewModel: appState.openAIUsageViewModel
            )
        }
        .menuBarExtraStyle(.window)
    }
}
