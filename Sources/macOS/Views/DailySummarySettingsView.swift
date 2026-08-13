import SwiftUI

struct DailySummarySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("dailySummaryEnabled") private var isEnabled: Bool = true
    @AppStorage("morningTime") private var morningTime: Int = 9 * 60
    @AppStorage("afternoonTime") private var afternoonTime: Int = 14 * 60
    @AppStorage("nightTime") private var nightTime: Int = 21 * 60
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Main Toggle Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Daily Summary Alarms")
                                    .font(.headline)
                                Text("Alarms will pop up to show your tasks for the day.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $isEnabled)
                                .toggleStyle(.switch)
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                    )
                    
                    if isEnabled {
                        // Times Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Alarm Times")
                                .font(.headline)
                                .padding(.bottom, -4)
                            
                            Divider()
                            
                            TimePickerRow(title: "Morning", subtitle: "Planned Tasks", icon: "sun.max.fill", color: .orange, minutes: $morningTime)
                                .onChange(of: morningTime) { UserDefaults.standard.removeObject(forKey: "lastFired_\(SummaryType.morning.rawValue)") }
                            
                            Divider()
                            
                            TimePickerRow(title: "Afternoon", subtitle: "Progress Check", icon: "sun.horizon.fill", color: .yellow, minutes: $afternoonTime)
                                .onChange(of: afternoonTime) { UserDefaults.standard.removeObject(forKey: "lastFired_\(SummaryType.afternoon.rawValue)") }
                            
                            Divider()
                            
                            TimePickerRow(title: "Night", subtitle: "Daily Wrap-up", icon: "moon.stars.fill", color: .indigo, minutes: $nightTime)
                                .onChange(of: nightTime) { UserDefaults.standard.removeObject(forKey: "lastFired_\(SummaryType.night.rawValue)") }
                        }
                        .padding(16)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 450, height: 460)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct TimePickerRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var minutes: Int
    
    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                let cal = Calendar.current
                return cal.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
            },
            set: { newDate in
                let cal = Calendar.current
                minutes = cal.component(.hour, from: newDate) * 60 + cal.component(.minute, from: newDate)
            }
        )
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            DatePicker("", selection: timeBinding, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .frame(width: 90)
        }
    }
}
