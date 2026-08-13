import Foundation

struct DailySummarySettings {
    static var isEnabled: Bool {
        get { 
            // Default to true if not set
            if UserDefaults.standard.object(forKey: "dailySummaryEnabled") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "dailySummaryEnabled") 
        }
        set { UserDefaults.standard.set(newValue, forKey: "dailySummaryEnabled") }
    }
    
    // Store times as minutes from midnight
    static var morningTime: Int {
        get { UserDefaults.standard.object(forKey: "morningTime") as? Int ?? 9 * 60 } // Default 9:00 AM
        set { UserDefaults.standard.set(newValue, forKey: "morningTime") }
    }
    
    static var afternoonTime: Int {
        get { UserDefaults.standard.object(forKey: "afternoonTime") as? Int ?? 14 * 60 } // Default 2:00 PM
        set { UserDefaults.standard.set(newValue, forKey: "afternoonTime") }
    }
    
    static var nightTime: Int {
        get { UserDefaults.standard.object(forKey: "nightTime") as? Int ?? 21 * 60 } // Default 9:00 PM
        set { UserDefaults.standard.set(newValue, forKey: "nightTime") }
    }
    
    // Track last fired dates by type
    static func lastFiredDate(for type: SummaryType) -> Date? {
        UserDefaults.standard.object(forKey: "lastFired_\(type.rawValue)") as? Date
    }
    
    static func setLastFiredDate(_ date: Date, for type: SummaryType) {
        UserDefaults.standard.set(date, forKey: "lastFired_\(type.rawValue)")
    }
}
