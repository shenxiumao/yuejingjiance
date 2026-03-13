//
//  YueJingJianceApp.swift
//  YueJingJiance
//
//  应用入口 - 改进版
//

import SwiftUI
import UserNotifications

@main
struct YueJingJianceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appStateManager = AppStateManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appStateManager)
                .preferredColorScheme(.system) // 支持深色模式
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // 初始化通知
        Task {
            await NotificationService.shared.requestAuthorization()
        }
        
        // 设置通知代理
        UNUserNotificationCenter.current().delegate = NotificationCenterDelegate.shared
    }
}

// MARK: - 应用状态管理
final class AppStateManager: ObservableObject {
    @Published var isLocked = false
    @Published var isAuthenticated = true
    @Published var privacySettings: PrivacySettings = PrivacySettings()
    
    private var appDidBecomeActive = false
    
    init() {
        setupLifecycleObservers()
    }
    
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.appDidBecomeActive = true
            self?.checkAuthStatus()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.appDidBecomeActive = false
            self?.scheduleLock()
        }
    }
    
    private func scheduleLock() {
        guard privacySettings.enableAppLock else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(privacySettings.autoLockDelay)) { [weak self] in
            self?.isLocked = true
            self?.isAuthenticated = false
        }
    }
    
    private func checkAuthStatus() {
        if appDidBecomeActive && privacySettings.enableAppLock && !isAuthenticated {
            isLocked = true
        }
    }
    
    func authenticate(completion: @escaping (Bool) -> Void) {
        let reason = "需要验证身份以访问应用"
        
        Task {
            let success = await BiometricAuthManager.shared.authenticate(with: reason)
            completion(success)
        }
    }
    
    func resetLock() {
        isLocked = false
        isAuthenticated = true
    }
}

// MARK: - 应用代理
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 初始化 CoreData
        _ = CoreDataStack.shared
        
        // 记录启动时间
        UserDefaults.shared.hasLaunchedBefore = true
        UserDefaults.shared.lastLaunchDate = Date()
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        willContinueUserActivityWithType userActivityType: String
    ) -> Bool {
        return true
    }
    
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        return true
    }
}

// MARK: - 根视图
struct RootView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        Group {
            if appStateManager.isLocked {
                LockView()
                    .environmentObject(appStateManager)
            } else {
                ContentView()
            }
        }
    }
}

// MARK: - 锁屏视图
struct LockView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var isAuthenticating = false
    @State private var authError: String?
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.pink)
            
            Text("身份验证")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("需要验证身份以继续")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let error = authError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Button(action: authenticate) {
                HStack {
                    Image(systemName: "faceid")
                    Text("验证")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.pink)
                .cornerRadius(12)
            }
            .disabled(isAuthenticating)
            .padding(.horizontal, 40)
            
            if appStateManager.privacySettings.lockType != .none {
                Button(action: authenticate) {
                    Text("使用密码")
                        .font(.subheadline)
                        .foregroundColor(.pink)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func authenticate() {
        isAuthenticating = true
        authError = nil
        
        appStateManager.authenticate { success in
            isAuthenticating = false
            
            if success {
                appStateManager.resetLock()
            } else {
                authError = "验证失败，请重试"
            }
        }
    }
}

// MARK: - 主内容视图
struct ContentView: View {
    @StateObject private var cycleManager = CycleManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(cycleManager: cycleManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
                .tag(0)
            
            RecordView(cycleManager: cycleManager)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("记录")
                }
                .tag(1)
            
            CalendarView(cycleManager: cycleManager)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("日历")
                }
                .tag(2)
            
            StatisticsOverviewView(viewModel: StatisticsViewModel(
                cycleRepository: MockCycleRepository(),
                statisticsRepository: MockStatisticsRepository(),
                predictionService: CyclePredictionService.shared
            ))
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("统计")
            }
            .tag(3)
            
            SettingsView(cycleManager: cycleManager)
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
                .tag(4)
        }
        .accentColor(.pink)
    }
}

// MARK: - 模拟统计仓库
final class MockStatisticsRepository: StatisticsRepositoryProtocol {
    func fetchCycleStatistics(for userId: UUID) async throws -> CycleStatistics {
        return CycleStatistics(
            averageCycleLength: 28,
            averagePeriodLength: 5,
            cycleLengthStandardDeviation: 2,
            periodLengthStandardDeviation: 1,
            mostCommonFlowIntensity: .medium,
            mostCommonSymptoms: [],
            totalCycles: 3,
            totalSymptoms: 0,
            cycleRegularity: 0.85
        )
    }
    
    func fetchPhaseDistribution(for userId: UUID, in dateRange: ClosedRange<Date>) async throws -> [CyclePhase: Int] {
        return [
            .menstruation: 5,
            .follicular: 10,
            .ovulation: 3,
            .luteal: 10
        ]
    }
    
    func fetchSymptomFrequency(for userId: UUID, in dateRange: ClosedRange<Date>) async throws -> [SymptomType: Int] {
        return [
            .cramps: 12,
            .fatigue: 8,
            .headache: 5
        ]
    }
    
    func fetchCycleTrend(for userId: UUID, limit: Int) async throws -> [Double] {
        return [28, 29, 27, 28, 30, 28]
    }
}
