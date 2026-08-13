import SwiftUI
import SwiftData
import AppKit
import ServiceManagement

/// NSApplicationDelegate that sets agent mode AFTER SwiftUI has fully
/// registered the MenuBarExtra.  If we call setActivationPolicy(.accessory)
/// too early (e.g. in applicationDidFinishLaunching), the app becomes
/// invisible before the menu bar icon is created.
final class AppDelegate: NSObject, NSApplicationDelegate {
    var onboardingWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Give SwiftUI a moment to register the MenuBarExtra, then hide the Dock icon.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.setActivationPolicy(.accessory)
        }
        
        let defaults = UserDefaults.standard
        
        // Show setup tour on very first launch
        if !defaults.bool(forKey: "hasCompletedOnboarding") {
            showOnboardingWindow()
        }
        
        // Register for launch-at-login by default on first run
        if !defaults.bool(forKey: "hasSetDefaultLaunchAtLogin") {
            defaults.set(true, forKey: "hasSetDefaultLaunchAtLogin")
            if SMAppService.mainApp.status != .enabled {
                try? SMAppService.mainApp.register()
            }
        }
    }
    
    private func showOnboardingWindow() {
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowRect = NSRect(x: screenRect.midX - 275, y: screenRect.midY - 210, width: 550, height: 420)
        
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.level = .normal
        
        let rootView = OnboardingView { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
        }
        
        window.contentView = NSHostingView(rootView: rootView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        self.onboardingWindow = window
    }
}

@main
struct BlockLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let container: ModelContainer
    @StateObject private var scheduler: BackgroundScheduler

    init() {
        // Initialize SwiftData persistence
        let schema = Schema([TaskModel.self])
        let config = ModelConfiguration("BlockLock", schema: schema)
        do {
            let modelContainer = try ModelContainer(for: schema, configurations: [config])
            self.container = modelContainer
            self._scheduler = StateObject(
                wrappedValue: BackgroundScheduler(container: modelContainer)
            )
        } catch {
            fatalError("[BlockLock] Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        // Menu bar icon + popover
        MenuBarExtra("BlockLock", systemImage: "lock.shield") {
            MenuBarView()
                .environmentObject(scheduler)
                .modelContainer(container)
        }
        .menuBarExtraStyle(.window)

        // Full planner window (opened from menu bar → "Open Full Planner")
        Window("BlockLock Planner", id: "planner") {
            MainPlannerView()
                .environmentObject(scheduler)
        }
        .modelContainer(container)
        .defaultSize(width: 1000, height: 700)
    }
}
