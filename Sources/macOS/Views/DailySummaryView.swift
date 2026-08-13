import SwiftUI
import SwiftData

struct DailySummaryView: View {
    let type: SummaryType
    let tasks: [TaskModel]
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text(type.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(type.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            
            // Task List
            if tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No tasks scheduled for today.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(tasks.sorted(by: { $0.startTime < $1.startTime })) { task in
                            TaskSummaryRow(task: task)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Dismiss Button
            Button(action: onDismiss) {
                Text("Dismiss Alarm")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .frame(width: 450, height: 600)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
    }
}

struct TaskSummaryRow: View {
    let task: TaskModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: task.categoryHexColor))
                .frame(width: 8, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                Text("\(formatTime(task.startTime)) - \(formatTime(task.endTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Explicit status text/icon
            VStack(alignment: .trailing, spacing: 4) {
                if task.isCompleted {
                    HStack(spacing: 4) {
                        Text("Completed")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Text("Pending")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                        Image(systemName: "circle")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
