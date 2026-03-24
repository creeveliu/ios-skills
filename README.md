# iOS Skills

一组面向 iOS 开发的实用 skills，覆盖架构、UIKit、SwiftUI、Swift、Objective-C、网络、稳定性、性能、用户体验、测试调试，以及基于 Blitz 的通用 App 冒烟测试。

## 安装到你的项目

```bash
npx skills add creeveliu/ios-skills
```

## 使用

安装后会根据上下文自动触发，也可以按需手动调用对应 skill。

- 问："UITableView 怎么实现分组" → 触发 `uikit-best-practices`
- 问："Swift async/await 怎么用" → 触发 `swift-language`
- 问："App 启动慢怎么优化" → 触发 `performance-optimization`
- 问："崩溃怎么排查" → 触发 `app-stability`
- 问："帮我测一下这个 App" → 触发 `blitz-app-smoke`

## 包含的 skills

- `ios-architecture`
- `uikit-best-practices`
- `swiftui-best-practices`
- `swift-language`
- `objective-c-language`
- `networking-data`
- `app-stability`
- `performance-optimization`
- `user-experience`
- `testing-debugging`
- `code-style-guide`
- `blitz-app-smoke`

## `blitz-app-smoke`

这个 skill 用来做通用 iOS App 冒烟测试。

- 用户只需要说一句：`帮我测一下这个 App`
- skill 会在当前项目目录自动探测 iOS 工程
- 如果缺少 Blitz，会直接提示用户按官方方式安装
- 如果项目里有测试手册，优先按测试手册执行
- 如果项目里有有实际内容的 unit test 或 UI test，会先提示用户是运行还是跳过，不会默认执行

## 版本

当前版本：2.1.0

## 仓库

- 主仓库：https://github.com/creeveliu/ios-skills

## 许可

MIT License
