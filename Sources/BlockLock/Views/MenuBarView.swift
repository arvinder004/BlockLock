import SwiftUI
import SwiftData
import ServiceManagement

/// Menu bar popover showing the active task, countdown ring, quick actions, and settings.
struct MenuBarView: View {
    @EnvironmentObject private var scheduler: BackgroundScheduler
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(spacing: 0) {
            // Active task card
            currentTaskSection
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

            Divider()

            // Quick actions
            actionButtons
                .padding(.vertical, 6)

            Divider()

            // Settings
            settingsSection
                .padding(.vertical, 6)

            #if DEBUG
            Divider()
            debugSection
                .padding(.vertical, 6)
            #endif
        }
        .frame(width: 310)
        .padding(.bottom, 8)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    // MARK: - Current Task

    @ViewBuilder
    private var currentTaskSection: some View {
        if let task = scheduler.currentTask {
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: task.categoryHexColor))
                        .frame(width: 10, height: 10)
                    Text(task.title)
                        .font(.system(.headline, design: .rounded))
                        .lineLimit(1)
                    Spacer()
                }

                // Countdown ring + time remaining
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    let total = task.endTime.timeIntervalSince(task.startTime)
                    let elapsed = ctx.date.timeIntervalSince(task.startTime)
                    let remaining = max(0, task.endTime.timeIntervalSince(ctx.date))
                    let progress = min(max(elapsed / total, 0), 1)

                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(.quaternary, lineWidth: 4)
                                .frame(width: 48, height: 48)
                            Circle()
                                .trim(from: 0, to: CGFloat(progress))
                                .stroke(
                                    progress > 0.9
                                        ? Color.red
                                        : Color(hex: task.categoryHexColor),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 48, height: 48)
                                .rotationEffect(.degrees(-90))

                            Image(systemName: "timer")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatCountdown(remaining))
                                .font(.system(.title3, design: .monospaced).bold())
                                .foregroundStyle(remaining < 300 ? .red : .primary)
                            Text("remaining")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()
                    }
                }
            }
        } else if let overdue = scheduler.overdueTask {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Task Overdue")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text(overdue.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.quaternary)
                Text("No active task")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 0) {
            if scheduler.currentTask != nil {
                menuButton(
                    "Complete Active Task",
                    icon: "checkmark.circle",
                    action: completeCurrentTask
                )
            }

            menuButton("Open Full Planner", icon: "calendar") {
                openWindow(id: "planner")
                // Bring the app window to front
                NSApp.activate(ignoringOtherApps: true)
            }

            if !scheduler.hasUncompletedTasksToday {
                menuButton(
                    OverlayWindowManager.shared.isShowingWidget ? "Hide Widget" : "Show Widget",
                    icon: OverlayWindowManager.shared.isShowingWidget ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle"
                ) {
                    OverlayWindowManager.shared.toggleFloatingWidget(container: scheduler.container)
                }
            }

            menuButton(
                scheduler.isPaused ? "Resume Reminders" : "Pause Reminders",
                icon: scheduler.isPaused ? "bell" : "bell.slash"
            ) {
                scheduler.isPaused.toggle()
            }
        }
    }

    // MARK: - Settings

    @ViewBuilder
    private var settingsSection: some View {
        VStack(spacing: 0) {
            // Launch at Login toggle
            // ─────────────────────────────────────────────────────────────
            // SMAppService.mainApp.register() requires the app to be
            // properly code-signed with an Apple Developer certificate.
            //
            // How it works:
            //   • register()   → tells launchd to open the app after login
            //   • unregister() → removes the login item
            //
            // In unsigned/debug builds (e.g. `swift run`), register()
            // will throw an error and the toggle silently reverts.
            // Once you archive & sign the app for distribution, it works.
            // ─────────────────────────────────────────────────────────────
            HStack {
                Label("Launch at Login", systemImage: "power")
                    .font(.callout)
                Spacer()
                Toggle("", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .onChange(of: launchAtLogin) { _, newValue in
                toggleLaunchAtLogin(newValue)
            }

            Divider()
                .padding(.vertical, 4)

            menuButton("Quit BlockLock", icon: "power", tint: .red) {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    // MARK: - Debug

    #if DEBUG
    @ViewBuilder
    private var debugSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Debug")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 4)

            menuButton("Test Soft Lock", icon: "lock.shield") {
                OverlayWindowManager.shared.triggerSoftLock(
                    for: scheduler.currentTask,
                    container: scheduler.container
                )
            }
        }
    }
    #endif

    // MARK: - Helpers

    @ViewBuilder
    private func menuButton(
        _ title: String,
        icon: String,
        tint: Color = .primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 18)
                Text(title)
                Spacer()
            }
            .font(.callout)
            .foregroundStyle(tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func completeCurrentTask() {
        guard let task = scheduler.currentTask else { return }
        task.isCompleted = true
        try? modelContext.save()
    }

    private func toggleLaunchAtLogin(_ enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Revert toggle — signing required for SMAppService to work.
            print("[BlockLock] Launch-at-login failed (app must be code-signed): \(error)")
            launchAtLogin = !enable
        }
    }

    private func formatCountdown(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}
