//
//  RepositoryProtocol.swift
//  YueJingJiance
//
//  数据仓库协议 - 基础设施层接口定义
//

import Foundation

// MARK: - 用户数据仓库协议
protocol UserRepositoryProtocol {
    func fetchAllUsers() async throws -> [UserEntity]
    func fetchUser(by id: UUID) async throws -> UserEntity?
    func createUser(_ user: UserEntity) async throws -> UserEntity
    func updateUser(_ user: UserEntity) async throws
    func deleteUser(by id: UUID) async throws
    func softDeleteUser(by id: UUID) async throws
    func fetchActiveUsers() async throws -> [UserEntity]
}

// MARK: - 月经周期数据仓库协议
protocol CycleRepositoryProtocol {
    func fetchCycles(for userId: UUID) async throws -> [MenstrualCycleEntity]
    func fetchCycle(by id: UUID) async throws -> MenstrualCycleEntity?
    func createCycle(_ cycle: MenstrualCycleEntity) async throws -> MenstrualCycleEntity
    func updateCycle(_ cycle: MenstrualCycleEntity) async throws
    func deleteCycle(by id: UUID) async throws
    func softDeleteCycle(by id: UUID) async throws
    func fetchCycles(in dateRange: ClosedRange<Date>, for userId: UUID) async throws -> [MenstrualCycleEntity]
    func fetchRecentCycles(for userId: UUID, limit: Int) async throws -> [MenstrualCycleEntity]
}

// MARK: - 症状数据仓库协议
protocol SymptomRepositoryProtocol {
    func fetchSymptoms(for userId: UUID) async throws -> [SymptomEntity]
    func fetchSymptom(by id: UUID) async throws -> SymptomEntity?
    func createSymptom(_ symptom: SymptomEntity) async throws -> SymptomEntity
    func updateSymptom(_ symptom: SymptomEntity) async throws
    func deleteSymptom(by id: UUID) async throws
    func softDeleteSymptom(by id: UUID) async throws
    func fetchSymptoms(on date: Date, for userId: UUID) async throws -> [SymptomEntity]
    func fetchSymptoms(in dateRange: ClosedRange<Date>, for userId: UUID) async throws -> [SymptomEntity]
    func fetchSymptoms(of type: SymptomType, for userId: UUID) async throws -> [SymptomEntity]
}

// MARK: - 统计数据仓库协议
protocol StatisticsRepositoryProtocol {
    func fetchCycleStatistics(for userId: UUID) async throws -> CycleStatistics
    func fetchPhaseDistribution(for userId: UUID, in dateRange: ClosedRange<Date>) async throws -> [CyclePhase: Int]
    func fetchSymptomFrequency(for userId: UUID, in dateRange: ClosedRange<Date>) async throws -> [SymptomType: Int]
    func fetchCycleTrend(for userId: UUID, limit: Int) async throws -> [Double]
}

// MARK: - 设置数据仓库协议
protocol SettingsRepositoryProtocol {
    func getSelectedUserId() async -> UUID?
    func setSelectedUserId(_ userId: UUID) async
    func getNotificationSettings() async -> NotificationSettings
    func setNotificationSettings(_ settings: NotificationSettings) async
    func getPrivacySettings() async -> PrivacySettings
    func setPrivacySettings(_ settings: PrivacySettings) async
}

// MARK: - 通知设置
struct NotificationSettings: Codable {
    var enabled: Bool
    var periodReminder: Bool
    var ovulationReminder: Bool
    var reminderDaysBefore: Int
    var reminderTime: Date
    
    init(enabled: Bool = true, periodReminder: Bool = true, ovulationReminder: Bool = false, 
         reminderDaysBefore: Int = 1, reminderTime: Date = Date()) {
        self.enabled = enabled
        self.periodReminder = periodReminder
        self.ovulationReminder = ovulationReminder
        self.reminderDaysBefore = reminderDaysBefore
        self.reminderTime = reminderTime
    }
}

// MARK: - 隐私设置
struct PrivacySettings: Codable {
    var enableAppLock: Bool
    var lockType: LockType
    var autoLockDelay: Int // 秒
    
    enum LockType: String, Codable, CaseIterable {
        case none = "无"
        case passcode = "密码"
        case faceID = "面容 ID"
        case touchID = "触控 ID"
    }
    
    init(enableAppLock: Bool = false, lockType: LockType = .none, autoLockDelay: Int = 300) {
        self.enableAppLock = enableAppLock
        self.lockType = lockType
        self.autoLockDelay = autoLockDelay
    }
}
