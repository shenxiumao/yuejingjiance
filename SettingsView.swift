import SwiftUI

struct SettingsView: View {
    @ObservedObject var cycleManager: CycleManager
    @State private var showingUserEditor = false
    @State private var showingDataExport = false
    @State private var showingAbout = false
    @State private var showingClearDataAlert = false
    @State private var showingClearAllDataAlert = false
    @State private var showingResetAppAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // 用户管理部分
                Section("用户管理") {
                    userManagementSection
                }
                
                // 周期设置部分
                Section("周期设置") {
                    cycleSettingsSection
                }
                
                // 数据管理部分
                Section("数据管理") {
                    dataManagementSection
                }
                
                // 应用设置部分
                Section("应用设置") {
                    appSettingsSection
                }
                
                // 关于部分
                Section("关于") {
                    aboutSection
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showingUserEditor) {
                UserEditorView(cycleManager: cycleManager)
            }
            .sheet(isPresented: $showingDataExport) {
                DataExportView(cycleManager: cycleManager)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .alert("清除当前用户数据", isPresented: $showingClearDataAlert) {
                Button("取消", role: .cancel) { }
                Button("确认清除", role: .destructive) {
                    cycleManager.clearCurrentUserData()
                }
            } message: {
                Text("这将删除当前用户 \"\(cycleManager.currentUser.name)\" 的所有月经记录和症状数据。此操作无法撤销。")
            }
            .alert("清除所有用户数据", isPresented: $showingClearAllDataAlert) {
                Button("取消", role: .cancel) { }
                Button("确认清除", role: .destructive) {
                    cycleManager.clearAllData()
                }
            } message: {
                Text("这将删除所有用户的所有月经记录和症状数据。此操作无法撤销。")
            }
            .alert("重置应用", isPresented: $showingResetAppAlert) {
                Button("取消", role: .cancel) { }
                Button("确认重置", role: .destructive) {
                    cycleManager.resetApp()
                }
            } message: {
                Text("这将重置应用到初始状态，删除所有数据并恢复默认用户设置。此操作无法撤销。")
            }
        }
    }
    
    // 用户管理部分
    private var userManagementSection: some View {
        Group {
            ForEach(cycleManager.users.indices, id: \.self) { index in
                HStack {
                    VStack(alignment: .leading) {
                        Text(cycleManager.users[index].name)
                            .font(.headline)
                        Text("周期: \(cycleManager.users[index].cycleLength)天 | 经期: \(cycleManager.users[index].periodLength)天")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if index == cycleManager.selectedUserIndex {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.pink)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    cycleManager.selectedUserIndex = index
                }
            }
            
            Button(action: {
                showingUserEditor = true
            }) {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.pink)
                    Text("编辑用户信息")
                }
            }
        }
    }
    
    // 周期设置部分
    private var cycleSettingsSection: some View {
        Group {
            NavigationLink(destination: CycleSettingsDetailView(cycleManager: cycleManager)) {
                HStack {
                    Image(systemName: "calendar.circle")
                        .foregroundColor(.blue)
                    Text("周期参数设置")
                }
            }
            
            NavigationLink(destination: PredictionSettingsView(cycleManager: cycleManager)) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                    Text("预测算法设置")
                }
            }
        }
    }
    
    // 数据管理部分
    private var dataManagementSection: some View {
        Group {
            Button(action: {
                showingDataExport = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.green)
                    Text("导出数据")
                }
            }
            
            Button(action: {
                // 导入数据功能
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.orange)
                    Text("导入数据")
                }
            }
            
            Button(action: {
                showingClearDataAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    Text("清除当前用户数据")
                }
            }
            
            Button(action: {
                showingClearAllDataAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    Text("清除所有用户数据")
                }
            }
            
            Button(action: {
                showingResetAppAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.red)
                    Text("重置应用")
                }
            }
        }
    }
    
    // 应用设置部分
    private var appSettingsSection: some View {
        Group {
            NavigationLink(destination: NotificationSettingsView()) {
                HStack {
                    Image(systemName: "bell")
                        .foregroundColor(.yellow)
                    Text("通知设置")
                }
            }
            
            NavigationLink(destination: PrivacySettingsView()) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.gray)
                    Text("隐私设置")
                }
            }
        }
    }
    
    // 关于部分
    private var aboutSection: some View {
        Group {
            Button(action: {
                showingAbout = true
            }) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("关于应用")
                }
            }
            
            HStack {
                Image(systemName: "number")
                    .foregroundColor(.gray)
                Text("版本")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 用户编辑视图
struct UserEditorView: View {
    @ObservedObject var cycleManager: CycleManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var userName: String = ""
    @State private var cycleLength: Double = 28
    @State private var periodLength: Double = 5
    
    var body: some View {
        NavigationView {
            Form {
                Section("用户信息") {
                    TextField("用户名称", text: $userName)
                }
                
                Section("周期设置") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("周期长度: \(Int(cycleLength)) 天")
                            .font(.subheadline)
                        Slider(value: $cycleLength, in: 21...35, step: 1)
                            .accentColor(.pink)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("经期长度: \(Int(periodLength)) 天")
                            .font(.subheadline)
                        Slider(value: $periodLength, in: 3...8, step: 1)
                            .accentColor(.pink)
                    }
                }
            }
            .navigationTitle("编辑用户")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveUserSettings()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            loadCurrentUserSettings()
        }
    }
    
    private func loadCurrentUserSettings() {
        let currentUser = cycleManager.currentUser
        userName = currentUser.name
        cycleLength = Double(currentUser.cycleLength)
        periodLength = Double(currentUser.periodLength)
    }
    
    private func saveUserSettings() {
        cycleManager.updateUserSettings(
            name: userName,
            cycleLength: Int(cycleLength),
            periodLength: Int(periodLength)
        )
    }
}

// 周期设置详情视图
struct CycleSettingsDetailView: View {
    @ObservedObject var cycleManager: CycleManager
    
    var body: some View {
        Form {
            Section("当前用户: \(cycleManager.currentUser.name)") {
                HStack {
                    Text("平均周期长度")
                    Spacer()
                    Text("\(cycleManager.currentUser.cycleLength) 天")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("平均经期长度")
                    Spacer()
                    Text("\(cycleManager.currentUser.periodLength) 天")
                        .foregroundColor(.secondary)
                }
                
                if let lastPeriod = cycleManager.currentUser.lastPeriodStart {
                    HStack {
                        Text("上次月经开始")
                        Spacer()
                        Text(DateFormatter.shortDate.string(from: lastPeriod))
                            .foregroundColor(.secondary)
                    }
                }
                
                if let nextPeriod = cycleManager.currentUser.nextPeriodStart {
                    HStack {
                        Text("预计下次月经")
                        Spacer()
                        Text(DateFormatter.shortDate.string(from: nextPeriod))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("统计信息") {
                HStack {
                    Text("记录的周期数")
                    Spacer()
                    Text("\(cycleManager.currentUser.cycles.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("症状记录数")
                    Spacer()
                    Text("\(cycleManager.currentUser.symptoms.count)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("周期详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 预测设置视图
struct PredictionSettingsView: View {
    @ObservedObject var cycleManager: CycleManager
    @State private var usePrediction = true
    @State private var predictionDays = 3
    
    var body: some View {
        Form {
            Section("预测设置") {
                Toggle("启用预测功能", isOn: $usePrediction)
                
                if usePrediction {
                    Stepper("提前提醒天数: \(predictionDays)", value: $predictionDays, in: 1...7)
                }
            }
            
            Section("预测说明") {
                Text("预测功能基于您的历史记录计算下次月经和排卵期的大概时间。预测结果仅供参考，实际情况可能因个人体质和生活状况而有所不同。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("预测设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 通知设置视图
struct NotificationSettingsView: View {
    @State private var enableNotifications = true
    @State private var periodReminder = true
    @State private var ovulationReminder = true
    @State private var symptomReminder = false
    
    var body: some View {
        Form {
            Section("通知设置") {
                Toggle("启用通知", isOn: $enableNotifications)
                
                if enableNotifications {
                    Toggle("月经提醒", isOn: $periodReminder)
                    Toggle("排卵期提醒", isOn: $ovulationReminder)
                    Toggle("症状记录提醒", isOn: $symptomReminder)
                }
            }
            
            Section("提醒时间") {
                if enableNotifications {
                    DatePicker("每日提醒时间", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                }
            }
        }
        .navigationTitle("通知设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 隐私设置视图
struct PrivacySettingsView: View {
    @State private var enablePasscode = false
    @State private var enableBiometric = false
    @State private var hideInRecents = false
    
    var body: some View {
        Form {
            Section("隐私保护") {
                Toggle("启用密码保护", isOn: $enablePasscode)
                Toggle("启用生物识别", isOn: $enableBiometric)
                Toggle("在最近使用中隐藏", isOn: $hideInRecents)
            }
            
            Section("数据安全") {
                Text("您的所有数据都存储在本地设备上，不会上传到任何服务器。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("隐私设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 数据导出视图
struct DataExportView: View {
    @ObservedObject var cycleManager: CycleManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("数据导出")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("导出您的月经周期和症状数据，可用于备份或分享给医生。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 15) {
                    Button(action: {
                        exportData(format: "CSV")
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("导出为 CSV 文件")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        exportData(format: "JSON")
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.gearshape")
                            Text("导出为 JSON 文件")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarItems(
                leading: Button("关闭") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func exportData(format: String) {
        // 这里实现数据导出逻辑
        showingShareSheet = true
    }
}

// 关于视图
struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 应用图标和名称
                    VStack(spacing: 10) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.pink)
                        
                        Text("月经助手")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("版本 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // 应用描述
                    VStack(alignment: .leading, spacing: 15) {
                        Text("关于应用")
                            .font(.headline)
                        
                        Text("月经助手是一款专为女性设计的月经周期追踪应用。支持同时记录两个人的月经周期，帮助您更好地了解和管理自己的生理健康。")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("主要功能")
                            .font(.headline)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "calendar", text: "月经周期追踪")
                            FeatureRow(icon: "heart.text.square", text: "症状记录")
                            FeatureRow(icon: "brain.head.profile", text: "智能预测")
                            FeatureRow(icon: "person.2", text: "双用户支持")
                            FeatureRow(icon: "lock.shield", text: "隐私保护")
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationBarItems(
                leading: Button("关闭") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// 功能行组件
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.pink)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(cycleManager: CycleManager())
    }
}