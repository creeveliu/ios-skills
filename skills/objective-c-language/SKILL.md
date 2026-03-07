---
name: objective-c-language
description: Objective-C language best practices. Use this skill whenever the user mentions Objective-C, ObjC, OC, working with legacy iOS code, ARC, Blocks, Categories, Protocols, Runtime, or Swift interoperability.
---

# Objective-C 最佳实践

本技能提供 Objective-C 编码的标准工作流程和最佳实践。

## 核心原则

1. **现代 Objective-C** - 使用现代语法糖和特性
2. **ARC 内存管理** - 正确使用自动引用计数
3. **轻量级泛型** - 提高类型安全性
4. **Block 安全** - 避免循环引用
5. **Swift 互操作** - 为 Swift 调用设计 API

---

## 内存管理

### ARC 基础规则

```objective-c
// ✅ 正确：使用强引用默认
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *items;

// ✅ 正确：避免循环引用时使用 weak
@property (nonatomic, weak) id<Delegate> delegate;
@property (nonatomic, weak) IBOutlet UIView *contentView;

// ✅ 正确：Block 属性使用 copy
@property (nonatomic, copy) void (^completionBlock)(BOOL success);

// ❌ 错误：Block 属性使用 strong（会导致循环引用）
@property (nonatomic, strong) void (^completionBlock)(BOOL success);
```

### Block 中的内存管理

```objective-c
// ✅ 正确：使用 weak-strong dance
__weak typeof(self) weakSelf = self;
self.completionBlock = ^(BOOL success) {
    typeof(self) strongSelf = weakSelf;
    if (strongSelf) {
        [strongSelf handleResult:success];
    }
};

// ✅ 正确：简单场景可仅用 weak
[networkManager fetchDataWithCompletion:^(id result) {
    [weakSelf updateUIWithResult:result];
}];

// ❌ 错误：直接使用 self 可能导致循环引用
[networkManager fetchDataWithCompletion:^(id result) {
    [self updateUIWithResult:result];  // self 被 block 强引用
}];
```

### 集合类内存管理

```objective-c
// ✅ 正确：使用可变集合的 copy
- (void)setItems:(NSArray *)items {
    _items = [items copy];  // 防止外部修改
}

- (void)addObserver:(id)observer {
    if (!_observers) {
        _observers = [NSMutableArray array];
    }
    [_observers addObject:observer];
}

// ✅ 正确：KVO 移除要配对
- (void)dealloc {
    for (id observer in _observers) {
        [observer removeObserver:self forKeyPath:@"status"];
    }
}
```

---

## 语言特性

### Category（类别）

```objective-c
// ✅ 正确：Category 命名使用公司/模块前缀
// NSString+JSON.h
@interface NSString (JSON)
- (NSDictionary *)json_decodedDictionary;
@end

// ✅ 正确：使用 Class Extension 添加私有属性
// MyClass.m
@interface MyClass ()
@property (nonatomic, strong) UIView *privateView;
@property (nonatomic, assign) BOOL isLoading;
- (void)privateMethod;
@end

@implementation MyClass
- (void)privateMethod {
    // 私有实现
}
@end

// ❌ 错误：在 Category 中添加属性（无法合成实例变量）
@interface NSString (Bad)
@property (nonatomic, strong) id data;  // 危险！
@end
```

### Protocol（协议）

```objective-c
// ✅ 正确：协议使用 weak 引用避免循环引用
@protocol DataSourceDelegate <NSObject>
- (void)didUpdateData:(id)sender;
@optional
- (void)willBeginLoading:(id)sender;
@end

@interface DataSource : NSObject
@property (nonatomic, weak) id<DataSourceDelegate> delegate;
@end

// ✅ 正确：检查 delegate 响应方法
- (void)finishLoading {
    if ([self.delegate respondsToSelector:@selector(didUpdateData:)]) {
        [self.delegate didUpdateData:self];
    }
}

// ✅ 正确：使用协议组合
@protocol TableViewDataSource <NSObject>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end
```

### Notification（通知）

```objective-c
// ✅ 正确：使用 block 方式接收通知（iOS 10+）
[self.notificationCenter addObserverForName:UIKeyboardWillShowNotification
                                     object:nil
                                      queue:[NSOperationQueue mainQueue]
                                 usingBlock:^(NSNotification *note) {
    [self handleKeyboardShow:note];
}];

// ✅ 正确：传统方式需要在 dealloc 移除
- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:UISystemTimeZoneDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// ❌ 错误：忘记移除观察者（可能导致崩溃）
- (void)dealloc {
    // 缺少 removeObserver
}
```

---

## Swift 混编

### 为 Swift 设计 API

```objective-c
// ✅ 正确：使用 NS_SWIFT_NAME 提供友好的 Swift 名称
@interface APIManager : NSObject
- (void)fetchUserData:(void (^)(NSDictionary * _Nullable data, NSError * _Nullable error))completion
NS_SWIFT_NAME(fetchUser(completion:));
@end

// Swift 调用：apiManager.fetchUser { data, error in ... }

// ✅ 正确：使用 NS_REFINED_FOR_SWIFT 隐藏原始 API
@interface Config : NSObject
@property (nonatomic, copy) NSString *apiKey NS_REFINED_FOR_SWIFT;
@end

// Swift 中通过 _objc_ 前缀访问原始 API

// ✅ 正确：使用 NS_ERROR_ENUM 提供 Swift Error
typedef NS_ERROR_ENUM(APIErrorDomain, APIError) {
    APIErrorUnknown = 0,
    APIErrorNetworkUnavailable = 1,
    APIErrorUnauthorized = 2,
} NS_SWIFT_NAME(APIManager.Error);
```

### 泛型支持

```objective-c
// ✅ 正确：使用轻量级泛型
@interface Repository<ObjectType> : NSObject
- (void)addItem:(ObjectType)item;
- (ObjectType)itemAtIndex:(NSInteger)index;
- (NSArray<ObjectType> *)allItems;
@end

// Swift 中：Repository<String>

// ✅ 正确：使用类型约束
@interface Collection<ElementType: id<NSCopying>> : NSObject
- (void)addCopy:(ElementType)item;
@end
```

### 可选类型映射

```objective-c
// ✅ 正确：使用 nullable/unspecified/null_resettable
@interface User : NSObject
@property (nonatomic, copy, nullable) NSString *nickname;  // Swift: String?
@property (nonatomic, copy, nonnull) NSString *userId;     // Swift: String
@property (nonatomic, strong, null_resettable) NSArray *tags;  // Swift: [String]（非空）
@end
```

---

## 代码规范

### 命名规范

```objective-c
// ✅ 正确：方法命名遵循动词 + 名词模式
- (void)saveDataToDisk;
- (UIImage *)imageWithSize:(CGSize)size;
- (void)setBackgroundColor:(UIColor *)color;

// ✅ 正确：第一个参数描述方法意图
- (void)insertObject:(id)object atIndex:(NSUInteger)index;  // 不是 insert:atIndex:

// ✅ 正确：布尔属性使用 is/has/should/can 前缀
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
```

### 初始化方法

```objective-c
// ✅ 正确：遵循初始化模式
- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name copy];
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    // 公共初始化逻辑
}
```

### 单例模式

```objective-c
// ✅ 正确：线程安全的单例
+ (instancetype)sharedManager {
    static MyClass *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
```

---

## 常见陷阱

### 循环引用

```objective-c
// ❌ 错误：self -> block -> self 循环
self.handler = ^{
    [self doSomething];
};

// ✅ 正确：使用 weak 引用
__weak typeof(self) weakSelf = self;
self.handler = ^{
    [weakSelf doSomething];
};
```

### KVO 陷阱

```objective-c
// ✅ 正确：KVO 配对注册和移除
- (void)startObserving {
    [self.object addObserver:self
                  forKeyPath:@"value"
                     options:NSKeyValueObservingOptionNew
                     context:&MyContextKey];
}

- (void)stopObserving {
    [self.object removeObserver:self
                     forKeyPath:@"value"
                        context:&MyContextKey];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == &MyContextKey) {
        // 处理 KVO
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
```

### 字符串比较

```objective-c
// ❌ 错误：使用 == 比较字符串内容
if (string == @"expected") { }

// ✅ 正确：使用 isEqualToString:
if ([string isEqualToString:@"expected"]) { }

// ✅ 正确：nil 安全检查
if (string != nil && [string isEqualToString:@"expected"]) { }
```

---

## 检查清单

在提交 Objective-C 代码前，请确认：

- [ ] 使用 ARC，没有手动 retain/release
- [ ] Block 使用 weak-strong dance 避免循环引用
- [ ] delegate 使用 weak 引用
- [ ] Category 命名有前缀，不会冲突
- [ ] Protocol 方法实现前检查 respondsToSelector
- [ ] Notification 在 dealloc 中移除
- [ ] KVO 配对添加和移除
- [ ] 单例使用 dispatch_once
- [ ] 为 Swift 调用设计了友好的 API（如需要）

---

## 参考资源

- [Programming with Objective-C](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/)
- [Transitioning to ARC](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ARC/Transitioning.html)
- [Swift 和 Objective-C 互操作](https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis)
