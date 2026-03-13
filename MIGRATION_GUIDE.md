# 月经助手 - 升级迁移指南

## 从 v1.0 到 v2.0 的升级说明

### 重大变更

#### 1. 架构重构
- **旧版**: 简单的 MVC 架构，所有逻辑在 View 中
- **新版**: Clean Architecture + MVVM，清晰的层次分离

#### 2. 数据层变更
- **旧版**: UserDefaults + JSON 序列化
- **新版**: CoreData + 加密存储 + iCloud 同步

#### 3. 新的依赖
```swift
// 新增文件结构
YueJingJiance/
├── App/                          # 应用入口
│   ├── YueJingJianceApp.swift   # 新的应用入口
│   └── AppDelegate.swift        # 应用代理
├── Models/                       # 数据模型
│   └── User.swift               # 实体定义
├── Views/                        # UI 视图层
│   ├── HomeView.swift
│   ├── RecordView.swift
│   ├── CalendarView.swift
│   ├── StatisticsView.swift     # 新增统计视图
│   ├── SettingsView.swift
│   └── ContentView.swift        # 兼容旧版
├── ViewModels/                   # 新增视图模型层
│   └── HomeViewModel.swift
├── Repositories/                 # 数据仓库层
│   └── RepositoryProtocol.swift
├── Services/                     # 业务服务层
│   ├── CyclePredictionService.swift
│   ├── NotificationService.swift
│   └── DataExportService.swift
├── Infrastructure/               # 基础设施层
│   ├── CoreDataStorage.swift
│   └── UserDefaultsStorage.swift
└── Tests/                        # 测试文件
    ├── CyclePredictionServiceTests.swift
    └── UserEntityTests.swift
```

### 数据迁移

#### 自动迁移脚本
```swift
// 在首次启动时执行
func migrateFromV1ToV2() async {
    // 1. 读取旧数据
    if let oldData = UserDefaults.standard.data(forKey: "SavedUsers") {
        let users = try? JSONDecoder().decode([User].self, from: oldData)
        
        // 2. 转换到新格式
        if let users = users {
            for user in users {
                let newUser = UserEntity(
                    id: user.id,
                    name: user.name,
                    cycleLength: user.cycleLength,
                    periodLength: user.periodLength
                )
                // 3. 保存到 CoreData
                try? await saveToCoreData(newUser)
            }
        }
    }
    
    // 4. 标记迁移完成
    UserDefaults.standard.set(true, forKey: "HasMigratedToV2")
}
```

### API 变更

#### 旧版 API
```swift
// 直接使用 CycleManager
let manager = CycleManager()
manager.addCycle(startDate: Date(), flow: .medium)
```

#### 新版 API
```swift
// 使用 Repository 模式
let cycleRepository = CoreDataCycleRepository()
let cycle = MenstrualCycleEntity(userId: userId, startDate: Date())
try? await cycleRepository.createCycle(cycle)

// 或使用 ViewModel
@StateObject private var viewModel = HomeViewModel(...)
await viewModel.recordPeriod(startDate: Date(), flow: .medium)
```

### 新功能使用

#### 1. 应用锁
```swift
// 在设置中启用
var settings = PrivacySettings()
settings.enableAppLock = true
settings.lockType = .faceID
await settingsRepository.setPrivacySettings(settings)
```

#### 2. 统计图表
```swift
// 在导航中添加统计页面
NavigationLink("统计") {
    StatisticsOverviewView(viewModel: StatisticsViewModel(...))
}
```

#### 3. 通知提醒
```swift
// 请求通知权限
let granted = await NotificationService.shared.requestAuthorization()

// 设置提醒
await NotificationService.shared.schedulePeriodReminder(
    for: user,
    prediction: predictionInfo
)
```

### 已知问题

1. **CoreData 迁移**: 首次启动可能需要几秒钟进行数据迁移
2. **iCloud 同步**: 需要用户登录 iCloud 账户
3. **HealthKit**: 需要用户在设置中授权

### 回滚方案

如需回滚到 v1.0：
```bash
git checkout v1.0.0
```

数据备份位置：
- v2.0 数据：`~/Library/Application Support/YueJingJiance/`
- v1.0 数据：`~/Library/Preferences/com.example.yuejingjiance.plist`

---

## 开发指南

### 添加新功能

1. **创建数据模型**
```swift
// Models/NewFeature.swift
struct NewFeatureEntity: Identifiable, Codable {
    let id: UUID
    var data: String
}
```

2. **定义 Repository 协议**
```swift
// Repositories/NewFeatureRepositoryProtocol.swift
protocol NewFeatureRepositoryProtocol {
    func fetchFeatures() async throws -> [NewFeatureEntity]
    func createFeature(_ feature: NewFeatureEntity) async throws
}
```

3. **实现 Repository**
```swift
// Infrastructure/NewFeatureRepository.swift
final class CoreDataNewFeatureRepository: NewFeatureRepositoryProtocol {
    // CoreData 实现
}
```

4. **创建 ViewModel**
```swift
// ViewModels/NewFeatureViewModel.swift
final class NewFeatureViewModel: ObservableObject {
    private let repository: NewFeatureRepositoryProtocol
    // ...
}
```

5. **创建 View**
```swift
// Views/NewFeatureView.swift
struct NewFeatureView: View {
    @StateObject private var viewModel = NewFeatureViewModel(...)
    // ...
}
```

### 测试规范

```swift
// Tests/NewFeatureTests.swift
final class NewFeatureTests: XCTestCase {
    func testExample() async throws {
        // 测试逻辑
    }
}
```

### 代码规范

- 遵循 Swift API Design Guidelines
- 使用 SwiftLint 进行代码检查
- 所有公共 API 需要文档注释
- 保持函数单一职责

---

## 故障排除

### 问题：CoreData 启动失败
**解决方案**:
```swift
// 删除旧数据并重建
let urls = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
let storeURL = urls[0].appendingPathComponent("YueJingJianceModel.sqlite")
try? FileManager.default.removeItem(at: storeURL)
```

### 问题：通知不显示
**解决方案**:
1. 检查是否请求了权限
2. 检查通知设置
3. 查看控制台日志

### 问题：FaceID 认证失败
**解决方案**:
1. 检查设备是否支持 FaceID/TouchID
2. 检查系统设置中是否启用了生物识别
3. 回退到密码认证

---

## 联系支持

如有问题，请联系：
- 邮箱：support@example.com
- GitHub Issues: [提交问题](#)
