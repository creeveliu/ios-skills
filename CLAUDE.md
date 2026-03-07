# iOS Skills Plugin

本项目是一个 Claude Code Skills Plugin，包含 11 个 iOS 开发最佳实践技能。

## 安装到你的项目

在你的项目根目录创建 `.claude/settings.local.json`，添加：

```json
{
  "plugins": [
    "creeveliu/ios-skills"
  ]
}
```

然后运行：

```bash
/plugin install ios-skills@creeveliu/ios-skills
```

或者在 Claude Code 中输入：

```
/plugin install ios-skills@creeveliu/ios-skills
```

## 技能列表

安装后，以下技能会自动触发：

- `ios-architecture` - MVVM/MVC、依赖注入、模块化
- `uikit-best-practices` - ViewController、Auto Layout、列表控件
- `swiftui-best-practices` - 状态管理、View 组合
- `swift-language` - Swift 语法、并发、泛型
- `objective-c-language` - ARC、Blocks、Categories
- `networking-data` - URLSession、Codable、持久化
- `app-stability` - 崩溃预防、异常处理、线程安全
- `performance-optimization` - 启动、内存、渲染优化
- `user-experience` - 动画、触觉、无障碍
- `testing-debugging` - 单元测试、UI 测试、Instruments
- `code-style-guide` - 代码格式、命名规范

## 版本

当前版本：2.0.0
