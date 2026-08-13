import SwiftUI
import SwiftData
import AppKit

/// Sheet view for creating a new task or editing an existing one.
struct TaskCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Pass an existing task to edit it; leave nil to create a new one.
    var editingTask: TaskModel?

    @State private var title: String = ""
    @State private var taskDescription: String = ""
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(3600)
    @State private var selectedColorHex: String = "#007AFF"
    @State private var enableMicroReminders: Bool = true
    @State private var reminderInterval: Int = 30
    @State private var reminderSound: String = "Glass"
    @State private var previewPlayer: NSSound? = nil

    /// All available macOS system sounds and iOS ringtones for the alarm picker.
    private let availableSounds = [
        // iOS Ringtones
        "Alarm", "Apex", "Beacon", "Chimes", "Circuit", "Crystals",
        "Radar", "Radiate", "Reflection", "Sencha", "Signal", "Silk",
        "Twinkle", "Uplift", "Waves",
        // Mac Sounds
        "Glass", "Ping", "Hero", "Submarine", "Purr",
        "Funk", "Basso", "Blow", "Bottle", "Frog",
        "Morse", "Pop", "Sosumi", "Tink"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──
            HStack {
                Text(editingTask == nil ? "New Task" : "Edit Task")
                    .font(.system(.title2, design: .rounded).bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()

            // ── Form ──
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Title
                    fieldGroup("Title") {
                        TextField("What are you working on?", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                    }

                    // Description
                    fieldGroup("Description (optional)") {
                        TextField("Add details…", text: $taskDescription, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }

                    // Time pickers
                    HStack(spacing: 20) {
                        fieldGroup("Start") {
                            DatePicker("", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                        }
                        fieldGroup("End") {
                            DatePicker("", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                        }
                    }

                    // Category color palette
                    fieldGroup("Category Color") {
                        HStack(spacing: 10) {
                            ForEach(ColorPalette.presets, id: \.hex) { preset in
                                Circle()
                                    .fill(Color(hex: preset.hex))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(.white, lineWidth: selectedColorHex == preset.hex ? 2.5 : 0)
                                    )
                                    .shadow(
                                        color: selectedColorHex == preset.hex
                                            ? Color(hex: preset.hex).opacity(0.5)
                                            : .clear,
                                        radius: 6
                                    )
                                    .scaleEffect(selectedColorHex == preset.hex ? 1.12 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: selectedColorHex)
                                    .onTapGesture {
                                        selectedColorHex = preset.hex
                                    }
                                    .help(preset.name)
                            }
                        }
                    }

                    Divider()

                    // Micro-reminders
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(isOn: $enableMicroReminders) {
                            HStack(spacing: 6) {
                                Image(systemName: "bell.badge")
                                    .foregroundStyle(.blue)
                                Text("Micro-Reminders")
                            }
                        }

                        if enableMicroReminders {
                            HStack {
                                Text("Remind every")
                                    .foregroundStyle(.secondary)
                                Stepper(
                                    "\(reminderInterval) min",
                                    value: $reminderInterval,
                                    in: 5...120,
                                    step: 5
                                )
                            }
                            .font(.callout)
                            .padding(.leading, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))

                            // Alarm sound picker
                            HStack(spacing: 10) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(.orange)
                                    .frame(width: 18)

                                Picker("Alarm Sound", selection: $reminderSound) {
                                    ForEach(availableSounds, id: \.self) { sound in
                                        Text(sound).tag(sound)
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: 150)

                                // Preview button
                                Button(action: {
                                    // If already playing, stop it
                                    if let player = previewPlayer, player.isPlaying {
                                        player.stop()
                                        previewPlayer = nil
                                    } else {
                                        // Stop any existing sound and play new one
                                        previewPlayer?.stop()
                                        if let sound = OverlayWindowManager.loadSound(named: reminderSound) {
                                            sound.loops = false
                                            sound.play()
                                            previewPlayer = sound
                                        }
                                    }
                                }) {
                                    Image(systemName: (previewPlayer?.isPlaying ?? false) ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                                .buttonStyle(.plain)
                                .help("Preview sound")
                            }
                            .padding(.leading, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .onChange(of: reminderSound) { _, _ in
                                // Stop sound if user changes the selection
                                previewPlayer?.stop()
                                previewPlayer = nil
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: enableMicroReminders)
                }
                .padding(20)
            }

            Divider()

            // ── Footer ──
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(editingTask == nil ? "Create Task" : "Save Changes") {
                    saveTask()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(20)
        }
        .frame(width: 460, height: 560)
        .onAppear(perform: populateFromExisting)
        .onDisappear {
            // Ensure preview sound stops when the creation sheet is closed/saved
            previewPlayer?.stop()
            previewPlayer = nil
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func fieldGroup<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
    }

    private func populateFromExisting() {
        guard let task = editingTask else { return }
        title = task.title
        taskDescription = task.taskDescription ?? ""
        startTime = task.startTime
        endTime = task.endTime
        selectedColorHex = task.categoryHexColor
        enableMicroReminders = task.enableMicroReminders
        reminderInterval = task.reminderIntervalMinutes
        reminderSound = task.reminderSound
    }

    private func saveTask() {
        if let task = editingTask {
            // Update existing
            task.title = title
            task.taskDescription = taskDescription.isEmpty ? nil : taskDescription
            task.startTime = startTime
            task.endTime = endTime
            task.categoryHexColor = selectedColorHex
            task.enableMicroReminders = enableMicroReminders
            task.reminderIntervalMinutes = reminderInterval
            task.reminderSound = reminderSound
        } else {
            // Create new
            let task = TaskModel(
                title: title,
                taskDescription: taskDescription.isEmpty ? nil : taskDescription,
                startTime: startTime,
                endTime: endTime,
                enableMicroReminders: enableMicroReminders,
                reminderIntervalMinutes: reminderInterval,
                reminderSound: reminderSound,
                categoryHexColor: selectedColorHex
            )
            modelContext.insert(task)
        }

        try? modelContext.save()
        dismiss()
    }
}
