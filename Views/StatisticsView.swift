//
//  StatisticsView.swift
//  YueJingJiance
//
//  统计图表视图 - 使用 SwiftUI 绘制
//

import SwiftUI
import Charts

// MARK: - 统计总览视图
struct StatisticsOverviewView: View {
    @ObservedObject var viewModel: StatisticsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 周期概览卡片
                cycleOverviewCard
                
                // 周期长度趋势图
                if viewModel.hasEnoughData {
                    cycleTrendChart
                    
                    // 周期分布图
                    phaseDistributionChart
                } else {
                    emptyStateView
                }
                
                // 症状统计
                symptomStatisticsCard
                
                // 规律性评分
                regularityScoreCard
            }
            .padding()
        }
        .navigationTitle("统计分析")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                await viewModel.loadStatistics()
            }
        }
    }
    
    // MARK: - 周期概览卡片
    private var cycleOverviewCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("周期概览")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatisticItem(
                    icon: "calendar",
                    value: "\(Int(viewModel.statistics?.averageCycleLength ?? 28))",
                    label: "平均周期",
                    subLabel: "天"
                )
                
                StatisticItem(
                    icon: "drop.fill",
                    value: "\(Int(viewModel.statistics?.averagePeriodLength ?? 5))",
                    label: "平均经期",
                    subLabel: "天"
                )
                
                StatisticItem(
                    icon: "chart.bar",
                    value: "\(viewModel.statistics?.totalCycles ?? 0)",
                    label: "记录周期",
                    subLabel: "次"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 周期趋势图
    private var cycleTrendChart: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("周期长度趋势")
                .font(.headline)
            
            if let chartData = viewModel.cycleTrendData {
                Chart(chartData) { item in
                    LineMark(
                        x: .value("周期数", item.index),
                        y: .value("天数", item.length)
                    )
                    .foregroundStyle(by: .value("趋势", item.length))
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("周期数", item.index),
                        y: .value("天数", item.length)
                    )
                }
                .chartXScale(domain: 0...max(chartData.count - 1, 1))
                .frame(height: 200)
            }
            
            if let stats = viewModel.statistics {
                Text("波动范围：\(stats.cycleLengthRange)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 周期阶段分布图
    private var phaseDistributionChart: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("阶段分布（近 3 个月）")
                .font(.headline)
            
            if let phaseData = viewModel.phaseDistributionData {
                HStack(spacing: 15) {
                    ForEach(phaseData, id: \.key) { phase, count in
                        PhaseIndicator(phase: phase, count: count, total: phaseData.values.reduce(0, +))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 症状统计卡片
    private var symptomStatisticsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("症状统计")
                    .font(.headline)
                Spacer()
                Text("最近 3 个月")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if viewModel.symptomFrequencyData.isEmpty {
                Text("暂无症状记录")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(viewModel.symptomFrequencyData.prefix(5), id: \.key) { type, count in
                    SymptomStatRow(type: type, count: count)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 规律性评分卡片
    private var regularityScoreCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("周期规律性")
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(Int((viewModel.statistics?.cycleRegularity ?? 0) * 100)) 分")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                    Text("满分 100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: viewModel.statistics?.cycleRegularity ?? 0)
                .progressViewStyle(LinearProgressViewStyle(tint: .pink))
                .frame(height: 8)
            
            Text(regularityDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 规律性描述
    private var regularityDescription: String {
        guard let regularity = viewModel.statistics?.cycleRegularity else { return "暂无足够数据" }
        
        if regularity >= 0.9 {
            return "您的周期非常规律，请继续保持健康的生活方式！"
        } else if regularity >= 0.7 {
            return "您的周期较为规律，属于正常范围。"
        } else if regularity >= 0.5 {
            return "您的周期有一定波动，建议关注生活习惯。"
        } else {
            return "您的周期波动较大，如有不适请咨询医生。"
        }
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("暂无足够数据")
                .font(.headline)
            
            Text("记录至少 3 个周期后\n将显示详细的统计分析")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - 统计项组件
struct StatisticItem: View {
    let icon: String
    let value: String
    let label: String
    let subLabel: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.pink)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(subLabel)
                .font(.caption2)
                .foregroundColor(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 阶段指示器组件
struct PhaseIndicator: View {
    let phase: CyclePhase
    let count: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text(phase.rawValue)
                .font(.caption)
            
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("\(Int(Double(count) / Double(total) * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(hex: phase.color))
        .cornerRadius(8)
    }
}

// MARK: - 症状统计行组件
struct SymptomStatRow: View {
    let type: SymptomType
    let count: Int
    
    var body: some View {
        HStack {
            Image(systemName: type.icon)
                .foregroundColor(.pink)
                .frame(width: 24)
            
            Text(type.rawValue)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count) 次")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 颜色扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 统计图表数据模型
struct CycleTrendItem: Identifiable, ChartDataEntry {
    let id = UUID()
    let index: Int
    let length: Double
}

// MARK: - 统计 ViewModel
final class StatisticsViewModel: ObservableObject {
    
    private let cycleRepository: CycleRepositoryProtocol
    private let statisticsRepository: StatisticsRepositoryProtocol
    private let predictionService: PredictionServiceProtocol
    
    @Published var statistics: CycleStatistics?
    @Published var cycleTrendData: [CycleTrendItem]?
    @Published var phaseDistributionData: [CyclePhase: Int]?
    @Published var symptomFrequencyData: [SymptomType: Int]?
    @Published var isLoading = false
    
    var hasEnoughData: Bool {
        statistics?.totalCycles ?? 0 >= 3
    }
    
    init(
        cycleRepository: CycleRepositoryProtocol,
        statisticsRepository: StatisticsRepositoryProtocol,
        predictionService: PredictionServiceProtocol = CyclePredictionService.shared
    ) {
        self.cycleRepository = cycleRepository
        self.statisticsRepository = statisticsRepository
        self.predictionService = predictionService
    }
    
    func loadStatistics() async {
        isLoading = true
        defer { isLoading = false }
        
        // 这里需要从当前用户加载数据
        // 简化处理，使用模拟数据
    }
}

// MARK: - 图表数据协议
protocol ChartDataEntry: Identifiable {
    var id: UUID { get }
}
