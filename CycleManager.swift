import Foundation
import SwiftUI

// 用户数据模型
struct User: Identifiable, Codable {
    let id = UUID()
    var name: String
    var cycleLength: Int = 28 // 周期长度（天）
    var periodLength: Int = 5 // 经期长度（天）
    var cycles: [MenstrualCycle] = []
    var symptoms: [Symptom] = []
    
    // 获取最后一次月经开始日期
    var lastPeriodStart: Date? {
        cycles.sorted { $0.startDate > $1.startDate }.first?.startDate
    }
    
    // 预测下次月经开始日期
    var nextPeriodStart: Date? {
        guard let lastStart = lastPeriodStart else { return nil }
        return Calendar.current.date(byAdding: .day, value: cycleLength, to: lastStart)
    }
    
    // 预测排卵日
    var ovulationDate: Date? {
        guard let nextStart = nextPeriodStart else { return nil }
        return Calendar.current.date(byAdding: .day, value: -14, to: nextStart)
    }
}

// 月经周期数据模型
struct MenstrualCycle: Identifiable, Codable {
    let id = UUID()
    var startDate: Date
    var endDate: Date?
    var flow: FlowIntensity = .medium
    var notes: String = ""
    
    var duration: Int {
        guard let endDate = endDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}

// 经血量强度
enum FlowIntensity: String, CaseIterable, Codable {
    case light = "轻量"
    case medium = "中量"
    case heavy = "重量"
    
    var color: Color {
        switch self {
        case .light: return .pink.opacity(0.3)
        case .medium: return .pink.opacity(0.6)
        case .heavy: return .pink.opacity(0.9)
        }
    }
}

// 症状记录
struct Symptom: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var type: SymptomType
    var severity: Int // 1-5级
    var notes: String = ""
}

// 症状类型
enum SymptomType: String, CaseIterable, Codable {
    case cramps = "痛经"
    case headache = "头痛"
    case moodSwings = "情绪波动"
    case bloating = "腹胀"
    case fatigue = "疲劳"
    case acne = "痘痘"
    case breastTenderness = "乳房胀痛"
    
    var icon: String {
        switch self {
        case .cramps: return "bolt.fill"
        case .headache: return "brain.head.profile"
        case .moodSwings: return "face.dashed"
        case .bloating: return "stomach"
        case .fatigue: return "bed.double.fill"
        case .acne: return "face.smiling"
        case .breastTenderness: return "heart.fill"
        }
    }
}

// 周期管理器
class CycleManager: ObservableObject {
    @Published var users: [User] = []
    @Published var selectedUserIndex: Int = 0
    
    private let userDefaultsKey = "SavedUsers"
    
    init() {
        loadUsers()
        if users.isEmpty {
            // 创建默认用户
            users = [
                User(name: "用户1"),
                User(name: "用户2")
            ]
            saveUsers()
        }
    }
    
    var currentUser: User {
        get {
            guard selectedUserIndex < users.count else {
                return User(name: "默认用户")
            }
            return users[selectedUserIndex]
        }
        set {
            if selectedUserIndex < users.count {
                users[selectedUserIndex] = newValue
                saveUsers()
            }
        }
    }
    
    // 添加月经周期记录
    func addCycle(startDate: Date, endDate: Date? = nil, flow: FlowIntensity = .medium, notes: String = "") {
        let cycle = MenstrualCycle(startDate: startDate, endDate: endDate, flow: flow, notes: notes)
        users[selectedUserIndex].cycles.append(cycle)
        saveUsers()
    }
    
    // 添加症状记录
    func addSymptom(date: Date, type: SymptomType, severity: Int, notes: String = "") {
        let symptom = Symptom(date: date, type: type, severity: severity, notes: notes)
        users[selectedUserIndex].symptoms.append(symptom)
        saveUsers()
    }
    
    // 删除月经记录
    func deleteCycle(_ cycle: MenstrualCycle) {
        users[selectedUserIndex].cycles.removeAll { $0.id == cycle.id }
        saveUsers()
    }
    
    // 删除症状记录
    func deleteSymptom(_ symptom: Symptom) {
        users[selectedUserIndex].symptoms.removeAll { $0.id == symptom.id }
        saveUsers()
    }
    
    // 更新用户设置
    func updateUserSettings(name: String, cycleLength: Int, periodLength: Int) {
        users[selectedUserIndex].name = name
        users[selectedUserIndex].cycleLength = cycleLength
        users[selectedUserIndex].periodLength = periodLength
        saveUsers()
    }
    
    // 获取指定日期的周期状态
    func getCycleStatus(for date: Date) -> CycleStatus {
        let user = currentUser
        
        // 检查是否在经期内
        for cycle in user.cycles {
            let endDate = cycle.endDate ?? Calendar.current.date(byAdding: .day, value: user.periodLength, to: cycle.startDate)!
            if date >= cycle.startDate && date <= endDate {
                return .period
            }
        }
        
        // 检查是否在排卵期
        if let ovulationDate = user.ovulationDate {
            let ovulationStart = Calendar.current.date(byAdding: .day, value: -2, to: ovulationDate)!
            let ovulationEnd = Calendar.current.date(byAdding: .day, value: 2, to: ovulationDate)!
            if date >= ovulationStart && date <= ovulationEnd {
                return .ovulation
            }
        }
        
        return .normal
    }
    
    // 保存数据
    private func saveUsers() {
        if let encoded = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    // 加载数据
    private func loadUsers() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([User].self, from: data) {
            users = decoded
        }
    }
    
    // 清除当前用户的所有数据
    func clearCurrentUserData() {
        users[selectedUserIndex].cycles.removeAll()
        users[selectedUserIndex].symptoms.removeAll()
        saveUsers()
    }
    
    // 清除所有用户的所有数据
    func clearAllData() {
        for index in users.indices {
            users[index].cycles.removeAll()
            users[index].symptoms.removeAll()
        }
        saveUsers()
    }
    
    // 重置应用到初始状态
    func resetApp() {
        users = [
            User(name: "用户1"),
            User(name: "用户2")
        ]
        selectedUserIndex = 0
        saveUsers()
    }
}

// 周期状态
enum CycleStatus {
    case period
    case ovulation
    case normal
    
    var color: Color {
        switch self {
        case .period: return .red
        case .ovulation: return .blue
        case .normal: return .gray.opacity(0.3)
        }
    }
    
    var description: String {
        switch self {
        case .period: return "经期"
        case .ovulation: return "排卵期"
        case .normal: return "安全期"
        }
    }
}