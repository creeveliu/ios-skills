# iOS Skills Marketplace 发布清单

## ✅ 已完成配置

### 文件结构

```
.claude-plugin/
├── marketplace.json    # Marketplace 配置（定义插件列表）
├── plugin.json         # 插件清单（定义当前插件）
└── settings.json       # 插件设置
```

### Marketplace 配置

- **Marketplace 名称**: `ios-skills-marketplace`
- **插件名称**: `ios-skills`
- **版本**: 2.0.0
- **作者**: Clify
- **仓库**: https://github.com/creeveliu/ios-skills

## 📦 用户安装方式

```bash
# 添加 marketplace
/plugin marketplace add creeveliu/ios-skills

# 安装插件
/plugin install ios-skills@ios-skills-marketplace
```

## 🚀 发布步骤

### 1. 提交更改

```bash
git add .claude-plugin/
git commit -m "feat: 添加 marketplace 配置"
git push
```

### 2. 创建 Release（可选）

```bash
git tag v2.0.0
git push origin v2.0.0
```

### 3. 验证 Marketplace（可选）

用户可以本地验证：

```bash
# 添加本地 marketplace 测试
/plugin marketplace add ./path/to/ios-skills

# 安装插件
/plugin install ios-skills@ios-skills-marketplace

# 验证技能
/skill ios-architecture
```

## 📋 Marketplace 配置说明

### marketplace.json

```json
{
  "name": "ios-skills-marketplace",      // Marketplace 标识符
  "owner": {
    "name": "Clify"
  },
  "metadata": {
    "description": "iOS 开发最佳实践",
    "version": "2.0.0"
  },
  "plugins": [
    {
      "name": "ios-skills",               // 插件名称
      "source": "./",                     // 插件路径（相对于 marketplace）
      "description": "全面的 iOS 开发最佳实践技能包"
    }
  ]
}
```

### 添加更多插件

未来如需添加更多插件，只需在 `plugins` 数组中添加：

```json
{
  "plugins": [
    {
      "name": "ios-skills",
      "source": "./",
      "description": "iOS 开发最佳实践"
    },
    {
      "name": "ios-tools",
      "source": {
        "source": "github",
        "repo": "creeveliu/ios-tools"
      },
      "description": "iOS 开发工具集"
    }
  ]
}
```

## 🔧 用户更新方式

当 marketplace 更新时，用户执行：

```bash
# 更新 marketplace
/plugin marketplace update ios-skills-marketplace

# 或更新特定插件
/plugin update ios-skills@ios-skills-marketplace
```

## ⚠️ 注意事项

1. **Marketplace 名称**: 避免使用官方保留名称（如 `claude-code-marketplace`、`anthropic-plugins` 等）
2. **版本管理**: 确保 `plugin.json` 和 `marketplace.json` 中的版本一致
3. **相对路径**: `source: "./"` 表示插件在市场目录的根目录
4. **GitHub 访问**: 用户需要能访问你的 GitHub 仓库

## 📚 相关文档

- [Claude Code Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
