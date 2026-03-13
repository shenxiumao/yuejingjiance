//
//  HomeViewModel.swift
//  YueJingJiance
//
//  首页 ViewModel - MVVM 模式
//

import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    
    // MARK: - 依赖注入
    private let cycleRepository: CycleRepositoryProtocol
    private let symptomRepository: SymptomRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol
    private let predictionService: PredictionServiceProtocol
    
    // MARK: - 状态属性
    @Published var currentUser: UserEntity?
    @Published var users: [UserEntity] = []
    @Published var currentPhase: CyclePhase = .follicular
    @Published var predictionInfo: PredictionInfo?
    @Published var statistics: CycleStatistics?
    @Published var todaySymptoms: [SymptomEntity] = []
    @Published var recentCycles: [MenstrualCycleEntity] = []
    @Published var isLoading = false
    @Published var showError: String?
    
    // MARK: - 组合订阅
    private var cancellables = Set<AnyCancellable>()
    private var userId: UUID?
    
    // MARK: - 初始化
    init(
        cycleRepository: CycleRepositoryProtocol,
        symptomRepository: SymptomRepositoryProtocol,
        settingsRepository: SettingsRepositoryProtocol,
        predictionService: PredictionServiceProtocol = CyclePredictionService.shared
    ) {
        self.cycleRepository = cycleRepository
        self.symptomRepository = symptomRepository
        self.settingsRepository = settingsRepository
        self.predictionService = predictionService
        
        setupBindings()
        loadInitialData()
    }
    
    // MARK: - 设置绑定
    private func setupBindings() {
        // 监听用户变化
        settingsRepository.getSelectedUserId()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userId in
                self?.userId = userId
                self?.loadUserData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 加载初始数据
    private func loadInitialData() {
        Task {
            await loadUsers()
            if let userId = await settingsRepository.getSelectedUserId() {
                self.userId = userId
                await loadUserData()
            }
        }
    }
    
    // MARK: - 加载用户列表
    func loadUsers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            users = try await cycleRepository.fetchCycles(for: UUID()).isEmpty ? [] : []
        } catch {
            showError = "加载用户失败：\(error.localizedDescription)"
        }
    }
    
    // MARK: - 加载用户数据
    private func loadUserData() async {
        guard let userId = userId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 加载用户信息
            if let user = try await cycleRepository.fetchCycles(for: userId).isEmpty ? nil : nil {
                // 需要从用户仓库获取
            }
            
            // 加载周期数据
            let cycles = try await cycleRepository.fetchRecentCycles(for: userId, limit: 10)
            DispatchQueue.main.async {
                self.recentCycles = cycles
            }
            
            // 加载今日症状
            let symptoms = try await symptomRepository.fetchSymptoms(on: Date(), for: userId)
            DispatchQueue.main.async {
                self.todaySymptoms = symptoms
            }
            
            // 计算当前阶段
            if let firstCycle = cycles.sorted(by: { $0.startDate > $1.startDate }).first {
                let phase = await predictionService.calculateCurrentPhase(
                    for: UserEntity(id: userId),
                    on: Date(),
                    basedOn: cycles
                )
                DispatchQueue.main.async {
                    self.currentPhase = phase
                }
                
                // 计算预测信息
                let prediction = await predictionService.predictNextCycle(
                    for: UserEntity(id: userId),
                    basedOn: cycles
                )
                DispatchQueue.main.async {
                    self.predictionInfo = prediction
                }
                
                // 计算统计数据
                let stats = await predictionService.calculateCycleStatistics(for: cycles)
                DispatchQueue.main.async {
                    self.statistics = stats
                }
            }
        } catch {
            showError = "加载数据失败：\(error.localizedDescription)"
        }
    }
    
    // MARK: - 切换用户
    func switchUser(to user: UserEntity) async {
        await settingsRepository.setSelectedUserId(user.id)
        userId = user.id
        await loadUserData()
    }
    
    // MARK: - 记录月经
    func recordPeriod(startDate: Date, endDate: Date?, flow: FlowIntensity, notes: String = "") async -> Bool {
        guard let userId = userId else { return false }
        
        let cycle = MenstrualCycleEntity(
            userId: userId,
            startDate: startDate,
            endDate: endDate,
            flowIntensity: flow,
            notes: notes
        )
        
        do {
            _ = try await cycleRepository.createCycle(cycle)
            await loadUserData()
            return true
        } catch {
            showError = "记录失败：\(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - 记录症状
    func recordSymptom(date: Date, type: SymptomType, severity: Int, notes: String = "") async -> Bool {
        guard let userId = userId else { return false }
        
        let symptom = SymptomEntity(
            userId: userId,
            date: date,
            type: type,
            severity: severity,
            notes: notes
        )
        
        do {
            _ = try await symptomRepository.createSymptom(symptom)
            await loadUserData()
            return true
        } catch {
            showError = "记录失败：\(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - 删除周期
    func deleteCycle(_ cycle: MenstrualCycleEntity) async {
        guard let userId = userId else { return }
        
        do {
            try await cycleRepository.deleteCycle(by: cycle.id)
            await loadUserData()
        } catch {
            showError = "删除失败：\(error.localizedDescription)"
        }
    }
    
    // MARK: - 删除症状
    func deleteSymptom(_ symptom: SymptomEntity) async {
        guard let userId = userId else { return }
        
        do {
            try await symptomRepository.deleteSymptom(by: symptom.id)
            await loadUserData()
        } catch {
            showError = "删除失败：\(error.localizedDescription)"
        }
    }
    
    // MARK: - 格式化日期
    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    // MARK: - 获取天数差
    func daysBetween(_ from: Date, _ to: Date) -> Int {
        Calendar.current.dateComponents([.day], from: from, to: to).day ?? 0
    }
}

// MARK: - 模拟数据仓库（用于开发测试）
final class MockCycleRepository: CycleRepositoryProtocol {
    
    private var cycles: [MenstrualCycleEntity] = []
    
    func fetchCycles(for userId: UUID) async throws -> [MenstrualCycleEntity] {
        return cycles.filter { $0.userId == userId && !$0.isDeleted }
    }
    
    func fetchCycle(by id: UUID) async throws -> MenstrualCycleEntity? {
        return cycles.first { $0.id == id && !$0.isDeleted }
    }
    
    func createCycle(_ cycle: MenstrualCycleEntity) async throws -> MenstrualCycleEntity {
        cycles.append(cycle)
        return cycle
    }
    
    func updateCycle(_ cycle: MenstrualCycleEntity) async throws {
        if let index = cycles.firstIndex(where: { $0.id == cycle.id }) {
            cycles[index] = cycle
        }
    }
    
    func deleteCycle(by id: UUID) async throws {
        cycles.removeAll { $0.id == id }
    }
    
    func softDeleteCycle(by id: UUID) async throws {
        if let index = cycles.firstIndex(where: { $0.id == id }) {
            cycles[index].isDeleted = true
        }
    }
    
    func fetchCycles(in dateRange: ClosedRange<Date>, for userId: UUID) async throws -> [MenstrualCycleEntity] {
        return cycles.filter {
            $0.userId == userId &&
            !$0.isDeleted &&
            $0.startDate >= dateRange.lowerBound &&
            $0.startDate <= dateRange.upperBound
        }
    }
    
    func fetchRecentCycles(for userId: UUID, limit: Int) async throws -> [MenstrualCycleEntity] {
        return cycles
            .filter { $0.userId == userId && !$0.isDeleted }
            .sorted { $0.startDate > $1.startDate }
            .prefix(limit)
            .map { $0 }
    }
}

final class MockSymptomRepository: SymptomRepositoryProtocol {
    
    private var symptoms: [SymptomEntity] = []
    
    func fetchSymptoms(for userId: UUID) async throws -> [SymptomEntity] {
        return symptoms.filter { $0.userId == userId && !$0.isDeleted }
    }
    
    func fetchSymptom(by id: UUID) async throws -> SymptomEntity? {
        return symptoms.first { $0.id == id && !$0.isDeleted }
    }
    
    func createSymptom(_ symptom: SymptomEntity) async throws -> SymptomEntity {
        symptoms.append(symptom)
        return symptom
    }
    
    func updateSymptom(_ symptom: SymptomEntity) async throws {
        if let index = symptoms.firstIndex(where: { $0.id == symptom.id }) {
            symptoms[index] = symptom
        }
    }
    
    func deleteSymptom(by id: UUID) async throws {
        symptoms.removeAll { $0.id == id }
    }
    
    func softDeleteSymptom(by id: UUID) async throws {
        if let index = symptoms.firstIndex(where: { $0.id == id }) {
            symptoms[index].isDeleted = true
        }
    }
    
    func fetchSymptoms(on date: Date, for userId: UUID) async throws -> [SymptomEntity] {
        return symptoms.filter {
            $0.userId == userId &&
            !$0.isDeleted &&
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func fetchSymptoms(in dateRange: ClosedRange<Date>, for userId: UUID) async throws -> [SymptomEntity] {
        return symptoms.filter {
            $0.userId == userId &&
            !$0.isDeleted &&
            $0.date >= dateRange.lowerBound &&
            $0.date <= dateRange.upperBound
        }
    }
    
    func fetchSymptoms(of type: SymptomType, for userId: UUID) async throws -> [SymptomEntity] {
        return symptoms.filter {
            $0.userId == userId &&
            !$0.isDeleted &&
            $0.type == type
        }
    }
}
