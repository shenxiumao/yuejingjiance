//
//  UserEntityTests.swift
//  YueJingJianceTests
//
//  用户实体单元测试
//

import XCTest
@testable import YueJingJiance

final class UserEntityTests: XCTestCase {
    
    func testUserInitialization() {
        let user = UserEntity(name: "测试用户", cycleLength: 30, periodLength: 6)
        
        XCTAssertEqual(user.name, "测试用户")
        XCTAssertEqual(user.cycleLength, 30)
        XCTAssertEqual(user.periodLength, 6)
        XCTAssertNotNil(user.id)
        XCTAssertFalse(user.isDeleted)
    }
    
    func testUserUpdate() {
        var user = UserEntity()
        
        user.update(name: "新名字", cycleLength: 25)
        
        XCTAssertEqual(user.name, "新名字")
        XCTAssertEqual(user.cycleLength, 25)
    }
    
    func testUserEquality() {
        let user1 = UserEntity(id: UUID(), name: "用户")
        let user2 = UserEntity(id: user1.id, name: "用户")
        let user3 = UserEntity(name: "用户")
        
        XCTAssertEqual(user1, user2)
        XCTAssertNotEqual(user1, user3)
    }
}

// MARK: - MenstrualCycleEntity 测试
final class MenstrualCycleEntityTests: XCTestCase {
    
    func testCycleInitialization() {
        let userId = UUID()
        let cycle = MenstrualCycleEntity(
            userId: userId,
            startDate: Date(),
            flowIntensity: .heavy
        )
        
        XCTAssertEqual(cycle.userId, userId)
        XCTAssertEqual(cycle.flowIntensity, .heavy)
        XCTAssertNotNil(cycle.id)
    }
    
    func testCycleDuration_WithEndDate() {
        let userId = UUID()
        let startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let endDate = Date()
        
        let cycle = MenstrualCycleEntity(
            userId: userId,
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertEqual(cycle.duration, 5)
    }
    
    func testCycleDuration_WithoutEndDate() {
        let userId = UUID()
        let startDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        
        let cycle = MenstrualCycleEntity(
            userId: userId,
            startDate: startDate,
            endDate: nil
        )
        
        XCTAssertEqual(cycle.duration, 3)
    }
    
    func testCycleUpdate() {
        let userId = UUID()
        var cycle = MenstrualCycleEntity(userId: userId, startDate: Date())
        
        let newEndDate = Date()
        cycle.update(endDate: newEndDate, flowIntensity: .light)
        
        XCTAssertEqual(cycle.endDate, newEndDate)
        XCTAssertEqual(cycle.flowIntensity, .light)
    }
}

// MARK: - SymptomEntity 测试
final class SymptomEntityTests: XCTestCase {
    
    func testSymptomInitialization() {
        let userId = UUID()
        let symptom = SymptomEntity(
            userId: userId,
            type: .cramps,
            severity: 4
        )
        
        XCTAssertEqual(symptom.userId, userId)
        XCTAssertEqual(symptom.type, .cramps)
        XCTAssertEqual(symptom.severity, 4)
    }
    
    func testSymptomSeverityClamping() {
        let userId = UUID()
        
        // 测试最小值
        let symptom1 = SymptomEntity(userId: userId, type: .cramps, severity: -1)
        XCTAssertEqual(symptom1.severity, 1)
        
        // 测试最大值
        let symptom2 = SymptomEntity(userId: userId, type: .cramps, severity: 10)
        XCTAssertEqual(symptom2.severity, 5)
    }
    
    func testSymptomUpdate() {
        let userId = UUID()
        var symptom = SymptomEntity(userId: userId, type: .cramps, severity: 3)
        
        symptom.update(type: .headache, severity: 5)
        
        XCTAssertEqual(symptom.type, .headache)
        XCTAssertEqual(symptom.severity, 5)
    }
}

// MARK: - CycleStatistics 测试
final class CycleStatisticsTests: XCTestCase {
    
    func testCycleStatisticsRange() {
        let stats = CycleStatistics(
            averageCycleLength: 28,
            averagePeriodLength: 5,
            cycleLengthStandardDeviation: 2,
            periodLengthStandardDeviation: 1,
            mostCommonFlowIntensity: .medium,
            mostCommonSymptoms: [],
            totalCycles: 10,
            totalSymptoms: 20,
            cycleRegularity: 0.85
        )
        
        XCTAssertEqual(stats.cycleLengthRange, "26 - 30 天")
        XCTAssertEqual(stats.periodLengthRange, "4 - 6 天")
    }
}

// MARK: - PredictionInfo 测试
final class PredictionInfoTests: XCTestCase {
    
    func testPredictionInfoDaysCalculation() {
        let now = Date()
        let nextPeriod = Calendar.current.date(byAdding: .day, value: 14, to: now)!
        let ovulation = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let fertileStart = Calendar.current.date(byAdding: .day, value: 2, to: now)!
        let fertileEnd = Calendar.current.date(byAdding: .day, value: 8, to: now)!
        
        let prediction = PredictionInfo(
            nextPeriodStart: nextPeriod,
            nextPeriodEnd: nextPeriod,
            ovulationDate: ovulation,
            fertileWindowStart: fertileStart,
            fertileWindowEnd: fertileEnd,
            confidence: 0.8,
            basedOnCycles: 5
        )
        
        XCTAssertEqual(prediction.daysUntilPeriod, 14)
        XCTAssertEqual(prediction.daysUntilOvulation, 7)
        XCTAssertTrue(prediction.isWithinFertileWindow)
    }
}
