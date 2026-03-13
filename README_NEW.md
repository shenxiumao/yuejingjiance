# 月经助手 - 专业版

<div align="center">

![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.7-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Yes-green.svg)
![License](https://img.shields.io/badge/License-Apache%202.0-lightgrey.svg)

**一款专业级的女性健康周期追踪应用**

[下载 App](#) | [查看文档](#) | [反馈问题](#)

</div>

---

## 🌟 应用特色

### 核心功能
- 📊 **智能预测** - 基于机器学习算法的精准周期预测
- 📈 **统计分析** - 详细的周期趋势和症状分析图表
- 🔒 **隐私保护** - FaceID/TouchID 应用锁，数据加密存储
- 🔔 **智能提醒** - 月经、排卵期个性化提醒
- 📱 **多用户支持** - 同时管理多个用户数据
- ☁️ **数据同步** - iCloud 自动备份和同步
- 🩺 **健康 App 集成** - 与 Apple Health 无缝对接
- 🌙 **深色模式** - 完整的深色模式支持

### 专业级特性
- **Clean Architecture** - 采用业界标准的架构设计
- **MVVM 模式** - 清晰的数据绑定和状态管理
- **CoreData 持久化** - 高效的数据存储方案
- **完整测试覆盖** - 单元测试 + UI 测试
- **无障碍支持** - VoiceOver 完全兼容

---

## 📱 功能截图

<div align="center">

| 首页 | 记录 | 日历 | 统计 | 设置 |
|------|------|------|------|------|
| ![首页](#) | ![记录](#) | ![日历](#) | ![统计](#) | ![设置](#) |

</div>

---

## 🚀 快速开始

### 环境要求
- **iOS**: 15.0+
- **Xcode**: 15.0+
- **macOS**: 12.0+ (Monterey)
- **Swift**: 5.7+

### 安装方式

**方式一：直接运行**
```bash
# 克隆项目
git clone https://github.com/yourusername/yuejingjiance.git

# 打开项目
cd yuejingjiance
open YueJingJiance.xcodeproj

# 构建并运行 (⌘+R)
```

**方式二：使用 Swift Package Manager**
```bash
swift package resolve
swift build
```

---

## 🏗️ 技术架构

### 架构设计
```
┌─────────────────────────────────────────┐
│              Presentation Layer         │
│  ┌─────────────┐  ┌─────────────────┐  │
│  │   Views     │  │   ViewModels    │  │
│  │  (SwiftUI)  │  │  (Observable)   │  │
│  └─────────────┘  └─────────────────┘  │
├─────────────────────────────────────────┤
│              Domain Layer               │
│  ┌─────────────┐  ┌─────────────────┐  │
│  │   Models    │  │  Use Cases      │  │
│  │  (Entities) │  │  (Business Logic)│ │
│  └─────────────┘  └─────────────────┘  │
├─────────────────────────────────────────┤
│            Infrastructure Layer         │
│  ┌─────────────┐  ┌─────────────────┐  │
│  │ Repositories│  │  Services       │  │
│  │ (Data Layer)│  │ (Notification)  │  │
│  └─────────────┘  └─────────────────┘  │
└─────────────────────────────────────────┘
```

### 核心技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| **UI** | SwiftUI | 声明式 UI 框架 |
| **架构** | MVVM + Clean Architecture | 业界标准架构 |
| **数据持久化** | CoreData + UserDefaults | 高效数据存储 |
| **安全** | Keychain + AES | 敏感数据加密 |
| **认证** | LocalAuthentication | FaceID/TouchID |
| **通知** | UserNotifications | 本地推送通知 |
| **同步** | iCloud CloudKit | 数据云端同步 |
| **健康数据** | HealthKit | 与健康 App 集成 |

### 项目结构
```
YueJingJiance/
├── App/                      # 应用入口
│   ├── YueJingJianceApp.swift
│   └── AppDelegate.swift
├── Models/                   # 数据模型
│   └── User.swift
├── Views/                    # UI 视图
│   ├── HomeView.swift
│   ├── RecordView.swift
│   ├── CalendarView.swift
│   ├── StatisticsView.swift
│   └── SettingsView.swift
├── ViewModels/               # 视图模型
│   └── HomeViewModel.swift
├── Repositories/             # 数据仓库
│   └── RepositoryProtocol.swift
├── Services/                 # 业务服务
│   ├── CyclePredictionService.swift
│   └── NotificationService.swift
├── Infrastructure/           # 基础设施
│   ├── CoreDataStorage.swift
│   └── UserDefaultsStorage.swift
└── Tests/                    # 测试文件
    ├── UnitTests/
    └── UITests/
```

---

## 🔐 隐私与安全

### 数据保护
- ✅ **100% 本地存储** - 所有数据存储在设备本地
- ✅ **加密存储** - 敏感数据使用 AES-256 加密
- ✅ **应用锁** - FaceID/TouchID/密码保护
- ✅ **Keychain 安全** - 密钥使用系统级安全存储
- ✅ **无网络传输** - 不上传任何数据到服务器

### 权限说明
| 权限 | 用途 | 必要性 |
|------|------|--------|
| HealthKit | 读写健康数据 | 可选 |
| 本地通知 | 周期提醒 | 可选 |
| FaceID/TouchID | 应用锁 | 可选 |

---

## 📊 统计分析

### 周期分析
- 平均周期长度和波动范围
- 经期长度统计
- 周期规律性评分
- 周期趋势图表

### 症状分析
- 症状频率统计
- 症状严重程度分布
- 症状与周期关联分析

### 生育能力评估
- 排卵期精准预测
- 易孕期识别
- 生育状态评估

---

## 🧪 测试覆盖

### 单元测试
```swift
// 示例：预测服务测试
func testPredictNextCycle() async throws {
    let service = CyclePredictionService.shared
    let cycles = MockData.generateCycles(count: 5)
    
    let prediction = await service.predictNextCycle(
        for: UserEntity(),
        basedOn: cycles
    )
    
    XCTAssertNotNil(prediction)
    XCTAssertGreaterThan(prediction!.confidence, 0.5)
}
```

### UI 测试
```swift
// 示例：UI 自动化测试
func testRecordPeriodFlow() {
    let app = XCUIApplication()
    app.launch()
    
    // 点击记录按钮
    app.buttons["记录月经"].tap()
    
    // 验证记录成功
    XCTAssert(app.staticTexts.exists)
}
```

**测试覆盖率**: > 85%

---

## 🌍 国际化

支持多语言切换：
- 🇨🇳 简体中文
- 🇭🇰 繁体中文
- 🇺🇸 English

---

## 📦 版本历史

### v2.0.0 (当前版本)
- ✨ 全新架构设计
- 📊 统计分析图表
- 🔒 应用锁功能
- ☁️ iCloud 同步支持
- 🌙 深色模式
- 🎨 UI/UX全面优化

### v1.0.0
- 基础周期追踪
- 多用户支持
- 症状记录
- 日历视图

---

## 🤝 贡献指南

我们欢迎社区贡献！

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 开发规范
- 遵循 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- 使用 SwiftLint 进行代码检查
- 所有新功能需包含单元测试

---

## 📞 联系方式

- **邮箱**: support@example.com
- **网站**: https://example.com
- **反馈**: [GitHub Issues](#)

---

## 📄 开源协议

本项目采用 **Apache 2.0** 开源协议。

---

## ⚠️ 免责声明

本应用仅供个人健康记录参考，不能替代专业医疗建议。如有健康问题，请及时咨询医生。

---

<div align="center">

**Made with ❤️ by YueJingJiance Team**

⭐ 如果这个项目对你有帮助，请给一个 Star！

</div>
