# 🚀 快速启动指南

## 📍 项目位置

```
/Users/williamsun/Downloads/documents/01_主题验证/BlueWatch/
```

## 🎯 立即开始

### 方式 1：模拟测试（推荐 - 无需设备）

```bash
cd /Users/williamsun/Downloads/documents/01_主题验证/BlueWatch
flutter run -d chrome
```

**预期结果：** Chrome 浏览器打开，显示模拟的健康数据

### 方式 2：iOS 测试（需要 iPhone/iPad）

```bash
cd /Users/williamsun/Downloads/documents/01_主题验证/BlueWatch
flutter run
```

**步骤：**
1. 用 USB 线连接 iPhone/iPad
2. 在设备上点击"信任"
3. 应用会自动安装并运行
4. 授予 HealthKit 权限
5. 查看真实的健康数据

### 方式 3：Android 测试（需要 Android 设备）

```bash
cd /Users/williamsun/Downloads/documents/01_主题验证/BlueWatch
flutter run -d 6788f822
```

**步骤：**
1. 连接 Android 设备
2. 应用会自动安装并运行
3. 授予权限
4. 查看真实的健康数据

## 📊 应用展示

### 模拟数据示例

```
┌─────────────────────────────────┐
│ 健康数据                         │
│ 测试模式 (Mock Data)             │
├─────────────────────────────────┤
│ ℹ️ 使用 测试模式 读取健康数据    │
├─────────────────────────────────┤
│ 步数                             │
│ 8234 步                          │
├─────────────────────────────────┤
│ 心率                             │
│ 平均: 72 bpm                     │
│ 最高: 95 bpm                     │
│ 最低: 58 bpm                     │
├─────────────────────────────────┤
│ 睡眠                             │
│ 总时长: 8.0 小时                 │
│ 深睡: 4.0 小时                   │
│ 浅睡: 4.0 小时                   │
└─────────────────────────────────┘
```

## 🔧 常见问题

### Q: 如何切换到真实数据？

**A:** 编辑 `lib/screens/health_dashboard_screen.dart`：

```dart
// 改这一行
import '../services/simple_health_service.dart';

// 改为
import '../services/health_service.dart';  // iOS
// 或
import '../services/google_fit_service.dart';  // Android
```

### Q: 如何修改模拟数据？

**A:** 编辑 `lib/services/simple_health_service.dart`：

```dart
static const int _mockSteps = 8234;  // 修改这里
static const int _mockHeartRateAvg = 72;  // 修改这里
// ... 其他数据
```

### Q: 如何在真实设备上测试？

**A:**
1. 连接设备
2. 运行 `flutter run`
3. 授予权限
4. 查看真实数据

## 📚 文档

| 文档 | 说明 |
|------|------|
| FINAL_SUMMARY.md | 最终项目总结 |
| QUICK_REFERENCE.md | 快速参考 |
| IMPLEMENTATION_SUMMARY.md | 完整实现总结 |
| HEALTHKIT_IMPLEMENTATION_STATUS.md | iOS 状态 |
| ANDROID_GOOGLE_FIT_IMPLEMENTATION.md | Android 状态 |

## 💡 提示

- 🌐 **模拟测试最快** - 立即看到结果
- 📱 **真实设备更准确** - 看到真实数据
- 🔄 **无缝切换** - 改一行代码即可切换
- 📖 **查看文档** - 了解更多细节

## 🎯 下一步

1. **运行模拟测试** - `flutter run -d chrome`
2. **查看结果** - 在浏览器中验证
3. **连接真实设备** - 测试真实数据
4. **优化应用** - 根据需要改进

---

**准备好了吗？** 现在就运行应用吧！

```bash
flutter run -d chrome
```
