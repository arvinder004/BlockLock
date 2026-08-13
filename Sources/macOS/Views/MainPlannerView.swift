import SwiftUI
import SwiftData

/// Split-view layout: sidebar task backlog + 24-hour vertical timeline.
struct MainPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var scheduler: BackgroundScheduler
    @Query(sort: \TaskModel.startTime) private var allTasks: [TaskModel]

    @State private var showingTaskCreation = false
    @State private var showingSettings = false
    @State private var editingTask: TaskModel?
    @State private var filterMode: FilterMode = .today
    @State private var selectedDate: Date = Date()

    enum FilterMode: String, CaseIterable {
        case today    = "Today"
        case all      = "All"
        case upcoming = "Upcoming"
    }

    // Tasks shown in the sidebar list (filtered)
    private var filteredTasks: [TaskModel] {
        let cal = Calendar.current
        switch filterMode {
        case .today:
            return allTasks.filter { cal.isDate($0.startTime, inSameDayAs: selectedDate) && !$0.isCompleted }
        case .all:
            return allTasks.filter { !$0.isCompleted }
        case .upcoming:
            let now = Date()
            return allTasks.filter { $0.startTime > now && !$0.isCompleted }
        }
    }

    // Tasks shown on the 24-hour timeline (all tasks for the selected day)
    private var dayTasks: [TaskModel] {
        let cal = Calendar.current
        return allTasks.filter { cal.isDate($0.startTime, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationSplitView {
            sidebarView
                .navigationSplitViewColumnWidth(min: 230, ideal: 270, max: 340)
        } detail: {
            timelineView
        }
        .frame(minWidth: 920, minHeight: 620)
        .sheet(isPresented: $showingTaskCreation) {
            TaskCreationView()
        }
        .sheet(item: $editingTask) { task in
            TaskCreationView(editingTask: task)
        }
        .sheet(isPresented: $showingSettings) {
            DailySummarySettingsView()
        }
    }

    // MARK: ─── Sidebar ───

    @ViewBuilder
    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Tasks")
                    .font(.system(.title3, design: .rounded).bold())
                Spacer()
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Settings")
                
                Button(action: { showingTaskCreation = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .help("Add new task")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Filter pills
            Picker("Filter", selection: $filterMode) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            Divider()

            // Task list
            if filteredTasks.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredTasks) { task in
                        taskRow(task)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteTask(task)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    task.isCompleted.toggle()
                                    try? modelContext.save()
                                } label: {
                                    Label(
                                        task.isCompleted ? "Undo" : "Done",
                                        systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                    )
                                }
                                .tint(.green)
                            }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.quaternary)
            Text("No tasks")
                .font(.callout)
                .foregroundStyle(.secondary)
            Button("Add Task") { showingTaskCreation = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            Spacer()
        }
    }

    @ViewBuilder
    private func taskRow(_ task: TaskModel) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: task.categoryHexColor))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.callout.bold())
                    .lineLimit(1)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                Text(formatTimeRange(task.startTime, task.endTime, showDate: filterMode != .today))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)

            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { editingTask = task }
    }

    // MARK: ─── 24-Hour Timeline ───

    @ViewBuilder
    private var timelineView: some View {
        let hourHeight: CGFloat = 72

        VStack(spacing: 0) {
            // Day navigation header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDate, format: .dateTime.weekday(.wide))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(selectedDate, format: .dateTime.month(.wide).day().year())
                        .font(.system(.title2, design: .rounded).bold())
                }

                Spacer()

                HStack(spacing: 6) {
                    Button(action: { shiftDay(-1) }) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("Today") { selectedDate = Date() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                    Button(action: { shiftDay(1) }) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            // Scrollable timeline grid
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    ZStack(alignment: .topLeading) {
                        // Hour grid
                        VStack(spacing: 0) {
                            ForEach(0..<24, id: \.self) { hour in
                                HStack(alignment: .top, spacing: 8) {
                                    Text(hourLabel(hour))
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                        .frame(width: 54, alignment: .trailing)

                                    VStack(spacing: 0) {
                                        Divider()
                                        Spacer()
                                    }
                                }
                                .frame(height: hourHeight)
                                .id(hour)
                            }
                        }

                        // Task blocks
                        ForEach(dayTasks) { task in
                            TimelineBlockView(task: task, hourHeight: hourHeight) {
                                editingTask = task
                            }
                            .padding(.leading, 70)
                            .padding(.trailing, 20)
                            .offset(y: yPosition(for: task.startTime, hourHeight: hourHeight))
                        }

                        // Current time indicator (red line)
                        if Calendar.current.isDateInToday(selectedDate) {
                            TimelineView(.periodic(from: .now, by: 60)) { ctx in
                                let y = yPosition(for: ctx.date, hourHeight: hourHeight)
                                HStack(spacing: 0) {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 9, height: 9)
                                    Rectangle()
                                        .fill(.red)
                                        .frame(height: 1.5)
                                }
                                .padding(.leading, 52)
                                .offset(y: y)
                            }
                        }
                    }
                }
                .onAppear {
                    let h = Calendar.current.component(.hour, from: Date())
                    proxy.scrollTo(max(h - 2, 0), anchor: .top)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: ─── Helpers ───

    private func yPosition(for date: Date, hourHeight: CGFloat) -> CGFloat {
        let cal = Calendar.current
        let h = CGFloat(cal.component(.hour, from: date))
        let m = CGFloat(cal.component(.minute, from: date))
        return (h + m / 60.0) * hourHeight
    }

    private func hourLabel(_ hour: Int) -> String {
        switch hour {
        case 0:  return "12 AM"
        case 12: return "12 PM"
        case let h where h < 12: return "\(h) AM"
        default: return "\(hour - 12) PM"
        }
    }

    private func formatTimeRange(_ start: Date, _ end: Date, showDate: Bool) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        let timeStr = "\(timeFormatter.string(from: start)) – \(timeFormatter.string(from: end))"
        
        if showDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            return "\(dateFormatter.string(from: start)) • \(timeStr)"
        }
        return timeStr
    }

    private func shiftDay(_ offset: Int) {
        selectedDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) ?? selectedDate
    }

    private func deleteTask(_ task: TaskModel) {
        modelContext.delete(task)
        try? modelContext.save()
    }
}
