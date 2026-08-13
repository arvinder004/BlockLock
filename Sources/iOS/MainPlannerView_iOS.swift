import SwiftUI
import SwiftData

struct MainPlannerView_iOS: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var scheduler: BackgroundScheduler
    @Query(sort: \TaskModel.startTime) private var allTasks: [TaskModel]
    
    var body: some View {
        NavigationStack {
            List {
                if allTasks.isEmpty {
                    Text("No tasks yet. Tap + to add one.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(allTasks) { task in
                        VStack(alignment: .leading) {
                            Text(task.title).font(.headline)
                            Text("\(task.startTime, format: .dateTime.hour().minute()) - \(task.endTime, format: .dateTime.hour().minute())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("BlockLock")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        // TODO: iOS Task Creation
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}
