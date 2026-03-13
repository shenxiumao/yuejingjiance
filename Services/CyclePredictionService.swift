//
//  CyclePredictionService.swift
//  YueJingJiance
//
//  智能预测服务 - 使用统计算法进行周期预测
//

import Foundation

// MARK: - 预测服务协议
protocol PredictionServiceProtocol {
    func predictNextCycle(for user: UserEntity, basedOn cycles: [MenstrualCycleEntity]) async -> PredictionInfo?
    func calculateCurrentPhase(for user: UserEntity, on date: Date, basedOn cycles: [MenstrualCycleEntity]) async -> CyclePhase
    func calculateCycleStatistics(for cycles: [MenstrualCycleEntity]) async -> CycleStatistics
    func estimateFertilityStatus(for date: Date, basedOn user: UserEntity, cycles: [MenstrualCycleEntity]) async -> FertilityStatus
}

// MARK: - 生育状态
enum FertilityStatus: String {
    case low = "低"
    case medium = "中"
    case high = "高"
    case peak = "峰值"
    
    var color: String {
        switch self {
        case .low: return "#95A5A6"
        case .medium: return "#F39C12"
        case .high: return "#E74C3C"
        case .peak: return "#C0392B"
        }
    }
}

// MARK: - 预测服务实现
final class CyclePredictionService: PredictionServiceProtocol {
    
    static let shared = CyclePredictionService()
    
    private init() {}
    
    // MARK: - 预测下次周期
    func predictNextCycle(for user: UserEntity, basedOn cycles: [MenstrualCycleEntity]) async -> PredictionInfo? {
        guard let lastCycle = cycles
                .filter { !$0.isPredicted }
                .sorted { $0.startDate > $1.startDate }
                .first else {
            return nil
        }
        
        // 计算平均周期长度（使用加权平均，最近的周期权重更高）
        let sortedCycles = cycles
            .filter { !$0.isPredicted && $0.endDate != nil }
            .sorted { $0.startDate > $1.startDate }
        
        let averageCycleLength: Int
        let confidence: Double
        
        if sortedCycles.count >= 3 {
            // 使用最近 3-6 个周期的加权平均
            let recentCycles = Array(sortedCycles.prefix(6))
            let weights = recentCycles.indices.map { Double($0 + 1) }
            let totalWeight = weights.reduce(0, +)
            
            let weightedSum = zip(recentCycles, weights).reduce(0.0) { sum, element in
                let cycleLength = Calendar.current.dateComponents([.day], 
                    from: element.0.startDate, 
                    to: element.0.endDate ?? Date()).day ?? 28
                return sum + Double(cycleLength) * element.1
            }
            
            averageCycleLength = Int(weightedSum / totalWeight)
            confidence = min(0.95, 0.5 + Double(sortedCycles.count) * 0.1)
        } else {
            averageCycleLength = user.cycleLength
            confidence = 0.5
        }
        
        // 计算下次月经开始日期
        let nextPeriodStart = Calendar.current.date(
            byAdding: .day, 
            value: averageCycleLength, 
            from: lastCycle.startDate
        ) ?? Date()
        
        // 计算经期结束日期（使用平均经期长度）
        let nextPeriodEnd = Calendar.current.date(
            byAdding: .day, 
            value: user.periodLength, 
            from: nextPeriodStart
        ) ?? Date()
        
        // 计算排卵日（通常在下次月经前 14 天）
        let ovulationDate = Calendar.current.date(
            byAdding: .day, 
            value: -14, 
            from: nextPeriodStart
        ) ?? Date()
        
        // 计算易孕期（排卵日前 5 天到排卵后 1 天）
        let fertileWindowStart = Calendar.current.date(
            byAdding: .day, 
            value: -5, 
            from: ovulationDate
        ) ?? Date()
        
        let fertileWindowEnd = Calendar.current.date(
            byAdding: .day, 
            value: 1, 
            from: ovulationDate
        ) ?? Date()
        
        return PredictionInfo(
            nextPeriodStart: nextPeriodStart,
            nextPeriodEnd: nextPeriodEnd,
            ovulationDate: ovulationDate,
            fertileWindowStart: fertileWindowStart,
            fertileWindowEnd: fertileWindowEnd,
            confidence: confidence,
            basedOnCycles: sortedCycles.count
        )
    }
    
    // MARK: - 计算当前周期阶段
    func calculateCurrentPhase(for user: UserEntity, on date: Date, basedOn cycles: [MenstrualCycleEntity]) async -> CyclePhase {
        guard let lastPeriodStart = cycles
                .filter { !$0.isPredicted }
                .sorted { $0.startDate > $1.startDate }
                .first?.startDate else {
            return .follicular
        }
        
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriodStart, to: date).day ?? 0
        let cycleLength = user.cycleLength
        
        // 经期（第 1-5 天）
        if daysSinceLastPeriod < user.periodLength {
            return .menstruation
        }
        
        // 排卵期（第 12-16 天，假设 28 天周期）
        let ovulationDay = cycleLength - 14
        let ovulationWindow = 4 // ±2 天
        if abs(daysSinceLastPeriod - ovulationDay) <= ovulationWindow {
            return .ovulation
        }
        
        // 卵泡期（经期结束到排卵期前）
        if daysSinceLastPeriod < ovulationDay - ovulationWindow {
            return .follicular
        }
        
        // 黄体期（排卵期后到下次月经）
        return .luteal
    }
    
    // MARK: - 计算周期统计
    func calculateCycleStatistics(for cycles: [MenstrualCycleEntity]) async -> CycleStatistics {
        let validCycles = cycles.filter { !$0.isPredicted && $0.endDate != nil }
        
        guard !validCycles.isEmpty else {
            return CycleStatistics(
                averageCycleLength: 28,
                averagePeriodLength: 5,
                cycleLengthStandardDeviation: 0,
                periodLengthStandardDeviation: 0,
                mostCommonFlowIntensity: nil,
                mostCommonSymptoms: [],
                totalCycles: cycles.count,
                totalSymptoms: 0,
                cycleRegularity: 0
            )
        }
        
        // 计算周期长度
        let cycleLengths = validCycles.map { cycle in
            Calendar.current.dateComponents([.day], from: cycle.startDate, to: cycle.endDate!).day ?? 28
        }
        
        let averageCycleLength = cycleLengths.reduce(0, +) / cycleLengths.count
        let cycleLengthVariance = cycleLengths.map { pow(Double($0 - averageCycleLength), 2) }.reduce(0, +) / Double(cycleLengths.count)
        let cycleLengthStandardDeviation = sqrt(cycleLengthVariance)
        
        // 计算经期长度
        let periodLengths = validCycles.compactMap { cycle in
            cycle.endDate.map { Calendar.current.dateComponents([.day], from: cycle.startDate, to: $0).day ?? 5 }
        }
        
        let averagePeriodLength = periodLengths.isEmpty ? 5 : periodLengths.reduce(0, +) / periodLengths.count
        let periodLengthVariance = periodLengths.map { pow(Double($0 - averagePeriodLength), 2) }.reduce(0, +) / Double(periodLengths.count)
        let periodLengthStandardDeviation = sqrt(periodLengthVariance)
        
        // 最常见的经血量
        let flowIntensities = validCycles.map { $0.flowIntensity }
        let flowCounts = Dictionary(grouping: flowIntensities, by: { $0 }).mapValues { $0.count }
        let mostCommonFlowIntensity = flowCounts.max(by: { $0.value < $1.value })?.key
        
        // 最常见的症状（简化处理）
        let mostCommonSymptoms: [SymptomType] = []
        
        // 周期规律程度（基于标准差）
        let cycleRegularity: Double
        if cycleLengthStandardDeviation <= 2 {
            cycleRegularity = 0.95
        } else if cycleLengthStandardDeviation <= 5 {
            cycleRegularity = 0.7
        } else if cycleLengthStandardDeviation <= 7 {
            cycleRegularity = 0.5
        } else {
            cycleRegularity = 0.3
        }
        
        return CycleStatistics(
            averageCycleLength: Double(averageCycleLength),
            averagePeriodLength: Double(averagePeriodLength),
            cycleLengthStandardDeviation: cycleLengthStandardDeviation,
            periodLengthStandardDeviation: periodLengthStandardDeviation,
            mostCommonFlowIntensity: mostCommonFlowIntensity,
            mostCommonSymptoms: mostCommonSymptoms,
            totalCycles: validCycles.count,
            totalSymptoms: 0,
            cycleRegularity: cycleRegularity
        )
    }
    
    // MARK: - 估算生育状态
    func estimateFertilityStatus(for date: Date, basedOn user: UserEntity, cycles: [MenstrualCycleEntity]) async -> FertilityStatus {
        guard let prediction = await predictNextCycle(for: user, basedOn: cycles) else {
            return .low
        }
        
        // 检查是否在易孕期
        if date >= prediction.fertileWindowStart && date <= prediction.fertileWindowEnd {
            // 检查是否是排卵日
            let daysFromOvulation = Calendar.current.dateComponents([.day], from: prediction.ovulationDate, to: date).day ?? 0
            if abs(daysFromOvulation) <= 1 {
                return .peak
            }
            return .high
        }
        
        // 易孕期前 2 天
        let twoDaysBeforeFertile = Calendar.current.date(byAdding: .day, value: -2, from: prediction.fertileWindowStart) ?? Date()
        if date >= twoDaysBeforeFertile {
            return .medium
        }
        
        return .low
    }
}
