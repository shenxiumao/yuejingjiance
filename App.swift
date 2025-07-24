import SwiftUI

@main
struct YueJingJiancheApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // 可以根据需要调整
        }
    }
}

// 应用配置
struct AppConfig {
    static let appName = "月经助手"
    static let version = "1.0.0"
    static let buildNumber = "1"
    
    // 颜色主题
    struct Colors {
        static let primary = Color.pink
        static let secondary = Color.blue
        static let accent = Color.orange
        static let background = Color(.systemGroupedBackground)
        static let cardBackground = Color(.systemBackground)
    }
    
    // 默认设置
    struct Defaults {
        static let defaultCycleLength = 28
        static let defaultPeriodLength = 5
        static let defaultUser1Name = "用户1"
        static let defaultUser2Name = "用户2"
    }
}

// 全局扩展
extension Color {
    static let appPrimary = AppConfig.Colors.primary
    static let appSecondary = AppConfig.Colors.secondary
    static let appAccent = AppConfig.Colors.accent
}

// 通知相关
struct NotificationManager {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("通知权限已获得")
            } else {
                print("通知权限被拒绝")
            }
        }
    }
    
    static func schedulePeriodReminder(for user: User) {
        guard let nextPeriodDate = user.nextPeriodStart else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "月经提醒"
        content.body = "\(user.name)，您的月经可能即将到来"
        content.sound = .default
        
        let triggerDate = Calendar.current.date(byAdding: .day, value: -1, to: nextPeriodDate)!
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour], from: triggerDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "period_reminder_\(user.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    static func scheduleOvulationReminder(for user: User) {
        guard let ovulationDate = user.ovulationDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "排卵期提醒"
        content.body = "\(user.name)，您正处于排卵期"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour], from: ovulationDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "ovulation_reminder_\(user.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// 数据验证
struct DataValidator {
    static func isValidCycleLength(_ length: Int) -> Bool {
        return length >= 21 && length <= 35
    }
    
    static func isValidPeriodLength(_ length: Int) -> Bool {
        return length >= 3 && length <= 8
    }
    
    static func isValidDateRange(start: Date, end: Date) -> Bool {
        return start <= end
    }
}

// 数据导出工具
struct DataExporter {
    static func exportToCSV(users: [User]) -> String {
        var csv = "用户名,日期,类型,详情\n"
        
        for user in users {
            // 导出月经记录
            for cycle in user.cycles {
                csv += "\(user.name),\(DateFormatter.exportDate.string(from: cycle.startDate)),月经开始,\(cycle.flow.rawValue)\n"
                if let endDate = cycle.endDate {
                    csv += "\(user.name),\(DateFormatter.exportDate.string(from: endDate)),月经结束,\(cycle.flow.rawValue)\n"
                }
            }
            
            // 导出症状记录
            for symptom in user.symptoms {
                csv += "\(user.name),\(DateFormatter.exportDate.string(from: symptom.date)),症状,\(symptom.type.rawValue) - 严重程度:\(symptom.severity)\n"
            }
        }
        
        return csv
    }
    
    static func exportToJSON(users: [User]) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try? encoder.encode(users)
    }
}

// 日期格式化扩展
extension DateFormatter {
    static let exportDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

// 用户默认设置扩展
extension UserDefaults {
    private enum Keys {
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let notificationsEnabled = "notificationsEnabled"
        static let selectedTheme = "selectedTheme"
    }
    
    var hasLaunchedBefore: Bool {
        get { bool(forKey: Keys.hasLaunchedBefore) }
        set { set(newValue, forKey: Keys.hasLaunchedBefore) }
    }
    
    var notificationsEnabled: Bool {
        get { bool(forKey: Keys.notificationsEnabled) }
        set { set(newValue, forKey: Keys.notificationsEnabled) }
    }
    
    var selectedTheme: String {
        get { string(forKey: Keys.selectedTheme) ?? "light" }
        set { set(newValue, forKey: Keys.selectedTheme) }
    }
}

// 应用生命周期管理
class AppLifecycleManager: ObservableObject {
    @Published var isActive = true
    
    init() {
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isActive = true
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isActive = false
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// 导入UserNotifications框架
import UserNotifications