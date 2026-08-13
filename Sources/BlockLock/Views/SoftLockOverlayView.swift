import SwiftUI
import SwiftData

/// Full-screen overlay displayed inside the NSPanel when a task is overdue.
/// Users must either mark the task complete or extend the time block to dismiss.
struct SoftLockOverlayView: View {
    let task: TaskModel?
    @Environment(\.modelContext) private var modelContext

    @State private var showExtendOptions = false
    @State private var selectedExtension: TimeInterval = 15 * 60
    @State private var selectedReason: String = "Underestimated scope"
    @State private var animateIn = false

    private let extensionOptions: [(label: String, seconds: TimeInterval)] = [
        ("+15 min", 15 * 60),
        ("+30 min", 30 * 60),
        ("+1 hour", 60 * 60),
    ]

    private let reasons = [
        "Underestimated scope",
        "Distracted",
        "External blocker",
    ]

    var body: some View {
        ZStack {
            // Full-screen dark backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            // Center card
            VStack(spacing: 24) {
                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("Task Overdue")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if let task = task {
                    taskDetailsCard(task)

                    if showExtendOptions {
                        extendOptionsView(task: task)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        actionButtons(task: task)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                #if DEBUG
                Text("Press ⎋ Escape to dismiss (Debug only)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(.top, 16)
                #endif
            }
            .padding(48)
            .scaleEffect(animateIn ? 1.0 : 0.85)
            .opacity(animateIn ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                animateIn = true
            }
        }
    }

    // MARK: - Task Details Card

    @ViewBuilder
    private func taskDetailsCard(_ task: TaskModel) -> some View {
        VStack(spacing: 14) {
            Text(task.title)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            if let desc = task.taskDescription, !desc.isEmpty {
                Text(desc)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
            }

            HStack(spacing: 20) {
                Label(formatTime(task.startTime), systemImage: "clock")
                Text("→")
                    .fontWeight(.bold)
                Label(formatTime(task.endTime), systemImage: "clock.badge.exclamationmark")
            }
            .font(.callout)
            .foregroundStyle(.white.opacity(0.7))

            // Live overdue counter
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let overdue = context.date.timeIntervalSince(task.endTime)
                if overdue > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .foregroundStyle(.red)
                        Text("Overdue by \(formatDuration(overdue))")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundStyle(.red)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(24)
        .frame(minWidth: 380)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private func actionButtons(task: TaskModel) -> some View {
        HStack(spacing: 20) {
            Button(action: { markCompleted(task) }) {
                Label("Mark Completed", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(minWidth: 180, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)

            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showExtendOptions = true
                }
            }) {
                Label("Extend Time", systemImage: "clock.arrow.2.circlepath")
                    .font(.headline)
                    .frame(minWidth: 180, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.large)
        }
    }

    // MARK: - Extend Options

    @ViewBuilder
    private func extendOptionsView(task: TaskModel) -> some View {
        VStack(spacing: 18) {
            Text("Extend by:")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                ForEach(extensionOptions, id: \.seconds) { option in
                    Button(option.label) {
                        selectedExtension = option.seconds
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedExtension == option.seconds ? .blue : .gray)
                    .controlSize(.large)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Reason")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                Picker("Reason", selection: $selectedReason) {
                    ForEach(reasons, id: \.self) { reason in
                        Text(reason).tag(reason)
                    }
                }
                .pickerStyle(.segmented)
            }
            .frame(maxWidth: 420)

            HStack(spacing: 16) {
                Button("Cancel") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showExtendOptions = false
                    }
                }
                .buttonStyle(.bordered)
                .tint(.gray)

                Button("Confirm Extension") {
                    extendTime(task)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Actions

    private func markCompleted(_ task: TaskModel) {
        task.isCompleted = true
        try? modelContext.save()
        OverlayWindowManager.shared.dismissSoftLock()
    }

    private func extendTime(_ task: TaskModel) {
        task.endTime = task.endTime.addingTimeInterval(selectedExtension)
        try? modelContext.save()
        OverlayWindowManager.shared.dismissSoftLock()
    }

    // MARK: - Formatters

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return "\(s)s"
    }
}
