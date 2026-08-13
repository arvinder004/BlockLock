import SwiftUI
import ServiceManagement

struct OnboardingView: View {
    let onComplete: () -> Void
    
    @State private var currentTab = 0
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch currentTab {
                case 0: welcomeStep
                case 1: plannerStep
                case 2: alarmsStep
                case 3: completionStep
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack {
                if currentTab > 0 {
                    Button("Back") {
                        withAnimation { currentTab -= 1 }
                    }
                    .buttonStyle(.borderless)
                }
                Spacer()
                
                if currentTab < 3 {
                    Button("Next") {
                        withAnimation { currentTab += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
            .padding(.top, 16)
        }
        .frame(width: 550, height: 420)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Steps
    
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.bottom, 10)
            
            Text("Welcome to BlockLock")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            Text("Your personal anti-procrastination toolkit designed to keep you focused and on track throughout your day.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
        }
    }
    
    private var plannerStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 70))
                .foregroundColor(.orange)
                .padding(.bottom, 10)
            
            Text("Plan Your Day")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text("Use the Main Planner to block out time for your tasks. The visual timeline helps you see exactly when you need to focus, and the menu bar icon keeps your active task always visible.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
        }
    }
    
    private var alarmsStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 70))
                .foregroundColor(.red)
                .padding(.bottom, 10)
            
            Text("Stay Accountable")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text("BlockLock uses aggressive overlays to keep you on task. It will pop up full-screen Soft Locks if you are overdue, sound Micro-reminders during your work, and provide Daily Summaries.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
        }
    }
    
    private var completionStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.green)
                .padding(.bottom, 10)
            
            Text("You're all set!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            VStack(spacing: 12) {
                Text("To get the most out of BlockLock, we recommend allowing it to launch when you start your Mac.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .padding(.top, 10)
                    .onChange(of: launchAtLogin) { _, newValue in
                        toggleLaunchAtLogin(newValue)
                    }
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Actions
    
    private func toggleLaunchAtLogin(_ enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[Onboarding] Launch-at-login failed: \(error)")
            launchAtLogin = !enable
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onComplete()
    }
}
