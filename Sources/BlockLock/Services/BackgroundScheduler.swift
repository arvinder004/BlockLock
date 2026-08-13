import Foundation
import SwiftData
import SwiftUI

/// Background timer engine that runs every 10 seconds to detect overdue tasks
/// and fire micro-reminder check-ins for active tasks.
final class BackgroundScheduler: ObservableObject {
    /// The currently active task (start ≤ now ≤ end, not completed).
    @Published var currentTask: TaskModel?
    /// The first overdue task found, if any.
    @Published var overdueTask: TaskModel?
    /// When true, the scheduler skips all checks (user toggled "Pause Reminders").
    @Published var isPaused: Bool = false
    /// Tracks if there are any uncompleted tasks for the current day.
    @Published var hasUncompletedTasksToday: Bool = false

    let container: ModelContainer
    private var timer: Timer?

    init(container: ModelContainer) {
        self.container = container
        startTimer()
        
        // Immediate check on launch
        DispatchQueue.main.async { [weak self] in
            self?.checkTasks()
        }
    }

    func startTimer() {
        timer?.invalidate()
        // Run on the main run loop so we can safely access the main model context.
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.checkTasks()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Core Check Loop

    @MainActor
    private func checkTasks() {
        guard !isPaused else { return }

        let context = container.mainContext
        let now = Date()

        // Fetch all uncompleted tasks
        let predicate = #Predicate<TaskModel> { task in
            !task.isCompleted
        }
        let descriptor = FetchDescriptor<TaskModel>(predicate: predicate)

        guard let tasks = try? context.fetch(descriptor) else { return }

        // 1. Detect overdue tasks (endTime < now)
        let overdueTasks = tasks.filter { $0.endTime < now }

        if let firstOverdue = overdueTasks.first {
            overdueTask = firstOverdue
            if !OverlayWindowManager.shared.isShowingSoftLock {
                OverlayWindowManager.shared.triggerSoftLock(
                    for: firstOverdue,
                    container: container
                )
            }
        } else {
            overdueTask = nil
        }

        // 2. Identify the current active task (startTime ≤ now ≤ endTime)
        let activeTasks = tasks.filter { $0.startTime <= now && $0.endTime >= now }
        currentTask = activeTasks.first

        // 3. Fire micro-reminders for active tasks with reminders enabled
        for task in activeTasks where task.enableMicroReminders {
            let intervalSeconds = Double(task.reminderIntervalMinutes * 60)
            let shouldRemind: Bool

            if let lastReminder = task.lastReminderPromptAt {
                shouldRemind = now.timeIntervalSince(lastReminder) >= intervalSeconds
            } else {
                // First reminder fires after one interval from start
                shouldRemind = now.timeIntervalSince(task.startTime) >= intervalSeconds
            }

            if shouldRemind && !OverlayWindowManager.shared.isShowingSoftLock {
                task.lastReminderPromptAt = now
                try? context.save()
                OverlayWindowManager.shared.triggerMicroReminder(
                    for: task,
                    container: container
                )
            }
        }
        
        // 4. Force widget open if there are uncompleted tasks today
        let cal = Calendar.current
        let hasIncomplete = tasks.contains { cal.isDateInToday($0.startTime) }
        
        if self.hasUncompletedTasksToday != hasIncomplete {
            self.hasUncompletedTasksToday = hasIncomplete
        }
        
        if hasIncomplete {
            if !OverlayWindowManager.shared.isShowingWidget {
                OverlayWindowManager.shared.showFloatingWidget(container: container)
            }
        }
    }

    deinit {
        timer?.invalidate()
    }
}
