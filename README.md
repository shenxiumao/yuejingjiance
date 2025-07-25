# 月经助手 (YueJingJiance)

一款专为女性设计的月经周期追踪应用，支持多用户管理、智能预测和全面的生理状况记录。

## 🌟 主要功能

### 👥 多用户支持
- 支持多个用户的月经周期数据管理
- 独立的用户设置和数据存储
- 快速用户切换界面
- 用户信息自定义编辑

### 🩸 月经周期追踪
- 记录月经开始和结束日期
- 追踪经血量（轻量/中量/重量）
- 自定义周期长度和经期长度设置
- 智能预测下次月经时间
- **单独删除月经记录功能**

### 🧠 智能预测系统
- 基于历史数据的智能预测算法
- 排卵期计算和显示
- 安全期识别
- 个性化预测调整

### 💊 症状记录管理
- 支持多种生理症状记录：
  - 痛经 🩸
  - 头痛 🧠
  - 情绪波动 😔
  - 腹胀 🤰
  - 疲劳 😴
  - 痘痘 😷
  - 乳房胀痛 💗
- 症状严重程度评级（1-5级）
- 症状历史统计和查看
- **单独删除症状记录功能**

### 📊 可视化日历
- 直观的月历视图显示周期状态
- 颜色编码区分不同生理阶段：
  - 🔴 经期
  - 🔵 排卵期
  - 🟠 症状记录日
- 日期详情查看和管理
- 快速记录功能

### ⚡ 快速操作
- 首页快速记录月经（支持二级菜单选择经血量）
- 首页快速记录症状（支持二级菜单选择症状类型和严重程度）
- 一键跳转到日历查看
- 最近记录快速查看

### ⚙️ 个性化设置
- 用户信息管理和编辑
- 周期参数自定义设置
- 数据管理选项：
  - 清除当前用户数据
  - 清除所有用户数据
  - 重置应用到初始状态
- 数据导出功能

### 📤 数据管理
- 数据导出（CSV格式）
- 本地安全数据存储
- 灵活的数据清除选项
- 应用重置功能

## 🛠 技术架构

### 开发环境
- **语言**: Swift 5.7+
- **UI框架**: SwiftUI
- **最低版本**: iOS 15+
- **架构模式**: MVVM

### 核心技术栈
- **数据存储**: UserDefaults + JSON序列化
- **UI组件**: SwiftUI原生组件
- **状态管理**: ObservableObject + @Published
- **日期处理**: Foundation Calendar API
- **数据导出**: CSV格式支持

### 设计模式
- **MVVM架构**: 清晰的数据绑定和状态管理
- **观察者模式**: 响应式数据更新
- **单例模式**: CycleManager全局数据管理
- **组合模式**: 模块化UI组件设计

## 📱 用户界面

### 主要页面
1. **首页 (HomeView)**
   - 用户选择器
   - 当前状态显示
   - 预测信息卡片
   - 快速操作按钮
   - 最近记录概览

2. **记录页 (RecordView)**
   - 月经记录表单和历史
   - 症状记录表单和历史
   - 记录删除功能
   - 数据可视化显示

3. **日历页 (CalendarView)**
   - 月历视图
   - 状态颜色编码
   - 日期详情弹窗
   - 快速导航

4. **设置页 (SettingsView)**
   - 用户管理
   - 数据管理
   - 应用配置
   - 关于信息

### 用户体验特色
- 🎨 现代化Material Design风格
- 🌸 温馨的粉色主题
- 📱 完全响应式布局
- 🔄 流畅的页面切换动画
- 💫 优雅的交互反馈
- ⚡ 快速操作支持

## 🚀 快速开始

### 环境要求
- Xcode 14.0+
- iOS 15.0+
- Swift 5.7+
- macOS 12.0+（开发环境）

### 安装和运行
1. **克隆项目**
```bash
git clone [项目地址]
cd yuejingjiance
```

2. **打开项目**
```bash
open yuejingjiance.xcodeproj
```

3. **构建和运行**
```bash
# 使用Xcode构建
xcodebuild -project yuejingjiance.xcodeproj -scheme YueJingJiance -destination "generic/platform=iOS Simulator" build

# 或直接在Xcode中运行 (⌘+R)
```

### 项目结构
```
yuejingjiance/
├── App.swift                 # 应用入口和生命周期
├── ContentView.swift         # 主视图容器和标签页
├── CycleManager.swift        # 数据模型和业务逻辑
├── HomeView.swift           # 首页视图和快速操作
├── RecordView.swift         # 记录管理视图
├── CalendarView.swift       # 日历视图和日期管理
├── SettingsView.swift       # 设置和配置视图
├── Info.plist              # 应用配置文件
├── Package.swift           # Swift包管理
└── README.md              # 项目文档
```

## 📋 使用指南

### 初次设置
1. 启动应用后自动创建默认用户
2. 在设置页面编辑用户信息
3. 配置个人周期参数
4. 开始记录数据

### 记录月经
**方法一：快速记录**
1. 在首页点击"记录月经"
2. 选择经血量等级
3. 确认记录

**方法二：详细记录**
1. 进入"记录"页面
2. 选择"月经记录"标签
3. 设置开始/结束日期
4. 选择经血量和添加备注
5. 保存记录

### 记录症状
**方法一：快速记录**
1. 在首页点击"记录症状"
2. 选择症状类型和严重程度
3. 确认记录

**方法二：详细记录**
1. 进入"记录"页面
2. 选择"症状记录"标签
3. 设置日期和症状类型
4. 调整严重程度（1-5级）
5. 添加详细描述并保存

### 删除记录
- 在记录页面的历史列表中
- 点击每条记录右侧的红色垃圾桶图标
- 即可删除对应的月经记录或症状记录

### 查看预测
- 首页显示下次月经预测时间
- 日历页面可视化显示预测周期
- 排卵期和安全期标识

### 用户管理
- 首页点击用户名快速切换
- 设置页面管理用户信息
- 支持多用户独立数据

## 🔒 隐私和安全

### 数据保护
- ✅ 100%本地数据存储
- ✅ 无网络数据传输
- ✅ 用户完全控制数据
- ✅ 支持数据导出和清除

### 权限说明
- 本应用不需要任何系统权限
- 不访问网络或其他应用数据
- 所有数据仅存储在应用沙盒内

## 🎯 版本特性

### 当前版本亮点
- ✨ 全新的快速操作体验
- 🗑️ 单独删除记录功能
- 🔄 优化的用户切换体验
- 📱 现代化的UI设计
- ⚡ 流畅的交互动画

### 已知问题
- 暂无已知问题

## 🤝 开发贡献

### 代码规范
- 遵循Swift官方编码规范
- 使用SwiftUI最佳实践
- 保持代码简洁和可读性
- 添加必要的注释说明

### 提交流程
1. Fork项目仓库
2. 创建功能分支
3. 完成开发和测试
4. 提交Pull Request

## 📞 支持和反馈

如有问题或建议，欢迎通过以下方式联系：
- 📧 邮箱反馈 zoujunyi@zjydiary.cn
- 🐛 GitHub Issues
- 💬 项目讨论区

---

**免责声明**: 本应用仅供个人健康记录参考，不能替代专业医疗建议。如有健康问题，请及时咨询医生。

**版权声明**: 本项目采用Apache 2.0开源许可证，欢迎自由使用和修改。
