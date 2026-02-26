# Xcode HealthKit Capability 配置完成

## ✅ 已完成的配置

### 1. Entitlements 文件
- ✅ 创建 `ios/Runner/Runner.entitlements`
- ✅ 添加 HealthKit capability 配置
- ✅ 配置 HealthKit 访问权限

### 2. Xcode 项目配置
- ✅ 添加 `CODE_SIGN_ENTITLEMENTS` 到 Debug 配置
- ✅ 添加 `CODE_SIGN_ENTITLEMENTS` 到 Release 配置
- ✅ 添加 `CODE_SIGN_ENTITLEMENTS` 到 Profile 配置
- ✅ 在 project.pbxproj 中注册 Runner.entitlements 文件

### 3. 文件结构
```
ios/
└── Runner/
    ├── Info.plist                 # HealthKit 权限描述
    ├── Runner.entitlements        # HealthKit capability 配置
    └── Runner.xcodeproj/
        └── project.pbxproj        # 项目配置（已更新）
```

## 📋 配置详情

### Runner.entitlements 内容
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.healthkit</key>
	<true/>
	<key>com.apple.developer.healthkit.access</key>
	<array/>
</dict>
</plist>
```

### Info.plist 权限描述
- `NSHealthShareUsageDescription`: "BlueWatch 需要访问你的健康数据来显示心率、步数、睡眠等信息"
- `NSHealthUpdateUsageDescription`: "BlueWatch 需要保存你的健康数据"

## 🚀 下一步

### 立即可做
1. **重新打开 Xcode**
   - 关闭当前的 Xcode 窗口
   - 重新打开 `ios/Runner.xcworkspace`
   - Xcode 会重新加载项目配置

2. **验证配置**
   - 选择 Runner target
   - 进入 Signing & Capabilities
   - 应该看到 HealthKit 已启用

3. **在真实 iOS 设备上测试**
   - 连接 iPhone 或 iPad
   - 运行 `flutter run`
   - 应用启动时会请求 HealthKit 权限
   - 授予权限后应该能读取健康数据

## 🔧 故障排除

### 如果 HealthKit 权限仍未生效

**方案 1：在 Xcode 中手动添加**
1. 打开 `ios/Runner.xcworkspace`
2. 选择 Runner target
3. 进入 Signing & Capabilities
4. 点击 "+ Capability"
5. 搜索 "HealthKit" 并添加

**方案 2：检查 Bundle ID**
- 确保 Bundle ID 与 entitlements 文件中的配置一致
- 当前 Bundle ID: `com.bluewatch.bluewatch`

**方案 3：清理构建**
```bash
flutter clean
flutter pub get
flutter run
```

## 📝 验证清单

- [ ] Xcode 已重新打开
- [ ] Runner.entitlements 文件存在
- [ ] Info.plist 包含权限描述
- [ ] project.pbxproj 包含 CODE_SIGN_ENTITLEMENTS 配置
- [ ] Signing & Capabilities 中显示 HealthKit
- [ ] 在真实设备上成功运行应用
- [ ] 应用请求 HealthKit 权限
- [ ] 用户授予权限后能读取数据

## 💡 注意事项

1. **模拟器限制**
   - iOS 模拟器无法读取真实 HealthKit 数据
   - 必须在真实设备上测试

2. **开发者账户**
   - 如果使用自动签名，需要有效的 Apple 开发者账户
   - 或者使用 Xcode 的自动签名功能

3. **权限请求**
   - 首次运行时会弹出权限请求
   - 用户可以在设置中修改权限

4. **数据可用性**
   - 需要用户在 Health 应用中有数据
   - 或者从其他应用（如 Apple Watch）同步数据

---

**准备好测试了吗？** 重新打开 Xcode 并连接 iOS 设备！
