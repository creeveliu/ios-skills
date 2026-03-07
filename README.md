# iOS Skills

全面的 iOS 开发最佳实践技能包，涵盖架构开发、语言规范、性能优化、用户体验和质量保障。

## 技能列表

| 技能 | 说明 | 触发场景 |
|------|------|----------|
| `ios-architecture` | iOS 应用架构：MVVM/MVC/VIPER、依赖注入、模块化 | 项目结构、架构设计 |
| `uikit-best-practices` | UIKit 开发：ViewController、Auto Layout、列表控件 | UITableView、UIViewController |
| `swiftui-best-practices` | SwiftUI 开发：状态管理、View 组合、声明式 UI | SwiftUI、@State、View |
| `swift-language` | Swift 语言：语法、内存管理、并发、泛型、协议 | Swift 语法、async/await |
| `objective-c-language` | Objective-C 语言：ARC、Blocks、Categories、Runtime | OC 代码、Blocks、Swift 混编 |
| `networking-data` | 网络与数据：URLSession、Codable、本地存储 | 网络请求、数据持久化 |
| `app-stability` | 稳定性与崩溃：崩溃预防、异常处理、线程安全 | 崩溃排查、稳定性优化 |
| `performance-optimization` | 性能优化：启动、内存、渲染、电量 | 性能分析、卡顿优化 |
| `user-experience` | 用户体验：动画、触觉反馈、无障碍、深色模式 | 动画、Accessibility |
| `testing-debugging` | 测试与调试：单元测试、UI 测试、Instruments | 写测试、调试问题 |
| `code-style-guide` | 代码风格：Swift/ObjC 格式、命名、注释 | 代码格式、命名规范 |

## 安装

### 从 GitHub 安装

```bash
/plugin install ios-skills@creeveliu/ios-skills
```

### 本地安装（开发测试用）

技能文件已在 `skills/` 目录，可手动复制到目标项目：

```bash
cp -r skills/* /path/to/project/.claude/skills/
```

## 使用

技能会根据对话内容**自动触发**。例如：

- 问："UITableView 怎么实现分组" → 触发 `uikit-best-practices`
- 问："Swift async/await 怎么用" → 触发 `swift-language`
- 问："App 启动慢怎么优化" → 触发 `performance-optimization`
- 问："崩溃怎么排查" → 触发 `app-stability`

也可手动触发：
```
/skill swift-language
```

## 技能分类

```
架构基础
├── ios-architecture
├── swift-language
└── objective-c-language

UI 开发
├── uikit-best-practices
└── swiftui-best-practices

数据与网络
└── networking-data

质量保障
├── app-stability
├── performance-optimization
├── user-experience
├── testing-debugging
└── code-style-guide
```

## 版本

当前版本：2.0.0

## 许可

MIT License
