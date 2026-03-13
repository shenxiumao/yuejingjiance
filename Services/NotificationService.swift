//
//  NotificationService.swift
//  YueJingJiance
//
//  通知服务 - 处理本地通知和提醒
//

import Foundation
import UserNotifications

// MARK: - 通知服务协议
protocol NotificationServiceProtocol {
    func requestAuthorization() async -> Bool
    func schedulePeriodReminder(for user: UserEntity, prediction: PredictionInfo) async
    func scheduleOvulationReminder(for user: UserEntity, prediction: PredictionInfo) async
    func cancelAllReminders() async
    func cancelPeriodReminder(for userId: UUID) async
    func cancelOvulationReminder(for userId: UUID) async
}

// MARK: - 通知服务实现
final class NotificationService: NotificationServiceProtocol {
    
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - 请求授权
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error = error {
                    print("通知授权失败：\(error)")
                }
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - 预约月经提醒
    func schedulePeriodReminder(for user: UserEntity, prediction: PredictionInfo) async {
        guard prediction.daysUntilPeriod > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "月经即将来潮"
        content.body = "\(user.name)，根据您的记录，月经预计在 \(prediction.daysUntilPeriod) 天后来潮，请做好准备。"
        content.sound = .default
        content.badge = 1
        
        // 提前 1-2 天提醒
        let reminderDate = Calendar.current.date(
            byAdding: .day, 
            value: -prediction.reminderDaysBefore, 
            from: prediction.nextPeriodStart
        ) ?? prediction.nextPeriodStart
        
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        dateComponents.hour = 8 // 早上 8 点提醒
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "period_reminder_\(user.id)_\(prediction.nextPeriodStart.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try center.add(request)
            print("月经提醒已预约：\(reminderDate)")
        } catch {
            print("预约提醒失败：\(error)")
        }
    }
    
    // MARK: - 预约排卵期提醒
    func scheduleOvulationReminder(for user: UserEntity, prediction: PredictionInfo) async {
        let content = UNMutableNotificationContent()
        content.title = "排卵期提醒"
        content.body = "\(user.name)，您正处于排卵期，今天是受孕几率最高的日子之一。"
        content.sound = .default
        
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: prediction.ovulationDate
        )
        dateComponents.hour = 9 // 早上 9 点提醒
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "ovulation_reminder_\(user.id)_\(prediction.ovulationDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try center.add(request)
            print("排卵期提醒已预约：\(prediction.ovulationDate)")
        } catch {
            print("预约提醒失败：\(error)")
        }
    }
    
    // MARK: - 取消所有提醒
    func cancelAllReminders() async {
        center.removeAllPendingNotificationRequests()
        print("所有提醒已取消")
    }
    
    // MARK: - 取消月经提醒
    func cancelPeriodReminder(for userId: UUID) async {
        let identifiers = await getPeriodReminderIdentifiers(for: userId)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - 取消排卵期提醒
    func cancelOvulationReminder(for userId: UUID) async {
        let identifiers = await getOvulationReminderIdentifiers(for: userId)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - 获取提醒标识符
    private func getPeriodReminderIdentifiers(for userId: UUID) async -> [String] {
        let requests = await center.pendingNotificationRequests()
        return requests.filter { $0.identifier.hasPrefix("period_reminder_\(userId)") }
            .map { $0.identifier }
    }
    
    private func getOvulationReminderIdentifiers(for userId: UUID) async -> [String] {
        let requests = await center.pendingNotificationRequests()
        return requests.filter { $0.identifier.hasPrefix("ovulation_reminder_\(userId)") }
            .map { $0.identifier }
    }
}

// MARK: - 通知中心代理（需要在 AppDelegate 中设置）
final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationCenterDelegate()
    
    private override init() {}
    
    // 应用在前台时显示通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 显示横幅、声音和徽章
        completionHandler([.banner, .sound, .badge])
    }
    
    // 处理用户与通知的交互
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 处理通知点击事件
        let identifier = response.notification.request.identifier
        
        if identifier.hasPrefix("period_reminder_") {
            // 跳转到记录页面
            print("用户点击了月经提醒")
        } else if identifier.hasPrefix("ovulation_reminder_") {
            // 跳转到日历页面
            print("用户点击了排卵期提醒")
        }
        
        completionHandler()
    }
}
