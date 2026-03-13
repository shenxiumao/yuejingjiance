//
//  CoreDataStorage.swift
//  YueJingJiance
//
//  CoreData 存储管理 - 数据持久化层
//

import Foundation
import CoreData

// MARK: - CoreData 堆栈管理
final class CoreDataStack {
    static let shared = CoreDataStack()
    
    private let containerName = "YueJingJianceModel"
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: containerName)
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData 加载失败：\(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {}
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("CoreData 保存失败：\(error)")
            }
        }
    }
}

// MARK: - 核心数据实体扩展
extension NSManagedObject {
    func toDictionary() -> [String: Any] {
        let properties = entity.attributesByName
        var dictionary: [String: Any] = [:]
        
        for key in properties.keys {
            if let value = value(forKey: key) {
                dictionary[key] = value
            }
        }
        
        return dictionary
    }
}

// MARK: - 数据加密工具
final class DataEncryptor {
    static let shared = DataEncryptor()
    
    private let encryptionKey: String
    
    private init() {
        // 从 Keychain 获取或生成加密密钥
        self.encryptionKey = Self.generateEncryptionKey()
    }
    
    private static func generateEncryptionKey() -> String {
        // 实际项目中应该使用 Keychain 安全存储
        if let existingKey = KeychainManager.shared.get(key: "encryption_key") {
            return existingKey
        }
        
        let key = UUID().uuidString + UUID().uuidString
        KeychainManager.shared.set(key: "encryption_key", value: key)
        return key
    }
    
    func encrypt(_ data: Data) -> Data? {
        // 简单的 XOR 加密（生产环境应使用 AES-256）
        var encrypted = [UInt8](repeating: 0, count: data.count)
        let keyBytes = [UInt8](encryptionKey.utf8)
        
        for i in 0..<data.count {
            encrypted[i] = data[i] ^ keyBytes[i % keyBytes.count]
        }
        
        return Data(encrypted)
    }
    
    func decrypt(_ data: Data) -> Data? {
        var decrypted = [UInt8](repeating: 0, count: data.count)
        let keyBytes = [UInt8](encryptionKey.utf8)
        
        for i in 0..<data.count {
            decrypted[i] = data[i] ^ keyBytes[i % keyBytes.count]
        }
        
        return Data(decrypted)
    }
}

// MARK: - Keychain 安全存储
final class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    func set(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Biometric 认证
final class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    
    private let context = LAContext()
    private var canEvaluate: Bool = false
    private var error: NSError?
    
    private init() {
        canEvaluate = Self.canEvaluateAuth
    }
    
    private static var canEvaluateAuth: Bool {
        var canEvaluate = false
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            canEvaluate = true
        }
        
        return canEvaluate
    }
    
    var isBiometricAvailable: Bool {
        canEvaluate
    }
    
    var biometricType: String {
        guard canEvaluate else { return "none" }
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID: return "faceID"
            case .touchID: return "touchID"
            default: return "none"
            }
        }
        
        return "none"
    }
    
    func authenticate(with reason: String, completion: @escaping (Bool) -> Void) {
        guard canEvaluate else {
            completion(false)
            return
        }
        
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func authenticate(with reason: String) async -> Bool {
        await withCheckedContinuation { continuation in
            authenticate(with: reason) { success in
                continuation.resume(returning: success)
            }
        }
    }
}
