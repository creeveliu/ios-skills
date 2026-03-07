---
name: code-style-guide
description: iOS code style guide for Swift and Objective-C. Use this skill whenever the user mentions code style, formatting, naming conventions, code organization, Swift/Objective-C coding standards, indentation, comments, or needs to enforce consistent code quality across the project. This skill covers formatting rules, naming patterns, documentation standards, and file organization.
---

# iOS 编码规范

本规范适用于 Swift 和 Objective-C 项目，确保代码风格一致性和可维护性。

---

## 格式规范

### 缩进

**Swift**: 使用 4 个空格，不使用 Tab

```swift
// ✅ 正确
struct User {
    let name: String
    let age: Int

    func greet() {
        if age >= 18 {
            print("Hello, \(name)!")
        }
    }
}

// ❌ 错误：使用 Tab
// ❌ 错误：2 空格缩进
struct User {
  let name: String
}
```

**Objective-C**: 使用 4 个空格

```objective-c
// ✅ 正确
@implementation User {
    NSString *_name;
    NSInteger _age;
}

- (void)greet {
    if (_age >= 18) {
        NSLog(@"Hello, %@!", _name);
    }
}

@end
```

### 大括号

**Swift**: 左大括号与声明在同一行

```swift
// ✅ 正确
class ViewController: UIViewController {
    func viewDidLoad() {
        super.viewDidLoad()
    }
}

// ❌ 错误：左大括号独占一行
class ViewController: UIViewController
{
}
```

**Objective-C**: 左大括号独占一行

```objective-c
// ✅ 正确
@implementation ViewController
{
    // 实例变量
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

@end
```

### 空行

**Swift**:

```swift
// ✅ 正确：逻辑块之间空一行
class ViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var submitButton: UIButton!

    private var viewModel: ViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        titleLabel.text = "Title"
    }

    @IBAction private func submitTapped(_ sender: UIButton) {
        viewModel?.submit()
    }
}

// ❌ 错误：过多空行
class ViewController: UIViewController {


    @IBOutlet private weak var titleLabel: UILabel!


    // ❌ 错误：没有空行分隔
    private var viewModel: ViewModel?
    override func viewDidLoad() {
```

### 行宽

- **建议最大行宽**: 120 字符
- **必须换行**: 超过 140 字符

```swift
// ✅ 正确：长参数换行
func configure(with model: UserViewModel,
               animated: Bool,
               completion: (() -> Void)? = nil) {
    // ...
}

// ✅ 正确：长链式调用换行
label.textColor = .label
    .withAlphaComponent(0.8)
    .aligned(to: .center)
```

### 空格

```swift
// ✅ 正确：操作符两侧有空格
let sum = a + b
let result = x * y + z

// ✅ 正确：逗号后有空格
let array = [1, 2, 3]
let dict = ["a": 1, "b": 2]

// ✅ 正确：冒号后有空格（字典）
let dict = ["key": "value"]

// ✅ 正确：参数标签冒号后无空格
func greet(name: String, age: Int) { }

// ❌ 错误
let sum=a+b
let array = [1,2,3]
```

---

## 命名规范

### Swift 命名

```swift
// ✅ 正确：类型使用 PascalCase
class UserManager { }
protocol DataSource { }
enum ResultType { }

// ✅ 正确：变量/函数使用 camelCase
let userName = "John"
func calculateTotal() -> Int { }

// ✅ 正确：常量使用 camelCase（与 Swift 标准库一致）
let maximumCount = 100
static let shared = UserManager()

// ✅ 正确：布尔类型使用 is/has/should/can 前缀
var isLoading = false
var hasContent = true
var shouldUpdate = false

// ✅ 正确：OptionSet 使用名词复数
struct ShippingOptions: OptionSet {
    let rawValue: Int
    static let nextDay = ShippingOptions(rawValue: 1 << 0)
    static let sameDay = ShippingOptions(rawValue: 1 << 1)
}

// ❌ 错误
class user_manager { }  // 不应使用下划线
let UserName = "John"   // 变量不应大写开头
```

### Objective-C 命名

```objective-c
// ✅ 正确：类名使用 PascalCase，带前缀
@interface ABCUserManager : NSObject
@end

// ✅ 正确：方法使用动词开头
- (void)saveData;
- (NSString *)userName;
- (BOOL)isValid;

// ✅ 正确：参数命名清晰
- (void)insertObject:(id)object atIndex:(NSUInteger)index;

// ✅ 正确：属性命名
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;

// ✅ 正确：常量命名
extern NSString * const ABCUserDidLoginNotification;
extern const CGFloat ABCMaxItemCount;

// ❌ 错误
- (void)dataSave;      // 动词应在前
- (NSString *)username; // 驼峰命名
```

### 文件命名

```swift
// ✅ 正确：文件名与主类型一致
// ViewController.swift - 包含 ViewController 类
// UserViewModel.swift - 包含 UserViewModel 类
// NetworkService.swift - 包含 NetworkService 类

// ✅ 正确：扩展文件
// UIView+Extensions.swift
// String+Validation.swift

// ✅ 正确：协议文件
// Protocols.swift 或 DataSource.swift
```

---

## 注释规范

### Swift 文档注释

```swift
// ✅ 正确：使用 /// 文档注释
/// 计算用户折扣价格
/// - Parameters:
///   - price: 原价
///   - level: 会员等级
/// - Returns: 折扣后的价格
/// - Throws: DiscountError 当等级无效时
func calculateDiscount(price: Double, level: Int) throws -> Double {
    // ...
}

// ✅ 正确：使用 // 普通注释
// 计算总价（含税）
let total = price * 1.1

// ✅ 正确：标记代码区块
// MARK: - Lifecycle
// MARK: - Actions
// MARK: - Private Methods

// ❌ 错误：无意义的注释
let count = 0  // 设置 count 为 0
```

### Objective-C 文档注释

```objective-c
// ✅ 正确：使用 /** */ 文档注释
/**
 * 计算用户折扣价格
 *
 * @param price 原价
 * @param level 会员等级
 * @return 折扣后的价格
 * @throws DiscountError 当等级无效时
 */
- (double)calculateDiscount:(double)price level:(int)level;

// ✅ 正确：属性注释
/// 用户唯一标识符
@property (nonatomic, copy) NSString *userID;

// ✅ 正确：使用#pragma mark 分区
#pragma mark - Lifecycle
#pragma mark - UITableViewDataSource

// ❌ 错误：注释与代码不一致
// 设置背景为红色
view.backgroundColor = [UIColor blueColor];
```

### TODO 注释

```swift
// ✅ 正确：TODO 格式
// TODO: 优化图片加载性能
// FIXME: 处理网络错误情况
// NOTE: 这里需要特殊处理 iOS 14 以下版本

// ❌ 错误
// todo 优化
// 需要修改
```

---

## 代码组织

### Swift 文件结构

```swift
// ✅ 正确：标准文件结构
import UIKit

// MARK: - Typealias
typealias CompletionHandler = (Result<Data, Error>) -> Void

// MARK: - Protocol
protocol DataSourceDelegate: AnyObject {
    func didUpdateData(_ sender: Any)
}

// MARK: - Class
final class ViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var titleLabel: UILabel!

    // MARK: - Properties
    private var viewModel: ViewModel?
    private let service: Service

    // MARK: - Initialization
    init(service: Service) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    // MARK: - Actions
    @IBAction private func submitTapped(_ sender: UIButton) {
        viewModel?.submit()
    }

    // MARK: - Setup
    private func setupUI() {
        // ...
    }

    // MARK: - Private Methods
    private func loadData() {
        // ...
    }
}

// MARK: - Extension
extension ViewController: UITableViewDataSource {
    // ...
}
```

### Objective-C 文件结构

```objective-c
// ✅ 正确：头文件结构
#import <UIKit/UIKit.h>

@protocol DataSourceDelegate <NSObject>
- (void)didUpdateData:(id)sender;
@end

@interface ViewController : UIViewController

@property (nonatomic, weak) id<DataSourceDelegate> delegate;

- (instancetype)initWithService:(Service *)service;

@end

// ✅ 正确：实现文件结构
#import "ViewController.h"

@interface ViewController () <UITableViewDataSource>

@property (nonatomic, strong) ViewModel *viewModel;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation ViewController {
    NSInteger _count;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _count;
}

#pragma mark - Private Methods

- (void)setupUI {
    // ...
}

@end
```

---

## 检查清单

在提交代码前，请确认：

### 格式
- [ ] 使用 4 空格缩进（无 Tab）
- [ ] 行宽不超过 120 字符
- [ ] 逻辑块之间有空行分隔
- [ ] 大括号位置正确

### 命名
- [ ] 类型使用 PascalCase
- [ ] 变量/函数使用 camelCase
- [ ] 布尔值使用 is/has/should 前缀
- [ ] 文件名与主类型一致

### 注释
- [ ] 公共 API 有文档注释
- [ ] 使用 // MARK 组织代码
- [ ] TODO/FIXME 格式正确
- [ ] 注释与实际代码一致

### 组织
- [ ] 文件结构符合规范
- [ ] 代码按功能分区
- [ ] 扩展使用 MARK 注释

---

## 参考资源

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Google Swift Style Guide](https://google.github.io/swift/)
- [Ray Wenderlich Swift Style Guide](https://github.com/raywenderlich/swift-style-guide)
