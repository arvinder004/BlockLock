import Cocoa
import SwiftUI
import SwiftData
import AVFoundation

/// Manages all overlay panels: soft-lock, micro-reminder (all displays), and floating widget.
/// Singleton — accessed via `OverlayWindowManager.shared`.
final class OverlayWindowManager {
    static let shared = OverlayWindowManager()

    // MARK: - Panel Storage

    private var softLockPanel: NSPanel?
    private var microReminderPanels: [NSPanel] = []
    private var dailySummaryPanels: [NSPanel] = []
    private var floatingWidgetPanel: NSPanel?
    private var escapeMonitor: Any?

    /// Audio player for alert sounds
    private var alertPlayer: NSSound?

    /// Whether the full soft-lock overlay is currently displayed.
    var isShowingSoftLock: Bool { softLockPanel != nil }

    /// Whether the floating widget is currently visible.
    var isShowingWidget: Bool { floatingWidgetPanel != nil }

    /// Whether the daily summary is currently visible.
    var isShowingDailySummary: Bool { !dailySummaryPanels.isEmpty }

    private init() {}

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Soft Lock (Full-Screen Overlay)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func triggerSoftLock(for task: TaskModel?, container: ModelContainer) {
        DispatchQueue.main.async { [weak self] in
            self?.showSoftLockPanel(for: task, container: container)
        }
    }

    private func showSoftLockPanel(for task: TaskModel?, container: ModelContainer) {
        guard softLockPanel == nil else { return }

        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        let panel = NSPanel(
            contentRect: screenRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = NSColor.black.withAlphaComponent(0.85)
        panel.isOpaque = false
        panel.ignoresMouseEvents = false
        panel.hidesOnDeactivate = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovable = false

        let rootView = SoftLockOverlayView(task: task)
            .modelContainer(container)
        let hosting = NSHostingView(rootView: rootView)
        panel.contentView = hosting
        panel.makeKeyAndOrderFront(nil)

        self.softLockPanel = panel

        #if DEBUG
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.dismissSoftLock()
                return nil
            }
            return event
        }
        #endif
    }

    func dismissSoftLock() {
        DispatchQueue.main.async { [weak self] in
            self?.softLockPanel?.orderOut(nil)
            self?.softLockPanel = nil

            #if DEBUG
            if let monitor = self?.escapeMonitor {
                NSEvent.removeMonitor(monitor)
                self?.escapeMonitor = nil
            }
            #endif
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Micro Reminder (Centered, All Displays, With Sound)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func triggerMicroReminder(for task: TaskModel, container: ModelContainer) {
        DispatchQueue.main.async { [weak self] in
            self?.showMicroReminderOnAllScreens(for: task, container: container)
        }
    }

    private func showMicroReminderOnAllScreens(for task: TaskModel, container: ModelContainer) {
        guard microReminderPanels.isEmpty else { return }

        // 🔔 Play the task's chosen alarm sound on loop until dismissed
        playAlertSound(named: task.reminderSound)

        // Create a centered reminder panel on EVERY connected display
        for screen in NSScreen.screens {
            let panel = createMicroReminderPanel(on: screen, for: task, container: container)
            microReminderPanels.append(panel)
        }

        // No auto-dismiss — the reminder stays until the user takes action
    }

    private func createMicroReminderPanel(
        on screen: NSScreen,
        for task: TaskModel,
        container: ModelContainer
    ) -> NSPanel {
        // Full-screen panel so the semi-transparent backdrop covers everything
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.hidesOnDeactivate = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovable = false

        let reminderView = MicroReminderView(
            task: task,
            onDismiss: { [weak self] in
                self?.dismissMicroReminder()
            },
            onPauseReminders: { [weak self] in
                DispatchQueue.main.async {
                    task.enableMicroReminders = false
                    try? container.mainContext.save()
                }
                self?.dismissMicroReminder()
            }
        )

        let hosting = NSHostingView(rootView: reminderView)
        panel.contentView = hosting
        panel.makeKeyAndOrderFront(nil)

        return panel
    }

    func dismissMicroReminder() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Stop the looping alarm sound immediately
            self.alertPlayer?.stop()
            self.alertPlayer = nil

            for panel in self.microReminderPanels {
                panel.orderOut(nil)
            }
            self.microReminderPanels.removeAll()
        }
    }

    // MARK: Alert Sound

    /// Loads an NSSound by attempting standard Mac sounds first, then iOS ringtones.
    static func loadSound(named soundName: String) -> NSSound? {
        if let sound = NSSound(named: NSSound.Name(soundName)) {
            return sound
        }
        
        // Check iOS Ringtones folder (macOS 11+)
        let ringtonePath = "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/\(soundName).m4r"
        if FileManager.default.fileExists(atPath: ringtonePath) {
            return NSSound(contentsOfFile: ringtonePath, byReference: true)
        }
        
        return nil
    }

    /// Plays a system sound in a continuous loop (like an alarm).
    /// The sound keeps playing until `dismissMicroReminder()` is called.
    private func playAlertSound(named soundName: String = "Glass") {
        // Stop any existing sound first
        alertPlayer?.stop()

        if let sound = Self.loadSound(named: soundName) {
            sound.loops = true   // 🔁 Loop continuously like an alarm
            sound.play()
            self.alertPlayer = sound
        } else {
            // Fallback: system beep (doesn't loop, but at least audible)
            NSSound.beep()
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Floating Widget (Always-On-Top Task List)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func showFloatingWidget(container: ModelContainer) {
        DispatchQueue.main.async { [weak self] in
            self?.createFloatingWidgetPanel(container: container)
        }
    }

    private func createFloatingWidgetPanel(container: ModelContainer) {
        guard floatingWidgetPanel == nil else {
            // Already showing — bring to front
            floatingWidgetPanel?.makeKeyAndOrderFront(nil)
            return
        }

        let width: CGFloat = 290
        let height: CGFloat = 380
        let screenRect = NSScreen.main?.frame ?? .zero
        // Default position: bottom-right corner of the screen
        let x = screenRect.maxX - width - 24
        let y = screenRect.minY + 60

        let panel = NSPanel(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovable = true
        panel.isMovableByWindowBackground = true    // Drag from anywhere
        panel.minSize = NSSize(width: 240, height: 200)
        panel.maxSize = NSSize(width: 400, height: 600)

        let widgetView = FloatingWidgetView()
            .modelContainer(container)
        let hosting = NSHostingView(rootView: widgetView)
        panel.contentView = hosting
        panel.makeKeyAndOrderFront(nil)

        self.floatingWidgetPanel = panel
    }

    func dismissFloatingWidget() {
        DispatchQueue.main.async { [weak self] in
            self?.floatingWidgetPanel?.orderOut(nil)
            self?.floatingWidgetPanel = nil
        }
    }

    func toggleFloatingWidget(container: ModelContainer) {
        if isShowingWidget {
            dismissFloatingWidget()
        } else {
            showFloatingWidget(container: container)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Daily Summary Alarms
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func triggerDailySummary(type: SummaryType, tasks: [TaskModel], container: ModelContainer) {
        DispatchQueue.main.async { [weak self] in
            self?.showDailySummaryOnAllScreens(type: type, tasks: tasks)
        }
    }

    private func showDailySummaryOnAllScreens(type: SummaryType, tasks: [TaskModel]) {
        guard dailySummaryPanels.isEmpty else { return }

        // Play alarm sound on loop
        playAlertSound(named: "Glass")

        for screen in NSScreen.screens {
            let panel = createDailySummaryPanel(on: screen, type: type, tasks: tasks)
            dailySummaryPanels.append(panel)
        }
    }

    private func createDailySummaryPanel(on screen: NSScreen, type: SummaryType, tasks: [TaskModel]) -> NSPanel {
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = NSColor.black.withAlphaComponent(0.6)
        panel.isOpaque = false
        panel.hasShadow = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovable = false

        let summaryView = DailySummaryView(
            type: type,
            tasks: tasks,
            onDismiss: { [weak self] in
                self?.dismissDailySummary()
            }
        )

        let hosting = NSHostingView(rootView: summaryView)
        panel.contentView = hosting
        panel.makeKeyAndOrderFront(nil)

        return panel
    }

    func dismissDailySummary() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.alertPlayer?.stop()
            self.alertPlayer = nil

            for panel in self.dailySummaryPanels {
                panel.orderOut(nil)
            }
            self.dailySummaryPanels.removeAll()
        }
    }
}
