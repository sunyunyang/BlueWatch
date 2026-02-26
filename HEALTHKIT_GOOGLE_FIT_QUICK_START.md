# Apple HealthKit 和 Google Fit 集成 - 快速启动指南

## 🎯 目标

在 BlueWatch Flutter 应用中集成 Apple HealthKit（iOS）和 Google Fit（Android），支持读取用户的健康数据。

## 📊 支持的数据类型

### 心率数据
- 当前心率（bpm）
- 平均心率
- 最高心率
- 最低心率

### 步数数据
- 每日步数
- 每日距离
- 每日卡路里

### 睡眠数据
- 睡眠时长
- 深睡时长
- 浅睡时长

### 运动数据
- 运动类型（跑步、骑行、游泳等）
- 运动时长
- 运动距离
- 运动卡路里
- 运动心率

## 🚀 快速开始（3 步）

### 第一步：添加依赖

编辑 `pubspec.yaml`：

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Health Data Integration
  health: ^9.0.0              # HealthKit 和 Google Fit
  permission_handler: ^11.0.0 # 权限管理

  # State Management
  provider: ^6.0.0

  # Local Storage
  hive: ^2.0.0
  hive_flutter: ^1.0.0

  # Utilities
  intl: ^0.19.0              # 日期格式化
```

然后运行：

```bash
flutter pub get
```

### 第二步：配置平台特定设置

#### iOS 配置

编辑 `ios/Runner/Info.plist`，添加：

```xml
<key>NSHealthShareUsageDescription</key>
<string>BlueWatch 需要访问你的健康数据来显示心率、步数、睡眠等信息</string>

<key>NSHealthUpdateUsageDescription</key>
<string>BlueWatch 需要保存你的健康数据</string>
```

#### Android 配置

编辑 `android/app/build.gradle`，确保最低 API 版本：

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21  // Google Fit 需要 API 21+
        targetSdkVersion 34
    }
}
```

编辑 `android/app/src/main/AndroidManifest.xml`，添加权限：

```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### 第三步：实现健康数据服务

创建 `lib/services/health_service.dart`：

```dart
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();

  factory HealthService() {
    return _instance;
  }

  HealthService._internal();

  final Health _health = Health();

  // 请求权限
  Future<bool> requestPermissions() async {
    try {
      // iOS HealthKit 权限
      final types = [
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.DISTANCE,
        HealthDataType.CALORIES_BURNED,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
      ];

      final permissions = await _health.requestAuthorization(types);
      return permissions;
    } catch (error) {
      print('权限请求失败: $error');
      return false;
    }
  }

  // 获取今日步数
  Future<int> getTodaySteps() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final steps = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: now,
        types: [HealthDataType.STEPS],
      );

      if (steps.isEmpty) return 0;

      return (steps.first.value as num).toInt();
    } catch (error) {
      print('获取步数失败: $error');
      return 0;
    }
  }

  // 获取今日心率
  Future<Map<String, int>> getTodayHeartRate() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final heartRates = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );

      if (heartRates.isEmpty) {
        return {'avg': 0, 'max': 0, 'min': 0};
      }

      final values = heartRates
          .map((e) => (e.value as num).toInt())
          .toList();

      return {
        'avg': (values.reduce((a, b) => a + b) / values.length).toInt(),
        'max': values.reduce((a, b) => a > b ? a : b),
        'min': values.reduce((a, b) => a < b ? a : b),
      };
    } catch (error) {
      print('获取心率失败: $error');
      return {'avg': 0, 'max': 0, 'min': 0};
    }
  }

  // 获取睡眠数据
  Future<Map<String, int>> getTodaySleep() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));

      final sleepData = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [
          HealthDataType.SLEEP_IN_BED,
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_AWAKE,
        ],
      );

      if (sleepData.isEmpty) {
        return {'total': 0, 'deep': 0, 'light': 0};
      }

      // 计算睡眠时长（分钟）
      int totalSleep = 0;
      int deepSleep = 0;
      int lightSleep = 0;

      for (var data in sleepData) {
        if (data.type == HealthDataType.SLEEP_ASLEEP) {
          totalSleep += (data.value as num).toInt();
        } else if (data.type == HealthDataType.SLEEP_IN_BED) {
          deepSleep += (data.value as num).toInt();
        }
      }

      lightSleep = totalSleep - deepSleep;

      return {
        'total': totalSleep,
        'deep': deepSleep,
        'light': lightSleep,
      };
    } catch (error) {
      print('获取睡眠数据失败: $error');
      return {'total': 0, 'deep': 0, 'light': 0};
    }
  }

  // 获取运动数据
  Future<List<Map<String, dynamic>>> getWorkouts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final workouts = await _health.getHealthDataFromTypes(
        startTime: startDate,
        endTime: endDate,
        types: [HealthDataType.WORKOUT],
      );

      return workouts
          .map((w) => {
                'type': w.typeString,
                'duration': w.value,
                'startTime': w.dateFrom,
                'endTime': w.dateTo,
              })
          .toList();
    } catch (error) {
      print('获取运动数据失败: $error');
      return [];
    }
  }
}
```

## 📱 在 UI 中使用

创建 `lib/screens/health_dashboard_screen.dart`：

```dart
import 'package:flutter/material.dart';
import '../services/health_service.dart';

class HealthDashboardScreen extends StatefulWidget {
  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  final HealthService _healthService = HealthService();

  int _steps = 0;
  Map<String, int> _heartRate = {'avg': 0, 'max': 0, 'min': 0};
  Map<String, int> _sleep = {'total': 0, 'deep': 0, 'light': 0};

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    // 请求权限
    final hasPermission = await _healthService.requestPermissions();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('需要健康数据权限')),
      );
      return;
    }

    // 加载数据
    final steps = await _healthService.getTodaySteps();
    final heartRate = await _healthService.getTodayHeartRate();
    final sleep = await _healthService.getTodaySleep();

    setState(() {
      _steps = steps;
      _heartRate = heartRate;
      _sleep = sleep;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('健康数据')),
      body: RefreshIndicator(
        onRefresh: _loadHealthData,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // 步数卡片
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('步数', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 8),
                    Text(
                      '$_steps 步',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // 心率卡片
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('心率', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('平均'),
                            Text('${_heartRate['avg']} bpm'),
                          ],
                        ),
                        Column(
                          children: [
                            Text('最高'),
                            Text('${_heartRate['max']} bpm'),
                          ],
                        ),
                        Column(
                          children: [
                            Text('最低'),
                            Text('${_heartRate['min']} bpm'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // 睡眠卡片
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('睡眠', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('总时长'),
                            Text('${(_sleep['total']! / 60).toStringAsFixed(1)} 小时'),
                          ],
                        ),
                        Column(
                          children: [
                            Text('深睡'),
                            Text('${(_sleep['deep']! / 60).toStringAsFixed(1)} 小时'),
                          ],
                        ),
                        Column(
                          children: [
                            Text('浅睡'),
                            Text('${(_sleep['light']! / 60).toStringAsFixed(1)} 小时'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🔐 权限处理

### iOS 权限流程

```
用户打开应用
    ↓
请求 HealthKit 权限
    ↓
系统弹出权限对话框
    ↓
用户选择允许/拒绝
    ↓
应用获得权限（或被拒绝）
    ↓
读取健康数据
```

### Android 权限流程

```
用户打开应用
    ↓
检查运行时权限
    ↓
如果未授予，请求权限
    ↓
系统弹出权限对话框
    ↓
用户选择允许/拒绝
    ↓
应用获得权限（或被拒绝）
    ↓
读取 Google Fit 数据
```

## 📈 数据同步策略

### 后台同步

```dart
// 每天定时同步数据
void setupBackgroundSync() {
  // 使用 workmanager 包
  Workmanager().registerPeriodicTask(
    'sync_health_data',
    'syncHealthData',
    frequency: Duration(hours: 1),
  );
}

// 同步任务
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final healthService = HealthService();

    // 同步今日数据
    final steps = await healthService.getTodaySteps();
    final heartRate = await healthService.getTodayHeartRate();
    final sleep = await healthService.getTodaySleep();

    // 保存到本地数据库
    // ...

    return true;
  });
}
```

## 🐛 常见问题

### Q: 权限被拒绝怎么办？
A: 引导用户到设置中手动授予权限

### Q: 数据为空怎么办？
A: 检查用户是否在 HealthKit/Google Fit 中有数据

### Q: 如何处理不同平台的数据差异？
A: 使用统一的数据模型，在服务层进行转换

### Q: 如何保护用户隐私？
A: 只请求必要的权限，不上传敏感数据到服务器

## 📚 参考资源

- [health 包文档](https://pub.dev/packages/health)
- [Apple HealthKit 文档](https://developer.apple.com/healthkit/)
- [Google Fit 文档](https://developers.google.com/fit)
- [Flutter 权限处理](https://pub.dev/packages/permission_handler)

## 🎯 下一步

1. 添加依赖到 pubspec.yaml
2. 配置 iOS 和 Android 平台设置
3. 实现 HealthService
4. 创建 UI 展示健康数据
5. 测试权限和数据读取
6. 添加本地存储和数据同步

---

**准备好开始了吗？** 按照上面的步骤逐一实现即可！
