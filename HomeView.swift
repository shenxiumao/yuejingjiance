import SwiftUI

struct HomeView: View {
    @ObservedObject var cycleManager: CycleManager
    @State private var showingUserPicker = false
    @State private var showingPeriodOptions = false
    @State private var showingSymptomOptions = false
    @State private var selectedFlow: FlowIntensity = .medium
    @State private var selectedSymptomType: SymptomType = .cramps
    @State private var selectedSeverity: Int = 3
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 用户选择器
                    userSelectorCard
                    
                    // 当前状态卡片
                    currentStatusCard
                    
                    // 预测信息卡片
                    predictionCard
                    
                    // 快速操作
                    quickActionsCard
                    
                    // 最近记录
                    recentRecordsCard
                }
                .padding()
            }
            .navigationTitle("月经助手")
            .background(Color(.systemGroupedBackground))
        }
        .confirmationDialog("记录月经", isPresented: $showingPeriodOptions, titleVisibility: .visible) {
            ForEach(FlowIntensity.allCases, id: \.self) { flow in
                Button(flow.rawValue) {
                    cycleManager.addCycle(startDate: Date(), flow: flow)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("请选择经血量")
        }
        .confirmationDialog("记录症状", isPresented: $showingSymptomOptions, titleVisibility: .visible) {
            ForEach(SymptomType.allCases, id: \.self) { symptomType in
                Button(symptomType.rawValue) {
                    cycleManager.addSymptom(date: Date(), type: symptomType, severity: 3)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("请选择症状类型")
        }
    }
    
    // 显示月经记录选项
    private func showPeriodRecordOptions() {
        showingPeriodOptions = true
    }
    
    // 显示症状记录选项
    private func showSymptomRecordOptions() {
        showingSymptomOptions = true
    }
    
    // 用户选择器卡片
    private var userSelectorCard: some View {
        VStack {
            HStack {
                Text("当前用户")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    showingUserPicker = true
                }) {
                    HStack {
                        Text(cycleManager.currentUser.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.pink)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .confirmationDialog("选择用户", isPresented: $showingUserPicker, titleVisibility: .visible) {
            ForEach(Array(cycleManager.users.enumerated()), id: \.offset) { index, user in
                Button(user.name) {
                    cycleManager.selectedUserIndex = index
                }
            }
            Button("取消", role: .cancel) { }
        }
    }
    
    // 当前状态卡片
    private var currentStatusCard: some View {
        let today = Date()
        let status = cycleManager.getCycleStatus(for: today)
        
        return VStack(spacing: 15) {
            HStack {
                Text("今日状态")
                    .font(.headline)
                Spacer()
                Text(status.description)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(status.color)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            
            // 周期进度
            if let lastPeriodStart = cycleManager.currentUser.lastPeriodStart {
                let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriodStart, to: today).day ?? 0
                let cycleLength = cycleManager.currentUser.cycleLength
                let progress = Double(daysSinceLastPeriod) / Double(cycleLength)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("周期第 \(daysSinceLastPeriod + 1) 天")
                            .font(.subheadline)
                        Spacer()
                        Text("共 \(cycleLength) 天")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .pink))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // 预测信息卡片
    private var predictionCard: some View {
        VStack(spacing: 15) {
            Text("预测信息")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                // 下次月经
                VStack {
                    Image(systemName: "drop.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    
                    Text("下次月经")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let nextPeriod = cycleManager.currentUser.nextPeriodStart {
                        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: nextPeriod).day ?? 0
                        Text("\(daysUntil) 天后")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } else {
                        Text("暂无数据")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // 排卵期
                VStack {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("排卵期")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let ovulationDate = cycleManager.currentUser.ovulationDate {
                        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: ovulationDate).day ?? 0
                        if daysUntil > 0 {
                            Text("\(daysUntil) 天后")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        } else if daysUntil >= -2 {
                            Text("进行中")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        } else {
                            Text("已过")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("暂无数据")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // 快速操作卡片
    private var quickActionsCard: some View {
        VStack(spacing: 15) {
            Text("快速操作")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 15) {
                // 记录月经
                Button(action: {
                    showPeriodRecordOptions()
                }) {
                    VStack {
                        Image(systemName: "drop.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        Text("记录月经")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // 记录症状
                Button(action: {
                    showSymptomRecordOptions()
                }) {
                    VStack {
                        Image(systemName: "heart.text.square.fill")
                            .font(.title)
                            .foregroundColor(.orange)
                        Text("记录症状")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // 查看日历
                NavigationLink(destination: CalendarView(cycleManager: cycleManager)) {
                    VStack {
                        Image(systemName: "calendar.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        Text("查看日历")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // 最近记录卡片
    private var recentRecordsCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("最近记录")
                    .font(.headline)
                Spacer()
                NavigationLink("查看全部", destination: RecordView(cycleManager: cycleManager))
                    .font(.caption)
                    .foregroundColor(.pink)
            }
            
            let recentCycles = cycleManager.currentUser.cycles.sorted { $0.startDate > $1.startDate }.prefix(3)
            
            if recentCycles.isEmpty {
                Text("暂无记录")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                ForEach(Array(recentCycles), id: \.id) { cycle in
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(cycle.flow.color)
                        
                        VStack(alignment: .leading) {
                            Text("月经开始")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(DateFormatter.shortDate.string(from: cycle.startDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(cycle.flow.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(cycle.flow.color.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 8)
                    
                    if cycle.id != recentCycles.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// 日期格式化扩展
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(cycleManager: CycleManager())
    }
}