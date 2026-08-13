import Foundation
import SwiftData

@Model
final class TaskModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var taskDescription: String?
    var startTime: Date
    var endTime: Date
    var isCompleted: Bool

    // Micro-Reminder Properties
    var enableMicroReminders: Bool
    var reminderIntervalMinutes: Int   // Default: 30
    var lastReminderPromptAt: Date?

    // Sound
    var reminderSound: String = "Glass" // System sound name for micro-reminder alarm

    // Design / Categorization
    var categoryHexColor: String       // Hex string for timeline visualization

    init(
        title: String,
        taskDescription: String? = nil,
        startTime: Date,
        endTime: Date,
        enableMicroReminders: Bool = true,
        reminderIntervalMinutes: Int = 30,
        reminderSound: String = "Glass",
        categoryHexColor: String = "#007AFF"
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = taskDescription
        self.startTime = startTime
        self.endTime = endTime
        self.isCompleted = false
        self.enableMicroReminders = enableMicroReminders
        self.reminderIntervalMinutes = reminderIntervalMinutes
        self.reminderSound = reminderSound
        self.categoryHexColor = categoryHexColor
    }
}
