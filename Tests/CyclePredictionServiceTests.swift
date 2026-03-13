//
//  CyclePredictionServiceTests.swift
//  YueJingJianceTests
//
//  预测服务单元测试
//

import XCTest
@testable import YueJingJiance

final class CyclePredictionServiceTests: XCTestCase {
    
    private var service: CyclePredictionService!
    
    override func setUp() {
        super.setUp()
        service = CyclePredictionService.shared
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - 预测下次周期测试
    func testPredictNextCycle_WithSufficientData() async throws {
        // 准备测试数据
        let userId = UUID()
        let cycles = generateTestCycles(userId: userId, count: 5)
        
        let user = UserEntity(id: userId, cycleLength: 28, periodLength: 5)
        
        // 执行预测
        let prediction = await service.predictNextCycle(for: user, basedOn: cycles)
        
        // 验证预测结果
        XCTAssertNotNil(prediction, "应该有预测结果")
        XCTAssertGreaterThan(prediction!.confidence, 0.5, "置信度应该大于 0.5")
        XCTAssertGreaterThan(prediction!.daysUntilPeriod, 0, "距离下次月经应该大于 0 天")
    }
    
    func testPredictNextCycle_WithInsufficientData() async throws {
        let userId = UUID()
        let cycles: [MenstrualCycleEntity] = []
        
        let user = UserEntity(id: userId)
        
        let prediction = await service.predictNextCycle(for: user, basedOn: cycles)
        
        XCTAssertNil(prediction, "数据不足时应该返回 nil")
    }
    
    // MARK: - 周期阶段计算测试
    func testCalculateCurrentPhase_Menstruation() async throws {
        let userId = UUID()
        let startDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let cycles = [MenstrualCycleEntity(userId: userId, startDate: startDate)]
        
        let user = UserEntity(id: userId, cycleLength: 28, periodLength: 5)
        
        let phase = await service.calculateCurrentPhase(for: user, on: Date(), basedOn: cycles)
        
        XCTAssertEqual(phase, .menstruation, "应该处于经期")
    }
    
    func testCalculateCurrentPhase_Ovulation() async throws {
        let userId = UUID()
        // 假设周期第 14 天左右是排卵期
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let cycles = [MenstrualCycleEntity(userId: userId, startDate: startDate)]
        
        let user = UserEntity(id: userId, cycleLength: 28, periodLength: 5)
        
        let phase = await service.calculateCurrentPhase(for: user, on: Date(), basedOn: cycles)
        
        XCTAssertEqual(phase, .ovulation, "应该处于排卵期")
    }
    
    // MARK: - 统计计算测试
    func testCalculateCycleStatistics() async throws {
        let userId = UUID()
        let cycles = generateTestCycles(userId: userId, count: 10)
        
        let statistics = await service.calculateCycleStatistics(for: cycles)
        
        XCTAssertGreaterThan(statistics.totalCycles, 0, "应该有周期统计")
        XCTAssertGreaterThan(statistics.averageCycleLength, 0, "平均周期长度应该大于 0")
        XCTAssertGreaterThanOrEqual(statistics.cycleRegularity, 0, "规律性应该 >= 0")
        XCTAssertLessThanOrEqual(statistics.cycleRegularity, 1, "规律性应该 <= 1")
    }
    
    // MARK: - 生育状态测试
    func testEstimateFertilityStatus() async throws {
        let userId = UUID()
        let cycles = generateTestCycles(userId: userId, count: 5)
        let user = UserEntity(id: userId)
        
        let status = await service.estimateFertilityStatus(for: Date(), basedOn: user, cycles: cycles)
        
        XCTAssertNotNil(status, "应该有生育状态")
    }
    
    // MARK: - 辅助方法
    private func generateTestCycles(userId: UUID, count: Int) -> [MenstrualCycleEntity] {
        var cycles: [MenstrualCycleEntity] = []
        var currentDate = Calendar.current.date(byAdding: .month, value: -count, to: Date())!
        
        for _ in 0..<count {
            let endDate = Calendar.current.date(byAdding: .day, value: 5, from: currentDate)!
            let cycle = MenstrualCycleEntity(
                userId: userId,
                startDate: currentDate,
                endDate: endDate,
                flowIntensity: .medium
            )
            cycles.append(cycle)
            currentDate = Calendar.current.date(byAdding: .day, value: 28, from: currentDate)!
        }
        
        return cycles
    }
}

// MARK: - FlowIntensity 测试
final class FlowIntensityTests: XCTestCase {
    
    func testFlowIntensityAllCases() {
        let intensities = FlowIntensity.allCases
        
        XCTAssertEqual(intensities.count, 4, "应该有 4 种经血量等级")
        XCTAssertTrue(intensities.contains { $0 == .light })
        XCTAssertTrue(intensities.contains { $0 == .medium })
        XCTAssertTrue(intensities.contains { $0 == .heavy })
        XCTAssertTrue(intensities.contains { $0 == .veryHeavy })
    }
    
    func testFlowIntensityColorHex() {
        XCTAssertEqual(FlowIntensity.light.colorHex, "#FFB6C1")
        XCTAssertEqual(FlowIntensity.medium.colorHex, "#FF69B4")
        XCTAssertEqual(FlowIntensity.heavy.colorHex, "#DC143C")
        XCTAssertEqual(FlowIntensity.veryHeavy.colorHex, "#8B0000")
    }
}

// MARK: - SymptomType 测试
final class SymptomTypeTests: XCTestCase {
    
    func testSymptomTypeAllCases() {
        let types = SymptomType.allCases
        
        XCTAssertGreaterThanOrEqual(types.count, 7, "应该至少有 7 种症状类型")
    }
    
    func testSymptomTypeIcon() {
        XCTAssertEqual(SymptomType.cramps.icon, "bolt.fill")
        XCTAssertEqual(SymptomType.headache.icon, "brain.head.profile")
        XCTAssertEqual(SymptomType.fatigue.icon, "bed.double.fill")
    }
}
