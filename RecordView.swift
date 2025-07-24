import SwiftUI

struct RecordView: View {
    @ObservedObject var cycleManager: CycleManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // 分段控制器
                Picker("记录类型", selection: $selectedTab) {
                    Text("月经记录").tag(0)
                    Text("症状记录").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // 内容区域
                TabView(selection: $selectedTab) {
                    PeriodRecordView(cycleManager: cycleManager)
                        .tag(0)
                    
                    SymptomRecordView(cycleManager: cycleManager)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("记录")
        }
    }
}

// 月经记录视图
struct PeriodRecordView: View {
    @ObservedObject var cycleManager: CycleManager
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var hasEndDate = false
    @State private var selectedFlow = FlowIntensity.medium
    @State private var notes = ""
    @State private var showingAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 用户信息
                userInfoCard
                
                // 记录表单
                recordFormCard
                
                // 历史记录
                historyCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .alert("记录成功", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("月经记录已保存")
        }
    }
    
    private var userInfoCard: some View {
        VStack {
            HStack {
                Text("当前用户: \(cycleManager.currentUser.name)")
                    .font(.headline)
                Spacer()
                Text("周期: \(cycleManager.currentUser.cycleLength)天")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var recordFormCard: some View {
        VStack(spacing: 20) {
            Text("添加月经记录")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 开始日期
            VStack(alignment: .leading, spacing: 8) {
                Text("开始日期")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
            }
            
            // 结束日期（可选）
            VStack(alignment: .leading, spacing: 8) {
                Toggle("设置结束日期", isOn: $hasEndDate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if hasEndDate {
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                }
            }
            
            // 经血量
            VStack(alignment: .leading, spacing: 8) {
                Text("经血量")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 15) {
                    ForEach(FlowIntensity.allCases, id: \.self) { flow in
                        Button(action: {
                            selectedFlow = flow
                        }) {
                            VStack {
                                Circle()
                                    .fill(flow.color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedFlow == flow ? Color.pink : Color.clear, lineWidth: 3)
                                    )
                                
                                Text(flow.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // 备注
            VStack(alignment: .leading, spacing: 8) {
                Text("备注")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("输入备注...", text: $notes, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            // 保存按钮
            Button(action: savePeriodRecord) {
                Text("保存记录")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var historyCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("历史记录")
                    .font(.headline)
                Spacer()
                Text("最近5条")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            let recentCycles = cycleManager.currentUser.cycles.sorted { $0.startDate > $1.startDate }.prefix(5)
            
            if recentCycles.isEmpty {
                Text("暂无记录")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ForEach(Array(recentCycles), id: \.id) { cycle in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(DateFormatter.mediumDate.string(from: cycle.startDate))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if let endDate = cycle.endDate {
                                Text("至 \(DateFormatter.mediumDate.string(from: endDate))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if !cycle.notes.isEmpty {
                                Text(cycle.notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                        
                        VStack {
                            Circle()
                                .fill(cycle.flow.color)
                                .frame(width: 20, height: 20)
                            
                            Text(cycle.flow.rawValue)
                                .font(.caption)
                        }
                        
                        // 删除按钮
                        Button(action: {
                            cycleManager.deleteCycle(cycle)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(PlainButtonStyle())
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
    
    private func savePeriodRecord() {
        cycleManager.addCycle(
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            flow: selectedFlow,
            notes: notes
        )
        
        // 重置表单
        startDate = Date()
        endDate = Date()
        hasEndDate = false
        selectedFlow = .medium
        notes = ""
        
        showingAlert = true
    }
}

// 症状记录视图
struct SymptomRecordView: View {
    @ObservedObject var cycleManager: CycleManager
    @State private var selectedDate = Date()
    @State private var selectedSymptom = SymptomType.cramps
    @State private var severity = 3
    @State private var notes = ""
    @State private var showingAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 症状记录表单
                symptomFormCard
                
                // 症状历史
                symptomHistoryCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .alert("记录成功", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("症状记录已保存")
        }
    }
    
    private var symptomFormCard: some View {
        VStack(spacing: 20) {
            Text("添加症状记录")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 日期选择
            VStack(alignment: .leading, spacing: 8) {
                Text("日期")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
            }
            
            // 症状类型
            VStack(alignment: .leading, spacing: 8) {
                Text("症状类型")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                    ForEach(SymptomType.allCases, id: \.self) { symptom in
                        Button(action: {
                            selectedSymptom = symptom
                        }) {
                            HStack {
                                Image(systemName: symptom.icon)
                                    .foregroundColor(selectedSymptom == symptom ? .white : .pink)
                                Text(symptom.rawValue)
                                    .font(.caption)
                                    .foregroundColor(selectedSymptom == symptom ? .white : .primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedSymptom == symptom ? Color.pink : Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // 严重程度
            VStack(alignment: .leading, spacing: 8) {
                Text("严重程度: \(severity)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("轻微")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: Binding(
                        get: { Double(severity) },
                        set: { severity = Int($0) }
                    ), in: 1...5, step: 1)
                    .accentColor(.pink)
                    
                    Text("严重")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    ForEach(1...5, id: \.self) { level in
                        Circle()
                            .fill(level <= severity ? Color.pink : Color(.systemGray5))
                            .frame(width: 12, height: 12)
                    }
                }
            }
            
            // 备注
            VStack(alignment: .leading, spacing: 8) {
                Text("备注")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("描述症状详情...", text: $notes, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            // 保存按钮
            Button(action: saveSymptomRecord) {
                Text("保存记录")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var symptomHistoryCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("症状历史")
                    .font(.headline)
                Spacer()
                Text("最近10条")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            let recentSymptoms = cycleManager.currentUser.symptoms.sorted { $0.date > $1.date }.prefix(10)
            
            if recentSymptoms.isEmpty {
                Text("暂无症状记录")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ForEach(Array(recentSymptoms), id: \.id) { symptom in
                    HStack {
                        Image(systemName: symptom.type.icon)
                            .foregroundColor(.pink)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(symptom.type.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(DateFormatter.mediumDate.string(from: symptom.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !symptom.notes.isEmpty {
                                Text(symptom.notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                        
                        // 严重程度指示器
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { level in
                                Circle()
                                    .fill(level <= symptom.severity ? Color.pink : Color(.systemGray5))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        
                        // 删除按钮
                        Button(action: {
                            cycleManager.deleteSymptom(symptom)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 8)
                    
                    if symptom.id != recentSymptoms.last?.id {
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
    
    private func saveSymptomRecord() {
        cycleManager.addSymptom(
            date: selectedDate,
            type: selectedSymptom,
            severity: severity,
            notes: notes
        )
        
        // 重置表单
        selectedDate = Date()
        selectedSymptom = .cramps
        severity = 3
        notes = ""
        
        showingAlert = true
    }
}

// 日期格式化扩展
extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

struct RecordView_Previews: PreviewProvider {
    static var previews: some View {
        RecordView(cycleManager: CycleManager())
    }
}