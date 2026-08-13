# BlockLock

BlockLock is a macOS application designed to help you stop procrastinating and manage your time effectively. 

## Features
- **Main Planner**: Plan your tasks and focus sessions effectively with a side-by-side backlog and 24-hour timeline.
- **Setup Tour**: A beautifully designed onboarding wizard to introduce new users to the app's features and set up "Launch at Login".
- **Daily Summary Alarms**: Automatic Morning, Afternoon, and Night popup alarms that summarize your progress and show your pending/completed tasks for the day.
- **Floating Widget**: An always-on-top floating widget that displays your daily schedule, enabled by default but easily toggled from the menu bar.
- **Overlay Window Manager**: Aggressive full-screen overlays (Soft Locks) to prevent distractions when a scheduled task is overdue.
- **Micro Reminders**: Unobtrusive mini-reminders to keep you on track during your active work sessions.
- **Background Scheduler**: A robust background engine running natively on macOS to ensure you never miss a beat.
- **Modern Settings**: An elegant, card-based settings interface to customize your alarms and preferences.

## Requirements
- macOS 14.0+
- iOS 17.0+ (Simulator/Device for iOS version)
- Xcode 15.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for generating the project)

## Build and Run
This project uses a multi-platform architecture generated via XcodeGen. It supports both macOS and iOS natively.

To build and run:
1. If you don't have XcodeGen installed, install it via Homebrew:
   ```bash
   brew install xcodegen
   ```
2. Generate the Xcode project from the terminal:
   ```bash
   xcodegen
   ```
3. Open the newly created `BlockLock.xcodeproj` file in Xcode.
4. Select your target (`BlockLock (macOS)` or `BlockLock (iOS)`) from the scheme selector in the top bar.
5. Click the **Run** button (or press `Cmd+R`) to build and launch the app!
