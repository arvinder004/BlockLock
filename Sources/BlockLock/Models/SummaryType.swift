import Foundation

enum SummaryType: String, CaseIterable, Identifiable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case night = "Night"
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .morning: return "Good Morning!"
        case .afternoon: return "Afternoon Check-in"
        case .night: return "Daily Wrap-up"
        }
    }
    
    var subtitle: String {
        switch self {
        case .morning: return "Here are your planned tasks for today."
        case .afternoon: return "Here is your progress so far today."
        case .night: return "Great work today! Here is your final summary."
        }
    }
}
