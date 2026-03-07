---
name: performance-optimization
description: iOS performance optimization best practices. Use this skill whenever the user mentions performance, optimization, app launch, memory, FPS, rendering, battery, instruments, or app responsiveness.
---

# 性能优化最佳实践

本技能提供 iOS 应用性能优化的标准工作流程和最佳实践。

## 核心原则

1. **测量优先** - 先 profiling 再优化
2. **关键路径** - 优先优化用户体验最敏感的部分
3. **空间换时间** - 合理使用缓存
4. **懒加载** - 按需加载资源
5. **批量处理** - 减少 UI 更新频率

---

## 启动优化

### 启动流程分析

```
┌─────────────────────────────────────────────────────┐
│  冷启动流程：                                        │
│  1. dyld 加载 → 2. Rebase/Bind → 3. ObjC 初始化    │
│  4. +load 方法 → 5. C++ 静态初始化 → 6. AppDelegate │
│  7. UIWindow 创建 → 8. RootViewController → 9. 首屏渲染 │
└─────────────────────────────────────────────────────┘
```

### 优化方案

```swift
// ✅ 正确：延迟非关键初始化
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // 关键路径：尽快显示首屏
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = RootViewController()
        window?.makeKeyAndVisible()

        // 非关键：异步初始化
        DispatchQueue.main.async {
            self.setupNonCriticalServices()
        }

        return true
    }

    private func setupNonCriticalServices() {
        // 延迟初始化非关键服务
        AnalyticsManager.setup()
        CrashReporter.setup()
        FeedbackManager.setup()
    }
}
```

### 减少 dyld 加载时间

```swift
// ✅ 正确：减少 +load 方法使用
// 在 Category/Base 类中避免使用 +load，改用 +initialize

// ❌ 错误：在 +load 中做耗时操作
+ (void)load {
    [self expensiveSetup];  // 阻塞启动
}

// ✅ 正确：使用 dispatch_once 延迟初始化
+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setup];
    });
}
```

### 图片加载优化

```swift
// ✅ 正确：使用渐进式加载
class ImageView: UIView {

    func loadImage(url: URL) {
        // 1. 先显示低分辨率缩略图
        thumbnailImageView.image = placeholder

        // 2. 异步加载原图
        DispatchQueue.global(qos: .userInitiated).async {
            let data = try? Data(contentsOf: url)
            let image = UIImage(data: data!)

            // 3. 主线程更新
            DispatchQueue.main.async {
                UIView.transition(with: self,
                                  duration: 0.2,
                                  options: .transitionCrossDissolve,
                                  animations: {
                    self.imageView.image = image
                })
            }
        }
    }
}
```

---

## 内存优化

### 图片内存优化

```swift
// ✅ 正确：图片解码在后台
func loadImage() {
    DispatchQueue.global(qos: .userInitiated).async {
        // 预解码图片（避免在主线程解码）
        let image = UIImage(contentsOfFile: path)!
        _ = image.cgImage?.dataProvider?.data

        DispatchQueue.main.async {
            imageView.image = image
        }
    }
}

// ✅ 正确：使用 Image Cache
let imageCache = NSCache<NSString, UIImage>()
imageCache.countLimit = 100
imageCache.totalCostLimit = 1024 * 1024 * 50  // 50MB

// ✅ 正确：大图使用 downsampling
func downsample(imageAt imageURL: URL, to pointSize: CGSize, scale: CGFloat) -> UIImage {
    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions) else {
        return UIImage()
    }

    let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
    let downsampleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
    ] as CFDictionary

    guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
        return UIImage()
    }

    return UIImage(cgImage: downsampledImage)
}
```

### 减少内存峰值

```swift
// ✅ 正确：使用 autorelease pool 处理大量临时对象
func processLargeData() {
    for chunk in dataChunks {
        autoreleasepool {
            // 临时对象在 pool 结束后释放
            let processed = process(chunk)
            save(processed)
        }
    }
}

// ✅ 正确：延迟加载大对象
class DataViewController: UIViewController {

    private lazy var largeData: Data = {
        // 只在需要时加载
        return loadLargeData()
    }()

    private var _largeData: Data?
    func loadLargeData() -> Data {
        // 加载逻辑
    }
}
```

### 检测内存泄漏

```swift
// ✅ 正确：使用 weak 检测循环引用
class ViewController: UIViewController {

    deinit {
        // 如果没打印，说明有循环引用
        print("\(type(of: self)) deinitialized")
    }
}

// Instruments 检测：
// 1. Allocations - 内存分配
// 2.Leaks - 内存泄漏
// 3. VM Tracker - 虚拟内存
```

---

## 渲染性能

### 保持 60 FPS

```swift
// ✅ 正确：避免在主线程做耗时操作
func tableView(_ tableView: UITableView,
               cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

    // ❌ 错误：主线程图片解码
    // cell.imageView?.image = loadImage(from: url)

    // ✅ 正确：异步图片加载
    cell.imageView?.image = placeholder
    loadImageAsync(url: url) { image in
        cell.imageView?.image = image
    }

    return cell
}
```

### 减少离屏渲染

```swift
// ✅ 正确：使用 CAShapeLayer 代替圆角
class RoundedView: UIView {

    private let borderLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    private func setupLayer() {
        borderLayer.path = UIBezierPath(roundedRect: bounds,
                                         cornerRadius: 12).cgPath
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.black.cgColor
        borderLayer.lineWidth = 2
        layer.addSublayer(borderLayer)
    }

    // ❌ 避免：离屏渲染
    // layer.cornerRadius = 12
    // layer.masksToBounds = true
}
```

### 批量更新

```swift
// ✅ 正确：批量插入减少动画次数
func insertItems() {
    tableView.beginUpdates()
    tableView.insertRows(at: indexPaths, with: .automatic)
    tableView.endUpdates()
}

// ✅ 正确：禁用动画提升性能
UIView.performWithoutAnimation {
    // 批量更新代码
    self.tableView.reloadData()
    self.layoutIfNeeded()
}
```

---

## 网络优化

### 请求合并

```swift
// ✅ 正确：合并多个请求
func loadUserData() async throws -> UserData {
    // ❌ 错误：串行请求
    // let user = try await fetchUser()
    // let posts = try await fetchPosts(userId: user.id)
    // let stats = try await fetchStats(userId: user.id)

    // ✅ 正确：并行请求
    async let user = fetchUser()
    async let posts = fetchPosts(userId: user.id)
    async let stats = fetchStats(userId: user.id)

    return try await UserData(user: user, posts: posts, stats: stats)
}
```

### 缓存策略

```swift
// ✅ 正确：使用 URLCache
let cache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 100_000_000)
URLCache.shared = cache

let session = URLSession(configuration: {
    let config = URLSessionConfiguration.default
    config.requestCachePolicy = .returnCacheDataElseLoad
    config.urlCache = cache
    return config
}())

// ✅ 正确：ETag 验证
func fetchData(withETag etag: String?) async throws -> (Data, String) {
    var request = URLRequest(url: apiURL)
    if let etag = etag {
        request.setValue(etag, forHTTPHeaderField: "If-None-Match")
    }

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
    }

    if httpResponse.statusCode == 304 {
        // 使用缓存
        return (cachedData, cachedETag)
    }

    let newETag = httpResponse.allHeaderFields["ETag"] as? String
    return (data, newETag ?? "")
}
```

---

## 电量优化

### 减少 CPU 使用

```swift
// ✅ 正确：停止不必要的定时器
class ViewController: UIViewController {

    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        startTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()  // 页面不可见时停止
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
```

### 位置服务优化

```swift
// ✅ 正确：按需请求位置
class LocationManager: NSObject {

    func startUpdatingLocation(accuracy: LocationAccuracy) {
        switch accuracy {
        case .navigation:
            // 高精度，耗电
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 10
        case .visit:
            // 低精度，省电
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 100
        }
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}
```

---

## Instruments 使用

### 性能分析流程

```
1. Time Profiler - 找到 CPU 瓶颈
2. Allocations - 分析内存分配
3. Leaks - 检测内存泄漏
4. Energy Log - 电量消耗分析
5. Network - 网络请求分析
```

### 关键指标

| 指标 | 目标值 | 工具 |
|------|--------|------|
| 启动时间 | < 1s | os_signpost |
| FPS | 60 (不低于 45) | Core Animation |
| 内存峰值 | < 设备限制 50% | Allocations |
| CPU 使用 | < 20% | Activity Monitor |
| 网络延迟 | < 500ms | Network Link Conditioner |

---

## 检查清单

在发布前，请确认：

- [ ] 启动时间已优化（冷启动 < 1s）
- [ ] 无明显卡顿（FPS 稳定 60）
- [ ] 内存泄漏已修复
- [ ] 图片已压缩和缓存
- [ ] 网络请求已优化（缓存、合并）
- [ ] 后台任务已正确管理
- [ ] 电量消耗已测试

---

## 参考资源

- [WWDC Performance](https://developer.apple.com/videos/performance/)
- [Instruments](https://developer.apple.com/documentation/instruments)
- [App Thinning](https://developer.apple.com/documentation/xcode/app_thinning)
