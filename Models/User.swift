//
//  User.swift
//  YueJingJiance
//
//  用户数据模型 - 领域层
//

import Foundation

// MARK: - 用户实体
struct UserEntity: Identifiable, Equatable {
    let id: UUID
    var name: String
    var avatarColor: String
    var cycleLength: Int
    var periodLength: Int
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
    
    init(
        id: UUID = UUID(),
        name: String = "用户",
        avatarColor: String = "#FF69B4",
        cycleLength: Int = 28,
        periodLength: Int = 5,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.avatarColor = avatarColor
        self.cycleLength = cycleLength
        self.periodLength = periodLength
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
    }
    
    mutating func update(name: String? = nil, avatarColor: String? = nil, cycleLength: Int? = nil, periodLength: Int? = nil) {
        if let name = name { self.name = name }
        if let avatarColor = avatarColor { self.avatarColor = avatarColor }
        if let cycleLength = cycleLength { self.cycleLength = cycleLength }
        if let periodLength = periodLength { self.periodLength = periodLength }
        self.updatedAt = Date()
    }
}

// MARK: - 月经周期实体
struct MenstrualCycleEntity: Identifiable, Equatable {
    let id: UUID
    var userId: UUID
    var startDate: Date
    var endDate: Date?
    var flowIntensity: FlowIntensity
    var symptoms: [String]
    var notes: String
    var isPredicted: Bool
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        startDate: Date,
        endDate: Date? = nil,
        flowIntensity: FlowIntensity = .medium,
        symptoms: [String] = [],
        notes: String = "",
        isPredicted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.startDate = startDate
        self.endDate = endDate
        self.flowIntensity = flowIntensity
        self.symptoms = symptoms
        self.notes = notes
        self.isPredicted = isPredicted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
    }
    
    var duration: Int {
        guard let endDate = endDate else {
            return Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        }
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    mutating func update(endDate: Date? = nil, flowIntensity: FlowIntensity? = nil, symptoms: [String]? = nil, notes: String? = nil) {
        if let endDate = endDate { self.endDate = endDate }
        if let flowIntensity = flowIntensity { self.flowIntensity = flowIntensity }
        if let symptoms = symptoms { self.symptoms = symptoms }
        if let notes = notes { self.notes = notes }
        self.updatedAt = Date()
    }
}

// MARK: - 症状实体
struct SymptomEntity: Identifiable, Equatable {
    let id: UUID
    var userId: UUID
    var date: Date
    var type: SymptomType
    var severity: Int // 1-5
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date = Date(),
        type: SymptomType,
        severity: Int = 3,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.type = type
        self.severity = max(1, min(5, severity))
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
    }
    
    mutating func update(type: SymptomType? = nil, severity: Int? = nil, notes: String? = nil) {
        if let type = type { self.type = type }
        if let severity = severity { self.severity = max(1, min(5, severity)) }
        if let notes = notes { self.notes = notes }
        self.updatedAt = Date()
    }
}

// MARK: - 枚举类型
enum FlowIntensity: String, CaseIterable, Codable, Identifiable {
    case light = "少量"
    case medium = "中等"
    case heavy = "大量"
    case veryHeavy = "极多"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var colorHex: String {
        switch self {
        case .light: return "#FFB6C1"
        case .medium: return "#FF69B4"
        case .heavy: return "#DC143C"
        case .veryHeavy: return "#8B0000"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "drop"
        case .medium: return "drop.fill"
        case .heavy: return "drop.triangle.fill"
        case .veryHeavy: return "drop.triangle"
        }
    }
}

enum SymptomType: String, CaseIterable, Codable, Identifiable {
    case cramps = "腹痛"
    case headache = "头痛"
    case moodSwings = "情绪波动"
    case bloating = "腹胀"
    case fatigue = "疲劳"
    case acne = "长痘"
    case breastTenderness = "乳房胀痛"
    case backache = "腰酸"
    case appetiteChange = "食欲变化"
    case insomnia = "失眠"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .cramps: return "bolt.fill"
        case .headache: return "brain.head.profile"
        case .moodSwings: return "face.smiling"
        case .bloating: return "stomach"
        case .fatigue: return "bed.double.fill"
        case .acne: return "face.dashed"
        case .breastTenderness: return "heart.fill"
        case .backache: return "figure.2.strengthtraining.traditional"
        case .appetiteChange: return "fork.knife"
        case .insomnia: return "moon.fill"
        }
    }
    
    var defaultSeverity: Int {
        switch self {
        case .cramps, .headache: return 3
        default: return 2
        }
    }
}

enum CyclePhase: String, CaseIterable {
    case menstruation = "经期"
    case follicular = "卵泡期"
    case ovulation = "排卵期"
    case luteal = "黄体期"
    
    var color: String {
        switch self {
        case .menstruation: return "#FF6B6B"
        case .follicular: return "#4ECDC4"
        case .ovulation: return "#FFE66D"
        case .luteal: return "#95E1D3"
        }
    }
    
    var icon: String {
        switch self {
        case .menstruation: return "drop.fill"
        case .follicular: return "sparkles"
        case .ovulation: return "heart.fill"
        case .luteal: return "circle.fill"
        }
    }
}

// MARK: - 预测信息
struct PredictionInfo {
    let nextPeriodStart: Date
    let nextPeriodEnd: Date
    let ovulationDate: Date
    let fertileWindowStart: Date
    let fertileWindowEnd: Date
    let confidence: Double // 0-1, 置信度
    let basedOnCycles: Int
    
    var daysUntilPeriod: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextPeriodStart).day ?? 0
    }
    
    var daysUntilOvulation: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: ovulationDate).day ?? 0
    }
    
    var isWithinFertileWindow: Bool {
        let today = Date()
        return today >= fertileWindowStart && today <= fertileWindowEnd
    }
    
    var isWithinPeriod: Bool {
        let today = Date()
        return today >= nextPeriodStart && today <= nextPeriodEnd
    }
}

// MARK: - 统计数据
struct CycleStatistics {
    let averageCycleLength: Double
    let averagePeriodLength: Double
    let cycleLengthStandardDeviation: Double
    let periodLengthStandardDeviation: Double
    let mostCommonFlowIntensity: FlowIntensity?
    let mostCommonSymptoms: [SymptomType]
    let totalCycles: Int
    let totalSymptoms: Int
    let cycleRegularity: Double // 0-1, 规律程度
    
    var cycleLengthRange: String {
        "\(Int(averageCycleLength - cycleLengthStandardDeviation)) - \(Int(averageCycleLength + cycleLengthStandardDeviation)) 天"
    }
    
    var periodLengthRange: String {
        "\(Int(averagePeriodLength - periodLengthStandardDeviation)) - \(Int(averagePeriodLength + periodLengthStandardDeviation)) 天"
    }
}
