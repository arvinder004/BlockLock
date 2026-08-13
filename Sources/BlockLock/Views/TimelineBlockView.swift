import SwiftUI

/// A single task block on the 24-hour timeline, colored by category.
struct TimelineBlockView: View {
    let task: TaskModel
    let hourHeight: CGFloat
    let onTap: () -> Void

    private var blockHeight: CGFloat {
        let duration = task.endTime.timeIntervalSince(task.startTime) / 3600.0
        return max(CGFloat(duration) * hourHeight, 32)
    }

    private var isActive: Bool {
        let now = Date()
        return now >= task.startTime && now <= task.endTime && !task.isCompleted
    }

    private var isOverdue: Bool {
        Date() > task.endTime && !task.isCompleted
    }

    var body: some View {
        HStack(spacing: 0) {
            // Color accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: task.categoryHexColor))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.callout.bold())
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                    .lineLimit(1)

                Text(timeRangeString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Spacer(minLength: 0)

            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .padding(.trailing, 10)
            } else if isOverdue {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                    .padding(.trailing, 10)
            } else if isActive {
                Image(systemName: "play.circle.fill")
                    .foregroundStyle(Color(hex: task.categoryHexColor))
                    .padding(.trailing, 10)
            }
        }
        .frame(height: blockHeight)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: task.categoryHexColor).opacity(task.isCompleted ? 0.06 : 0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isActive ? Color(hex: task.categoryHexColor).opacity(0.6) : .clear,
                            lineWidth: isActive ? 1.5 : 0
                        )
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var timeRangeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: task.startTime)) – \(f.string(from: task.endTime))"
    }
}
