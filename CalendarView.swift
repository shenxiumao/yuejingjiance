import SwiftUI

struct CalendarView: View {
    @ObservedObject var cycleManager: CycleManager
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showingDateDetail = false
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 月份导航
                monthNavigationView
                
                // 日历网格
                calendarGridView
                
                // 底部信息
                bottomInfoView
            }
            .navigationTitle("日历")
            .sheet(isPresented: $showingDateDetail) {
                DateDetailView(date: selectedDate, cycleManager: cycleManager)
            }
        }
    }
    
    // 月份导航视图
    private var monthNavigationView: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.pink)
            }
            
            Spacer()
            
            Text(dateFormatter.string(from: currentMonth))
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.pink)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // 日历网格视图
    private var calendarGridView: some View {
        VStack(spacing: 0) {
            // 星期标题
            weekdayHeaderView
            
            // 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(date: date, cycleManager: cycleManager, selectedDate: $selectedDate, showingDetail: $showingDateDetail)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 60)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    // 星期标题
    private var weekdayHeaderView: some View {
        HStack(spacing: 0) {
            ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { weekday in
                Text(weekday)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .background(Color(.systemGray6))
    }
    
    // 底部信息视图
    private var bottomInfoView: some View {
        VStack(spacing: 15) {
            // 图例
            legendView
            
            // 当前用户信息
            currentUserInfoView
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // 图例
    private var legendView: some View {
        VStack(spacing: 10) {
            Text("图例")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    Text("经期")
                        .font(.caption)
                }
                
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                    Text("排卵期")
                        .font(.caption)
                }
                
                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 12, height: 12)
                    Text("症状")
                        .font(.caption)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // 当前用户信息
    private var currentUserInfoView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("当前用户: \(cycleManager.currentUser.name)")
                    .font(.headline)
                Spacer()
                Button("切换用户") {
                    cycleManager.selectedUserIndex = (cycleManager.selectedUserIndex + 1) % cycleManager.users.count
                }
                .font(.caption)
                .foregroundColor(.pink)
            }
            
            if let nextPeriod = cycleManager.currentUser.nextPeriodStart {
                let daysUntil = calendar.dateComponents([.day], from: Date(), to: nextPeriod).day ?? 0
                Text("预计 \(daysUntil) 天后来月经")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // 获取当月所有日期
    private func getDaysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let numberOfDaysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // 添加前面的空白日期
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // 添加当月的所有日期
        for day in 1...numberOfDaysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}

// 日期单元格
struct DayCell: View {
    let date: Date
    @ObservedObject var cycleManager: CycleManager
    @Binding var selectedDate: Date
    @Binding var showingDetail: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: {
            selectedDate = date
            showingDetail = true
        }) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundColor(isToday ? .white : .primary)
                
                // 状态指示器
                HStack(spacing: 2) {
                    ForEach(getStatusIndicators(), id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isToday ? Color.pink : Color.clear)
            )
        }
        .frame(height: 60)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var isToday: Bool {
        calendar.isDate(date, inSameDayAs: Date())
    }
    
    private func getStatusIndicators() -> [Color] {
        var indicators: [Color] = []
        
        let status = cycleManager.getCycleStatus(for: date)
        switch status {
        case .period:
            indicators.append(.red)
        case .ovulation:
            indicators.append(.blue)
        case .normal:
            break
        }
        
        // 检查是否有症状记录
        let hasSymptoms = cycleManager.currentUser.symptoms.contains { symptom in
            calendar.isDate(symptom.date, inSameDayAs: date)
        }
        
        if hasSymptoms {
            indicators.append(.orange)
        }
        
        return indicators
    }
}

// 日期详情视图
struct DateDetailView: View {
    let date: Date
    @ObservedObject var cycleManager: CycleManager
    @Environment(\.presentationMode) var presentationMode
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 日期标题
                    Text(dateFormatter.string(from: date))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                    
                    // 周期状态
                    cycleStatusCard
                    
                    // 症状记录
                    symptomsCard
                    
                    // 快速操作
                    quickActionsCard
                }
                .padding()
            }
            .navigationTitle("日期详情")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("关闭") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var cycleStatusCard: some View {
        let status = cycleManager.getCycleStatus(for: date)
        
        return VStack(spacing: 15) {
            HStack {
                Text("周期状态")
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
            
            // 详细信息
            VStack(alignment: .leading, spacing: 8) {
                if let lastPeriodStart = cycleManager.currentUser.lastPeriodStart {
                    let daysSince = Calendar.current.dateComponents([.day], from: lastPeriodStart, to: date).day ?? 0
                    Text("距离上次月经: \(daysSince) 天")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let nextPeriodStart = cycleManager.currentUser.nextPeriodStart {
                    let daysUntil = Calendar.current.dateComponents([.day], from: date, to: nextPeriodStart).day ?? 0
                    if daysUntil > 0 {
                        Text("距离下次月经: \(daysUntil) 天")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var symptomsCard: some View {
        let daySymptoms = cycleManager.currentUser.symptoms.filter { symptom in
            Calendar.current.isDate(symptom.date, inSameDayAs: date)
        }
        
        return VStack(spacing: 15) {
            HStack {
                Text("症状记录")
                    .font(.headline)
                Spacer()
                if !daySymptoms.isEmpty {
                    Text("\(daySymptoms.count) 条")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if daySymptoms.isEmpty {
                Text("当日无症状记录")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                ForEach(daySymptoms, id: \.id) { symptom in
                    HStack {
                        Image(systemName: symptom.type.icon)
                            .foregroundColor(.orange)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(symptom.type.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if !symptom.notes.isEmpty {
                                Text(symptom.notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // 严重程度
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { level in
                                Circle()
                                    .fill(level <= symptom.severity ? Color.orange : Color(.systemGray5))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if symptom.id != daySymptoms.last?.id {
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
    
    private var quickActionsCard: some View {
        VStack(spacing: 15) {
            Text("快速操作")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 15) {
                Button(action: {
                    cycleManager.addCycle(startDate: date)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    VStack {
                        Image(systemName: "drop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        Text("记录月经")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    cycleManager.addSymptom(date: date, type: .cramps, severity: 3)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    VStack {
                        Image(systemName: "heart.text.square.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("记录症状")
                            .font(.caption)
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
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(cycleManager: CycleManager())
    }
}