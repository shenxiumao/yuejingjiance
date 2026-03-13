//
//  UserDefaultsStorage.swift
//  YueJingJiance
//
//  简单的 UserDefaults 存储实现 - 用于非敏感数据
//

import Foundation

final class UserDefaultsStorage {
    static let shared = UserDefaultsStorage()
    
    private let userDefaults: UserDefaults
    
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - 用户相关
    var selectedUserId: String? {
        get { userDefaults.string(forKey: "selected_user_id") }
        set { userDefaults.set(newValue, forKey: "selected_user_id") }
    }
    
    // MARK: - 通知设置
    var notificationSettingsData: Data? {
        get { userDefaults.data(forKey: "notification_settings") }
        set { userDefaults.set(newValue, forKey: "notification_settings") }
    }
    
    // MARK: - 隐私设置
    var privacySettingsData: Data? {
        get { userDefaults.data(forKey: "privacy_settings") }
        set { userDefaults.set(newValue, forKey: "privacy_settings") }
    }
    
    // MARK: - 应用状态
    var hasLaunchedBefore: Bool {
        get { userDefaults.bool(forKey: "has_launched_before") }
        set { userDefaults.set(newValue, forKey: "has_launched_before") }
    }
    
    var lastLaunchDate: Date? {
        get { userDefaults.object(forKey: "last_launch_date") as? Date }
        set { userDefaults.set(newValue, forKey: "last_launch_date") }
    }
    
    // MARK: - 主题设置
    var selectedTheme: String {
        get { userDefaults.string(forKey: "selected_theme") ?? "system" }
        set { userDefaults.set(newValue, forKey: "selected_theme") }
    }
    
    // MARK: - 通用方法
    func set<T: Codable>(_ value: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    func get<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    func clearAll() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
    }
}

// MARK: - 仓库实现：UserDefaults 版本
final class UserDefaultsSettingsRepository: SettingsRepositoryProtocol {
    
    func getSelectedUserId() async -> UUID? {
        guard let uuidString = UserDefaults.shared.selectedUserId,
              let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        return uuid
    }
    
    func setSelectedUserId(_ userId: UUID) async {
        UserDefaults.shared.selectedUserId = userId.uuidString
    }
    
    func getNotificationSettings() async -> NotificationSettings {
        if let data = UserDefaults.shared.notificationSettingsData,
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            return settings
        }
        return NotificationSettings()
    }
    
    func setNotificationSettings(_ settings: NotificationSettings) async {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.shared.notificationSettingsData = data
        }
    }
    
    func getPrivacySettings() async -> PrivacySettings {
        if let data = UserDefaults.shared.privacySettingsData,
           let settings = try? JSONDecoder().decode(PrivacySettings.self, from: data) {
            return settings
        }
        return PrivacySettings()
    }
    
    func setPrivacySettings(_ settings: PrivacySettings) async {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.shared.privacySettingsData = data
        }
    }
}
