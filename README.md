# Parchment

一个基于 Swift 构建的 iOS 小说/文本阅读器框架，支持仿真翻页与平移翻页、多主题、书签、章节目录、阅读进度等功能。

---

## 功能特性

- 📖 **双翻页模式** — 仿真翻页（Page Curl）与左右平移（Scroll）自由切换
- 🎨 **多主题** — 内置淡薄荷绿、浅灰蓝、燕麦色、米白色、曜石黑五套主题
- 🔖 **书签管理** — 支持添加/移除书签，书签列表快速跳转
- 📑 **章节目录** — 自动解析章节，支持目录快速跳转
- 📊 **阅读进度** — 进度条拖拽跳转，实时显示当前页/总页数
- 🔆 **亮度调节** — 应用内独立亮度控制
- 🔤 **字体设置** — 字体大小与字体名称可调
- 💾 **自动缓存** — 基于 Core Data 缓存分页结果，二次打开秒开
- 🌐 **编码自动识别** — 集成 [Uchardet](https://github.com/okferret/Uchardet.git) 自动检测文件编码
- 📐 **安全区域适配** — 自动适配刘海屏/灵动岛安全区域

---

## 系统要求

| 平台 | 最低版本 |
|------|---------|
| iOS | 13.0+ |
| tvOS | 13.0+ |
| watchOS | 6.0+ |
| visionOS | 1.0+ |

> **注意**：UI 相关功能（`ParchmentViewController` 等）仅在 iOS 上可用，需要 `UIKit`。

---

## 安装

### Swift Package Manager

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/okferret/Parchment.git", .upToNextMajor(from: "1.0.0"))
]
```

或在 Xcode 中通过 **File → Add Package Dependencies** 搜索并添加。

---

## 快速开始

### 基本使用

```swift
import Parchment

// 获取书籍文件 URL
let fileURL: URL = // 你的 .txt 文件路径

// 使用默认配置创建阅读器
let reader = ParchmentViewController(forWhat: fileURL)

// 全屏展示
present(reader, animated: true)
```

### 自定义配置

```swift
import Parchment

let fileURL: URL = // 你的 .txt 文件路径

// 获取当前配置（配置会自动持久化到 UserDefaults）
let config = Configuration.current()

// 创建阅读器
let reader = ParchmentViewController(forWhat: fileURL, configuration: config)
present(reader, animated: true)
```

### 书籍文件目录

框架提供了一个专用的书籍存储目录：

```swift
// 获取推荐的书籍存储目录
let booksDir: URL = Configuration.dirURL
```

### 清理书籍缓存

```swift
// 清理指定书籍的分页缓存（字体/屏幕尺寸变化后可调用）
BookHelper.cleanWith(fileURL)
```

---

## 架构说明

```
Parchment
├── ParchmentViewController     # 主阅读控制器（UINavigationController 子类）
├── ContentViewController       # 单页内容渲染（Core Text 绘制）
├── Configuration               # 阅读配置（主题/字体/翻页方式/亮度）
├── BookHelper                  # 书籍解析与 Core Data 管理
│   ├── BookParser              # 书籍元数据解析
│   ├── ChapterParser           # 章节目录解析
│   └── TextPaginator           # 文本分页算法
└── MenuViewController          # 菜单系统
    ├── ChapterViewController   # 章节目录面板
    ├── BookmarkViewController  # 书签列表面板
    ├── ProgressViewController  # 进度控制面板
    └── ConfigureViewController # 设置面板（主题/字体/翻页）
```

---

## 主题

框架内置 5 套阅读主题：

| 主题名 | 说明 |
|--------|------|
| `paleMint` | 淡薄荷绿（默认） |
| `powderBlue` | 浅灰蓝 |
| `oatmeal` | 燕麦色 |
| `offWhite` | 米白色 |
| `jetBlack` | 曜石黑（夜间模式） |

---

## 翻页方式

| 枚举值 | 说明 |
|--------|------|
| `TransitionStyle.pageCurl` | 仿真翻页 |
| `TransitionStyle.scroll` | 左右平移 |

---

## 手势交互

在 **平移翻页** 模式下，支持点击区域翻页：

| 点击区域 | 行为 |
|----------|------|
| 左侧 1/3 | 上一页 |
| 右侧 1/3 | 下一页 |
| 中间 1/3 | 显示/隐藏菜单栏 |

---

## 阅读进度通知

翻页时会发送进度通知，可在外部监听：

```swift
NotificationCenter.default.addObserver(
    forName: BookHelper.progressNotification,
    object: nil,
    queue: .main
) { notification in
    let userInfo = notification.userInfo
    let currentIndex = userInfo?["currentIndex"] as? Int64
    let totalUnitCount = userInfo?["totalUnitCount"] as? Int64
    // 处理进度更新
}
```

---

## 依赖

| 库 | 用途 |
|----|------|
| [Uchardet](https://github.com/okferret/Uchardet.git) | 文本文件编码自动识别 |

---

## License

本项目基于 [LICENSE](LICENSE) 协议开源。
