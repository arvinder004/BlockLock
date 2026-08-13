import SwiftUI

/// Large, centered micro-reminder overlay for check-ins on active tasks.
/// Shown on all connected displays with an alert sound.
struct MicroReminderView: View {
    let task: TaskModel?
    let onDismiss: () -> Void
    let onPauseReminders: () -> Void

    @State private var animateIn = false
    @State private var pulseRing = false

    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Center card
            VStack(spacing: 28) {
                // Pulsing bell icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.08))
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseRing ? 1.3 : 1.0)
                        .opacity(pulseRing ? 0 : 0.6)

                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 80, height: 80)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.blue)
                }
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        pulseRing = true
                    }
                }

                // Title & task name
                VStack(spacing: 10) {
                    Text("Check-in")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    if let task = task {
                        Text("Still working on")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("\"\(task.title)\"?")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }

                // Time remaining badge
                if let task = task, !task.isCompleted {
                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        let remaining = task.endTime.timeIntervalSince(ctx.date)
                        if remaining > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .font(.callout)
                                Text("\(formatDuration(remaining)) remaining")
                                    .font(.system(.body, design: .monospaced).bold())
                            }
                            .foregroundStyle(remaining < 300 ? .red : .secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(remaining < 300 ? Color.red.opacity(0.1) : Color.secondary.opacity(0.1))
                            )
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text("Time is up!")
                                    .font(.headline)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                // Action buttons
                HStack(spacing: 18) {
                    Button(action: onDismiss) {
                        Label("Yes, on it", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.large)

                    Button(action: onPauseReminders) {
                        Label("Pause Reminders", systemImage: "bell.slash.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.top, 4)
            }
            .padding(44)
            .frame(width: 520)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThickMaterial)
                    .shadow(color: .black.opacity(0.35), radius: 40, y: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(animateIn ? 1.0 : 0.75)
            .opacity(animateIn ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
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
