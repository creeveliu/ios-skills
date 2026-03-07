---
name: user-experience
description: iOS user experience best practices. Use this skill whenever the user mentions UX, user experience, animations, haptic feedback, accessibility, localization, dark mode, or app polish.
---

# 用户体验最佳实践

本技能提供 iOS 应用用户体验优化的标准工作流程和最佳实践。

## 核心原则

1. **遵循 HIG** - Apple Human Interface Guidelines
2. **即时反馈** - 用户操作必有响应
3. **流畅动画** - 60 FPS，符合物理规律
4. **无障碍** - 包容性设计，人人可用
5. **本地化** - 全球用户，多语言支持

---

## 动画设计

### 基础动画

```swift
// ✅ 正确：使用 UIView 动画
UIView.animate(withDuration: 0.3,
               delay: 0,
               usingSpringWithDamping: 0.7,
               initialSpringVelocity: 0.8,
               options: .curveEaseOut) {
    self.button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
} completion: { _ in
    UIView.animate(withDuration: 0.1) {
        self.button.transform = .identity
    }
}

// ✅ 正确：动画 spring 参数参考
// 平滑：damping 0.6-0.8, velocity 0.5-1.0
// 弹跳：damping 0.4-0.6, velocity 1.0-2.0
```

### 关键帧动画

```swift
// ✅ 正确：复杂动画使用关键帧
UIView.animateKeyframes(withDuration: 1.0, delay: 0) {

    // 第一阶段：放大
    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) {
        self.view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
    }

    // 第二阶段：旋转
    UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.4) {
        self.view.transform = CGAffineTransform(rotationAngle: .pi / 4)
    }

    // 第三阶段：恢复
    UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.3) {
        self.view.transform = .identity
    }

} completion: { _ in
    print("动画完成")
}
```

### 物理动画

```swift
// ✅ 正确：使用 UIDynamicAnimator 实现物理效果
class BounceView: UIView {

    private var animator: UIDynamicAnimator!
    private var gravity: UIGravityBehavior!
    private var collision: UICollisionBehavior!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPhysics()
    }

    private func setupPhysics() {
        animator = UIDynamicAnimator(referenceView: self)

        gravity = UIGravityBehavior()
        animator.addBehavior(gravity)

        collision = UICollisionBehavior()
        collision.translatesReferenceBoundsIntoBoundary = true
        animator.addBehavior(collision)
    }

    func addBall(at point: CGPoint) {
        let ball = UIView(frame: CGRect(x: point.x, y: point.y, width: 40, height: 40))
        ball.backgroundColor = .systemBlue
        ball.layer.cornerRadius = 20
        addSubview(ball)

        gravity.addItem(ball)
        collision.addItem(ball)
    }
}
```

---

## 触觉反馈

### Haptic Feedback

```swift
// ✅ 正确：使用 UIImpactFeedbackGenerator
class FeedbackManager {

    // 轻触反馈
    static func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // 中等反馈
    static func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    // 成功反馈
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // 错误反馈
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // 警告反馈
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}

// 使用场景
button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

@objc func buttonTapped() {
    FeedbackManager.lightTap()  // 点击反馈
    // 执行操作...
}
```

### 自定义触觉模式

```swift
// ✅ 正确：创建自定义触觉模式（iOS 10+）
func playCustomHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .heavy)

    // 准备反馈（预加热，减少延迟）
    generator.prepare()

    // 准备完成后触发
    generator.impactOccurred()

    // 使用后进化
    generator.prepare()
}
```

---

## 加载状态

### 骨架屏

```swift
// ✅ 正确：实现骨架屏
class SkeletonView: UIView {

    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSkeleton()
    }

    private func setupSkeleton() {
        backgroundColor = .systemGray5
        layer.cornerRadius = 8

        gradientLayer.colors = [
            UIColor.systemGray5.cgColor,
            UIColor.systemGray4.cgColor,
            UIColor.systemGray5.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = bounds
        layer.addSublayer(gradientLayer)

        startAnimating()
    }

    private func startAnimating() {
        let animation = CABasicAnimation(keyPath: "positions")
        animation.fromValue = -1.0
        animation.toValue = 2.0
        animation.duration = 1.5
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "skeleton")
    }

    func stopAnimating() {
        gradientLayer.removeAnimation(forKey: "skeleton")
    }
}
```

### 进度指示

```swift
// ✅ 正确：选择合适的加载指示器
class LoadingManager {

    // 短时间操作 (< 1s) - 不显示
    func quickAction() {
        // 直接执行，无需 loading
    }

    // 中等时间 (1-3s) - UIActivityIndicatorView
    func moderateAction() {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        // 显示在按钮或导航栏
    }

    // 长时间 (> 3s) - 全屏 loading + 进度
    func longAction() {
        let loadingView = LoadingOverlay()
        loadingView.showProgress(0.3)  // 显示进度
        // 更新进度...
    }

    // 后台任务 - 系统级提示
    func backgroundAction() {
        // 使用 BackgroundTask
    }
}
```

---

## 错误提示

### 友好的错误信息

```swift
// ✅ 正确：用户友好的错误提示
extension NetworkError {
    var userMessage: String {
        switch self {
        case .networkUnavailable:
            return "网络连接已断开，请检查网络设置后重试"
        case .timeout:
            return "请求超时，网络可能较慢，请重试"
        case .unauthorized:
            return "登录已过期，请重新登录"
        case .notFound:
            return "内容不存在或已被删除"
        default:
            return "出了点问题，请稍后重试"
        }
    }
}

// ✅ 正确：错误恢复建议
func showError(_ error: Error) {
    let alert = UIAlertController(
        title: "加载失败",
        message: error.userMessage,
        preferredStyle: .alert
    )

    alert.addAction(UIAlertAction(title: "重试", style: .default) { _ in
        self.retry()
    })

    alert.addAction(UIAlertAction(title: "稍后", style: .cancel))

    present(alert, animated: true)
}
```

---

## 无障碍 (Accessibility)

### VoiceOver 支持

```swift
// ✅ 正确：设置无障碍标签
class CustomButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAccessibility()
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityLabel = "提交"  // 朗读内容
        accessibilityHint = "双击提交表单"  // 操作提示
        accessibilityTraits = .button
    }

    // ✅ 正确：动态更新状态
    func setLoading(_ loading: Bool) {
        if loading {
            accessibilityLabel = "加载中"
            accessibilityTraits = .updatesFrequently
        } else {
            accessibilityLabel = "提交"
            accessibilityTraits = .button
        }
    }
}
```

### 无障碍分组

```swift
// ✅ 正确：相关元素分组
class ProfileCard: UIView {

    let avatarImageView = UIImageView()
    let nameLabel = UILabel()
    let emailLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAccessibility()
    }

    private func setupAccessibility() {
        // 将头像、姓名、邮箱作为一个整体
        accessibilityElements = [avatarImageView, nameLabel, emailLabel]

        avatarImageView.isAccessibilityElement = true
        avatarImageView.accessibilityLabel = "用户头像"

        nameLabel.isAccessibilityElement = true
        emailLabel.isAccessibilityElement = true
    }
}
```

### 动态字体

```swift
// ✅ 正确：支持动态字体
class DynamicLabel: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDynamicFont()
    }

    private func setupDynamicFont() {
        font = UIFont.preferredFont(forTextStyle: .body)
        adjustsFontForContentSizeCategory = true
    }
}

// 监听字体变化
NotificationCenter.default.addObserver(
    self,
    selector: #selector(contentSizeChanged),
    name: UIContentSizeCategory.didChangeNotification,
    object: nil
)

@objc private func contentSizeChanged() {
    // 重新布局
}
```

---

## 深色模式

### 适配 Dark Mode

```swift
// ✅ 正确：使用系统颜色
class ThemedView: UIView {

    private let label = UILabel()
    private let backgroundView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        // 自动适配深色模式
        backgroundColor = .systemBackground
        label.textColor = .label
        backgroundView.backgroundColor = .systemGray5
    }
}

// ✅ 正确：自定义颜色
extension UIColor {
    static var customPrimary: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1)
                : UIColor(red: 0.0, green: 0.4, blue: 0.8, alpha: 1)
        }
    }
}
```

---

## 本地化

### 多语言支持

```swift
// ✅ 正确：使用 Localizable.strings
// Localizable.strings (en)
"welcome_message" = "Welcome!";
"items_count" = "%d items";

// Localizable.strings (zh)
"welcome_message" = "欢迎！";
"items_count" = "%d 个项目";

// 使用
label.text = NSLocalizedString("welcome_message", comment: "欢迎消息")
let countText = String(format: NSLocalizedString("items_count", comment: ""), itemCount)

// ✅ 正确：Swift 5+ 字符串插值
let text = String(localized: "Hello, \(name)!", comment: "问候语")
```

### 复数形式

```swift
// ✅ 正确：处理复数形式
// Localizable.stringsdict
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>items_count</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%#@items@</string>
        <key>items</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>zero</key><string>没有项目</string>
            <key>one</key><string>%d 个项目</string>
            <key>other</key><string>%d 个项目</string>
        </dict>
    </dict>
</dict>
</plist>
```

---

## 检查清单

在发布前，请确认：

- [ ] 动画流畅（60 FPS）
- [ ] 触觉反馈适当
- [ ] 加载状态清晰
- [ ] 错误提示友好
- [ ] VoiceOver 可用
- [ ] 动态字体支持
- [ ] 深色模式适配
- [ ] 多语言本地化

---

## 参考资源

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Accessibility Programming Guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/iPhoneAccessibility/)
- [Localization and Internationalization](https://developer.apple.com/documentation/xcode/localization-and-internationalization)
