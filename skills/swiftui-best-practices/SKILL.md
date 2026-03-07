---
name: swiftui-best-practices
description: How to build iOS interfaces using SwiftUI following best practices. Use this skill whenever the user mentions SwiftUI, building Swift UI, creating views with Swift, state management, @State/@Binding/@ObservedObject, ViewBuilder, or needs guidance on SwiftUI architecture, performance optimization, or UIKit interoperability.
---

# SwiftUI 最佳实践

本技能提供 SwiftUI 开发的标准工作流程和最佳实践。

## 核心原则

1. **单一数据源** - 状态管理清晰，数据流向明确
2. **值类型语义** - 充分利用 struct 的值类型特性
3. **声明式 UI** - 视图是状态的函数
4. **组合优于继承** - 通过组合构建可复用组件
5. **性能优先** - 避免不必要的视图重建

---

## 状态管理

### 属性包装器选择指南

```swift
// @State - 视图私有状态
struct CounterView: View {
    @State private var count = 0  // ✅ 视图内部管理

    var body: some View {
        Button("Count: \(count)") {
            count += 1
        }
    }
}

// @Binding - 与父视图共享状态
struct StepperView: View {
    @Binding var value: Int  // ✅ 引用父视图的状态

    var body: some View {
        Stepper("Value: \(value)", value: $value)
    }
}

// Parent view
struct ParentView: View {
    @State private var stepperValue = 0

    var body: some View {
        StepperView(value: $stepperValue)  // 传递绑定
    }
}

// @StateObject - 拥有并创建可观察对象
class ViewModel: ObservableObject {
    @Published var data: String = ""
}

struct FormView: View {
    @StateObject private var viewModel = ViewModel()  // ✅ 视图创建并拥有

    var body: some View {
        TextField("Enter text", text: $viewModel.data)
    }
}

// @ObservedObject - 引用外部可观察对象
struct DetailView: View {
    @ObservedObject var viewModel: ViewModel  // ✅ 外部传入

    var body: some View {
        Text(viewModel.data)
    }
}

// @EnvironmentObject - 跨层级共享
struct ContentView: View {
    @EnvironmentObject var userSettings: UserSettings

    var body: some View {
        Text(userSettings.username)
    }
}

// 注册环境对象
ContentView()
    .environmentObject(UserSettings())
```

### 状态提升模式

```swift
// ✅ 正确：状态提升到共同父视图
struct ParentView: View {
    @State private var searchText = ""

    var body: some View {
        VStack {
            SearchField(text: $searchText)
            ResultsList(searchText: searchText)
        }
    }
}

struct SearchField: View {
    @Binding var text: String

    var body: some View {
        TextField("Search...", text: $text)
    }
}

struct ResultsList: View {
    let searchText: String

    var body: some View {
        List {
            Text("Results for: \(searchText)")
        }
    }
}

// ❌ 错误：状态分散在多个子视图
```

### ObservableObject 最佳实践

```swift
// ✅ 正确：使用 @MainActor 确保线程安全
@MainActor
class ContentViewModel: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: DataService

    init(service: DataService = .shared) {
        self.service = service
    }

    func loadItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await service.fetchItems()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// ✅ 正确：拆分大型 ViewModel
class UserViewModel: ObservableObject {
    @Published var profile: UserProfile
    @Published var settings: UserSettings
}

// 更好：使用多个小对象
struct UserProfile { }
struct UserSettings { }
```

---

## 视图架构

### 视图组件化

```swift
// ✅ 正确：提取可复用组件
struct UserProfileView: View {
    let user: User

    var body: some View {
        VStack(spacing: 16) {
            AvatarView(imageURL: user.avatarURL)
            NameView(name: user.name)
            BioView(bio: user.bio)
        }
    }
}

struct AvatarView: View {
    let imageURL: URL?

    var body: some View {
        AsyncImage(url: imageURL) { image in
            image.resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Image(systemName: "person.circle")
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
    }
}

// ✅ 正确：使用 @ViewBuilder 创建复杂视图
struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
```

### 条件视图

```swift
// ✅ 正确：使用 Group 或直接条件渲染
var body: some View {
    VStack {
        if isLoading {
            ProgressView()
        } else if items.isEmpty {
            EmptyStateView()
        } else {
            ContentView(items: items)
        }
    }
}

// ✅ 正确：使用 switch
var body: some View {
    switch state {
    case .loading:
        ProgressView()
    case .empty:
        EmptyStateView()
    case .content(let items):
        ContentView(items: items)
    }
}

// ❌ 错误：在 body 中执行复杂逻辑
var body: some View {
    {
        if condition {
            return SomeView()
        }
        return OtherView()
    }()
}
```

### 列表优化

```swift
// ✅ 正确：使用 id 参数帮助 SwiftUI 追踪变化
List(items, id: \.id) { item in
    ItemRow(item: item)
}

// ✅ 正确：使用 ForEach 处理静态列表
ForEach(categories) { category in
    CategoryRow(category: category)
}

// ✅ 正确：删除动画
List {
    ForEach(items) { item in
        ItemRow(item: item)
            .swipeActions {
                Button("Delete", role: .destructive) {
                    withAnimation {
                        items.removeAll { $0.id == item.id }
                    }
                }
            }
}
```

---

## 互操作性

### UIKit 集成

```swift
// ✅ 正确：使用 UIViewRepresentable 封装 UIKit
struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.delegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 处理完成
        }
    }
}

// ✅ 正确：使用 UIViewControllerRepresentable
struct SheetView: UIViewControllerRepresentable {
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = ContentViewController()
        viewController.onDismiss = onDismiss
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ controller: UINavigationController, context: Context) {
        // 更新逻辑
    }
}
```

### 双向绑定

```swift
// ✅ 正确：UIKit 组件的双向绑定
struct TextFieldWrapper: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged(_:)),
            for: .editingChanged
        )
        textField.delegate = context.coordinator
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        if textField.text != text {
            textField.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: TextFieldWrapper

        init(_ parent: TextFieldWrapper) {
            self.parent = parent
        }

        @objc func textChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            return true
        }
    }
}
```

---

## 性能优化

### 避免不必要的视图重建

```swift
// ✅ 正确：使用 Equatable 避免不必要的更新
struct OptimizedView: View, Equatable {
    let title: String
    let count: Int

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.title == rhs.title && lhs.count == rhs.count
    }

    var body: some View {
        Text("\(title): \(count)")
    }
}

// ✅ 正确：提取子视图减少重绘范围
struct ListView: View {
    let items: [Item]

    var body: some View {
        List {
            ForEach(items) { item in
                ItemRow(item: item)  // 单独组件，只重绘变化的部分
            }
        }
    }
}

// ❌ 错误：大视图导致整体重绘
struct MassiveView: View {
    let items: [Item]

    var body: some View {
        List {
            ForEach(items) { item in
                // 所有视图逻辑都在这里，任何变化都会导致整体重绘
            }
        }
    }
}
```

### 图像优化

```swift
// ✅ 正确：使用 AsyncImage 的 placeholder
AsyncImage(url: url) { image in
    image.resizable()
        .aspectRatio(contentMode: .fill)
} placeholder: {
    Color.gray.opacity(0.3)
        .overlay(ProgressView())
}

// ✅ 正确：指定图像缓存策略
AsyncImage(url: url, transaction: .init(animation: .easeInOut)) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image.resizable()
    case .failure:
        Image(systemName: "photo")
    @unknown default:
        EmptyView()
    }
}
```

### 延迟加载

```swift
// ✅ 正确：使用 LazyVStack/LazyHStack
ScrollView {
    LazyVStack {
        ForEach(heavyItems) { item in
            HeavyItemView(item: item)
        }
    }
}

// ✅ 正确：使用 onAppear 延迟加载
List {
    ForEach(items) { item in
        ItemRow(item: item)
            .onAppear {
                if items.last == item {
                    viewModel.loadMore()
                }
            }
    }
}
```

---

## 检查清单

在提交 SwiftUI 代码前，请确认：

- [ ] 选择了正确的属性包装器（@State/@Binding/@StateObject/@ObservedObject）
- [ ] 状态提升到合适的层级
- [ ] ObservableObject 使用 @MainActor 标注
- [ ] 视图组件化，没有过大的 body
- [ ] 列表使用了 id 参数
- [ ] 图像有 placeholder
- [ ] 大量视图使用 LazyVStack/LazyHStack
- [ ] 没有在主线程执行耗时操作
- [ ] UIKit 封装正确处理了更新逻辑

---

## 参考资源

- [Apple SwiftUI Tutorial](https://developer.apple.com/tutorials/swiftui)
- [SwiftUI State Management](https://developer.apple.com/documentation/swiftui/managing-user-interface-state)
- [SwiftUI Performance](https://developer.apple.com/videos/play/wwdc2021/10258/)
