import SwiftUI
import SwiftData

/// Compact always-on-top floating widget showing today's schedule with live timers.
/// Draggable, stays above all windows across all Spaces.
struct FloatingWidgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskModel.startTime) private var allTasks: [TaskModel]

    private var todayTasks: [TaskModel] {
        let cal = Calendar.current
        return allTasks.filter { cal.isDateInToday($0.startTime) }
    }

    private var activeTasks: [TaskModel] {
        let now = Date()
        return todayTasks.filter { !$0.isCompleted && $0.startTime <= now && $0.endTime >= now }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("Today's Schedule")
                    .font(.system(.subheadline, design: .rounded).bold())
                Spacer()
                Text("\(todayTasks.filter { !$0.isCompleted }.count) left")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.quaternary))
                
                let hasIncomplete = !todayTasks.filter { !$0.isCompleted }.isEmpty
                if !hasIncomplete {
                    Button(action: {
                        OverlayWindowManager.shared.dismissFloatingWidget()
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(.quaternary))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // ── Task List ──
            if todayTasks.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.title3)
                        .foregroundStyle(.quaternary)
                    Text("No tasks today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView {
                    VStack(spacing: 1) {
                        ForEach(todayTasks) { task in
                            taskRow(task)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 320)
            }

            // ── Active task highlight ──
            if let active = activeTasks.first {
                Divider()
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: active.categoryHexColor))
                        .frame(width: 6, height: 6)
                    Text("Now:")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text(active.title)
                        .font(.caption2.bold())
                        .foregroundStyle(Color(hex: active.categoryHexColor))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(hex: active.categoryHexColor).opacity(0.08))
            }
        }
        .frame(width: 280)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Task Row

    @ViewBuilder
    private func taskRow(_ task: TaskModel) -> some View {
        let isActive = isTaskActive(task)

        HStack(spacing: 8) {
            // Checkbox toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    task.isCompleted.toggle()
                    try? modelContext.save()
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(task.isCompleted ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)

            // Color dot
            Circle()
                .fill(Color(hex: task.categoryHexColor))
                .frame(width: 7, height: 7)

            // Title
            Text(task.title)
                .font(.system(.caption, design: .rounded))
                .fontWeight(isActive ? .bold : .regular)
                .lineLimit(1)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)

            Spacer(minLength: 4)

            // Timer / status
            if task.isCompleted {
                Text("done")
                    .font(.caption2)
                    .foregroundStyle(.green)
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    let now = ctx.date
                    if now < task.startTime {
                        // Upcoming
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 8))
                            Text(formatCountdown(task.startTime.timeIntervalSince(now)))
                        }
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                    } else if now <= task.endTime {
                        // Active — show remaining
                        let remaining = task.endTime.timeIntervalSince(now)
                        Text(formatCountdown(remaining))
                            .font(.system(.caption2, design: .monospaced).bold())
                            .foregroundStyle(remaining < 300 ? .red : Color(hex: task.categoryHexColor))
                    } else {
                        // Overdue
                        Text("overdue")
                            .font(.caption2.bold())
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isActive ? Color(hex: task.categoryHexColor).opacity(0.1) : .clear)
        )
        .padding(.horizontal, 4)
    }

    // MARK: - Helpers

    private func isTaskActive(_ task: TaskModel) -> Bool {
        let now = Date()
        return now >= task.startTime && now <= task.endTime && !task.isCompleted
    }

    private func formatCountdown(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}
