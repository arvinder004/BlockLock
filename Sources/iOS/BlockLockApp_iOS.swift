import SwiftUI
import SwiftData

@main
struct BlockLockApp_iOS: App {
    let container: ModelContainer
    @StateObject private var scheduler: BackgroundScheduler

    init() {
        let schema = Schema([TaskModel.self])
        let config = ModelConfiguration("BlockLock", schema: schema)
        do {
            let modelContainer = try ModelContainer(for: schema, configurations: [config])
            self.container = modelContainer
            self._scheduler = StateObject(
                wrappedValue: BackgroundScheduler(container: modelContainer)
            )
        } catch {
            fatalError("[BlockLock iOS] Failed to initialize SwiftData: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainPlannerView_iOS()
                .environmentObject(scheduler)
                .modelContainer(container)
        }
    }
}
