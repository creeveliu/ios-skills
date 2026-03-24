# iOS Skills

一组面向 iOS 开发的实用 skills，覆盖架构、UIKit、SwiftUI、Swift、Objective-C、网络、稳定性、性能、用户体验、测试调试，以及基于 Blitz 的通用 App 冒烟测试。

## 安装到你的项目

```bash
npx skills add creeveliu/ios-skills
```

## 技能列表

安装后可自动触发以下 skills：

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

用于在任意 iOS 项目中执行通用 App 冒烟测试。

- 通过自然语言触发，例如：`帮我测一下这个 App`
- 自动探测工程、scheme、测试手册和现有测试
- 检测到有实际内容的现有测试时，先提示用户是否跳过
- 缺少 Blitz 时提示按官方方式安装
- Blitz 安装失败直接终止，不降级

## 版本

当前版本：2.1.0

## 仓库

- 主仓库：https://github.com/creeveliu/ios-skills
