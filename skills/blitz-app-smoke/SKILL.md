---
name: blitz-app-smoke
description: 当用户希望用一句自然语言测试、冒烟验证或验收一个 iOS App，并且不想手动安装或学习 Blitz 时使用。
---

# Blitz App Smoke

当用户希望通过一句自然语言请求，例如 `帮我测一下这个 App`，来测试一个 iOS App 时，使用这个 skill。

## 目标

这个 skill 会把 Blitz 隐藏成内部依赖。

用户不应该需要：

- 知道 Blitz 是什么
- 学习模拟器或 `xcodebuild` 命令

## 强规则

Blitz 是强依赖。

- 如果缺少 Blitz，就立刻停止，并提示用户按官方方式安装。
- 不要降级为只用 `simctl` 的测试路径，也不要切到别的 UI 自动化方案。

## 执行模型

以当前工作目录作为 iOS 项目根目录，运行这个 skill 内置的单文件脚本：

```bash
bash run.sh run
```

orchestrator 负责：

- 环境检查
- Blitz bootstrap
- iOS 工程探测
- 可选的 Xcode MCP 辅助探测
- 现有测试识别与执行
- 测试手册解析
- Blitz 执行
- 统一报告输出

## 必须遵守的流程

触发后：

1. 确认当前工作区是 iOS 工程，或包含 iOS 工程。
2. 从这个 skill 目录运行 `run.sh` 的 `prepare` 或 `run`。
3. 如果缺少 Blitz，立即报错，并提示用户从官方来源安装。
4. 如果项目里存在测试手册，优先按手册执行。
5. 在执行 Blitz 前，先跑有实际内容的单元测试和 UI 测试。
6. 即使这些测试失败，也继续执行 Blitz。
7. 最终返回一份合并结果，明确标出 `passed`、`failed`、`skipped`。

## 现有测试规则

只执行对当前项目有实际覆盖价值的测试。

只有模板内容的 Xcode 测试必须报告为：

`skipped (template-only)`

现有测试失败是重要信号，但不能阻塞 Blitz 执行。

## 测试手册规则

测试手册优先级：

1. `codex.blitz.toml` 里显式配置的手册路径
2. 在常规文档目录中自动发现且唯一的测试手册
3. skill 内置的默认 Blitz smoke manual

如果发现多份候选手册，但配置没有消歧，就停止并报告歧义。

## 可选配置

如果仓库里存在 `codex.blitz.toml`，可用它指定：

- project 或 workspace 路径
- scheme
- 模拟器名称
- 测试手册路径
- 是否允许回退到内置默认手册
- 是否跳过 unit tests 或 UI tests

示例配置见 [templates/codex.blitz.toml.example](templates/codex.blitz.toml.example)

## 失败时的提示方式

如果缺少 Blitz 或 Blitz 不可用，面向用户的提示要短且可执行：

- 从官网下载安装 Blitz
- 或从官方 GitHub 仓库构建/安装 Blitz
- 安装完成后重试

如果缺少必要的 Apple 工具链，要明确指出缺的是哪个命令，例如：

- `xcodebuild`
- `xcrun`
- `simctl`

## 输出要求

最终结果应包含：

- 环境准备结果
- 发现到的 project 和 scheme
- Blitz 安装结果
- unit test 结果
- UI test 结果
- 使用的测试手册来源
- Blitz 执行结果
- 最终结论

## 备注

- 如果有 Xcode MCP，优先使用，但不要把它当成硬依赖。
- Blitz 是唯一的强自动化依赖。
- 用户说的是任务语言，不是工具语言。对外接口也保持这个层级。
