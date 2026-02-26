# Apple HealthKit 和 Google Fit 集成方案

## 📋 项目目标

在 BlueWatch Flutter 应用中集成 Apple HealthKit 和 Google Fit，支持读取用户的健康数据（心率、步数、睡眠等）。

## 🏗️ 整体架构

```
┌─────────────────────────────────────────────────────┐
│           BlueWatch Flutter App                      │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │      Health Data Integration Layer           │  │
│  │                                              │  │
│  │  ┌─────────────┐  ┌──────────────────────┐  │  │
│  │  │ HealthKit   │  │ Google Fit           │  │  │
│  │  │ (iOS)       │  │ (Android)            │  │  │
│  │  └──────┬──────┘  └──────────┬───────────┘  │  │
│  │         │                    │              │  │
│  │  ┌──────▼────────────────────▼──────────┐  │  │
│  │  │  Unified Health Data Model           │  │  │
│  │  │  - Heart Rate                        │  │  │
│  │  │  - Steps                             │  │  │
│  │  │  - Sleep                             │  │  │
│  │  │  - Workouts                          │  │  │
│  │  └──────┬─────────────────────────────┘  │  │
│  │         │                                │  │
│  │  ┌──────▼─────────────────────────────┐  │  │
│  │  │  Local Storage (SQLite/Hive)       │  │  │
│  │  └──────────────────────────────────┘  │  │
│  └──────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │      UI Layer                                │  │
│  │  - Health Dashboard                          │  │
│  │  - Data Statistics                           │  │
│  │  - Permission Management                     │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

## 📦 所需的 Flutter 包

### iOS (HealthKit)

```yaml
dependencies:
  health: ^9.0.0              # 主要的 HealthKit 集成包
  permission_handler: ^11.0.0 # 权限管理
  intl: ^0.19.0              # 日期时间格式化
```

### Android (Google Fit)

```yaml
dependencies:
  google_fit: ^2.0.0          # Google Fit 集成包
  permission_handler: ^11.0.0 # 权限管理
  intl: ^0.19.0              # 日期时间格式化
```

### 通用

```yaml
dependencies:
  provider: ^6.0.0            # 状态管理
  hive: ^2.0.0               # 本地存储
  hive_flutter: ^1.0.0       # Flutter 适配
```

## 🔑 核心数据模型

### 统一的健康数据模型

```dart
// lib/models/health_data.dart

class HealthDataPoint {
  final String id;
  final HealthDataType type;
  final double value;
  final String unit;
  final DateTime dateTime;
  final String source; // 'healthkit' 或 'google_fit'
  final Map<String, dynamic> metadata;

  HealthDataPoint({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.dateTime,
    required this.source,
    this.metadata = const {},
  });
}

enum HealthDataType {
  heartRate,      // bpm
  steps,          // count
  distance,       // meters
  calories,       // kcal
  sleepDuration,  // minutes
  sleepDeep,      // minutes
  sleepLight,     // minutes
  bloodPressure,  // mmHg
  bloodOxygen,    // %
  temperature,    // °C
  workoutDuration, // minutes
  workoutCalories, // kcal
}

class DailyHealthSummary {
  final DateTime date;
  final int steps;
  final double distance; // meters
  final double calories;
  final int heartRateAvg;
  final int heartRateMax;
  final int heartRateMin;
  final int sleepDuration; // minutes
  final int sleepDeep; // minutes
  final int sleepLight; // minutes
  final List<Workout> workouts;

  DailyHealthSummary({
    required this.date,
    required this.steps,
    required this.distance,
    required this.calories,
    required this.heartRateAvg,
    required this.heartRateMax,
    required this.heartRateMin,
    required this.sleepDuration,
    required this.sleepDeep,
    required this.sleepLight,
    required this.workouts,
  });
}

class Workout {
  final String id;
  final String type; // 'running', 'cycling', 'swimming', etc.
  final DateTime startTime;
  final DateTime endTime;
  final double distance; // meters
  final int calories;
  final int heartRateAvg;
  final int heartRateMax;

  Workout({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.distance,
    required this.calories,
    required this.heartRateAvg,
    required this.heartRateMax,
  });
}
```

## 🔧 实现步骤

### 第一步：iOS HealthKit 集成

#### 1.1 配置 iOS 项目

**编辑 ios/Podfile：**

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_HEALTH=1',
      ]
    end
  end
end
```

**编辑 ios/Runner/Info.plist：**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- 其他配置... -->

  <!-- HealthKit 权限 -->
  <key>NSHealthShareUsageDescription</key>
  <string>BlueWatch 需要访问你的健康数据来显示心率、步数、睡眠等信息</string>

  <key>NSHealthUpdateUsageDescription</key>
  <string>BlueWatch 需要保存你的健康数据</string>

  <!-- 后台模式 -->
  <key>UIBackgroundModes</key>
  <array>
    <string>processing</string>
    <string>fetch</string>
  </array>
</dict>
</plist>
```

#### 1.2 创建 HealthKit 服务

**lib/services/healthkit_service.dart：**

```dart
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/health_data.dart';

class HealthKitService {
  static final HealthKitService _instance = HealthKitService._internal();

  factory HealthKitService() {
    return _instance;
  }

  HealthKitService._internal();

  final Health _health = Health();

  // 支持的数据类型
  final List<HealthDataType> _supportedTypes = [
    HealthDataType.heartRate,
    HealthDataType.steps,
    HealthDataType.distance,
    HealthDataType.calories,
    HealthDataType.sleepDuration,
  ];

  /// 请求权限
  Future<bool> requestPermissions() async {
    try {
      // 请求 HealthKit 权限
      final permissions = _supportedTypes.map((type) {
        return _mapToHealthDataType(type);
      }).toList();

      final result = await _health.requestAuthorization(permissions);
      return result;
    } catch (e) {
      print('请求权限失败: $e');
      return false;
    }
  }

  /// 获取今天的健康数据
  Future<DailyHealthSummary?> getTodayHealthData() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      return await getHealthDataForDateRange(startOfDay, now);
    } catch (e) {
      print('获取今天数据失败: $e');
      return null;
    }
  }

  /// 获取日期范围内的健康数据
  Future<DailyHealthSummary?> getHealthDataForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: _supportedTypes.map((type) {
          return _mapToHealthDataType(type);
        }).toList(),
        startTime: startDate,
        endTime: endDate,
      );

      return _parseHealthData(data, startDate);
    } catch (e) {
      print('获取数据范围失败: $e');
      return null;
    }
  }

  /// 获取心率数据
  Future<List<HealthDataPoint>> getHeartRateData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startDate,
        endTime: endDate,
      );

      return data
          .map((point) => HealthDataPoint(
            id: '${point.dateTime.millisecondsSinceEpoch}',
            type: HealthDataType.heartRate,
            value: point.value.toDouble(),
            unit: 'bpm',
            dateTime: point.dateTime,
            source: 'healthkit',
          ))
          .toList();
    } catch (e) {
      print('获取心率数据失败: $e');
      return [];
    }
  }

  /// 获取步数数据
  Future<List<HealthDataPoint>> getStepsData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startDate,
        endTime: endDate,
      );

      return data
          .map((point) => HealthDataPoint(
            id: '${point.dateTime.millisecondsSinceEpoch}',
            type: HealthDataType.steps,
            value: point.value.toDouble(),
            unit: 'count',
            dateTime: point.dateTime,
            source: 'healthkit',
          ))
          .toList();
    } catch (e) {
      print('获取步数数据失败: $e');
      return [];
    }
  }

  /// 获取睡眠数据
  Future<List<HealthDataPoint>> getSleepData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_IN_BED, HealthDataType.SLEEP_ASLEEP],
        startTime: startDate,
        endTime: endDate,
      );

      return data
          .map((point) => HealthDataPoint(
            id: '${point.dateTime.millisecondsSinceEpoch}',
            type: point.typeString == 'SLEEP_ASLEEP'
                ? HealthDataType.sleepDuration
                : HealthDataType.sleepLight,
            value: point.value.toDouble(),
            unit: 'minutes',
            dateTime: point.dateTime,
            source: 'healthkit',
          ))
          .toList();
    } catch (e) {
      print('获取睡眠数据失败: $e');
      return [];
    }
  }

  // 辅助方法
  HealthDataType _mapToHealthDataType(HealthDataType type) {
    switch (type) {
      case HealthDataType.heartRate:
        return HealthDataType.HEART_RATE;
      case HealthDataType.steps:
        return HealthDataType.STEPS;
      case HealthDataType.distance:
        return HealthDataType.DISTANCE;
      case HealthDataType.calories:
        return HealthDataType.ACTIVE_ENERGY_BURNED;
      case HealthDataType.sleepDuration:
        return HealthDataType.SLEEP_ASLEEP;
      default:
        return HealthDataType.STEPS;
    }
  }

  DailyHealthSummary _parseHealthData(
    List<HealthDataPoint> data,
    DateTime date,
  ) {
    // 解析数据并创建每日摘要
    // ... 实现细节
    return DailyHealthSummary(
      date: date,
      steps: 0,
      distance: 0,
      calories: 0,
      heartRateAvg: 0,
      heartRateMax: 0,
      heartRateMin: 0,
      sleepDuration: 0,
      sleepDeep: 0,
      sleepLight: 0,
      workouts: [],
    );
  }
}
```

### 第二步：Android Google Fit 集成

#### 2.1 配置 Android 项目

**编辑 android/app/build.gradle：**

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21 // Google Fit 需要 API 21+
        targetSdkVersion 34
    }
}

dependencies {
    implementation 'com.google.android.gms:play-services-fitness:21.1.0'
}
```

**编辑 android/app/src/main/AndroidManifest.xml：**

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Google Fit 权限 -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.BODY_SENSORS" />
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />

    <!-- 其他配置... -->

</manifest>
```

#### 2.2 创建 Google Fit 服务

**lib/services/google_fit_service.dart：**

```dart
import 'package:google_fit/google_fit.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/health_data.dart';

class GoogleFitService {
  static final GoogleFitService _instance = GoogleFitService._internal();

  factory GoogleFitService() {
    return _instance;
  }

  GoogleFitService._internal();

  /// 请求权限
  Future<bool> requestPermissions() async {
    try {
      final permissions = [
        Permission.activityRecognition,
        Permission.location,
      ];

      final results = await permissions.request();

      return results.values.every((status) => status.isGranted);
    } catch (e) {
      print('请求权限失败: $e');
      return false;
    }
  }

  /// 获取今天的健康数据
  Future<DailyHealthSummary?> getTodayHealthData() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      return await getHealthDataForDateRange(startOfDay, now);
    } catch (e) {
      print('获取今天数据失败: $e');
      return null;
    }
  }

  /// 获取日期范围内的健康数据
  Future<DailyHealthSummary?> getHealthDataForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // 获取步数
      final steps = await GoogleFit.getSteps(
        startTime: startDate,
        endTime: endDate,
      );

      // 获取卡路里
      final calories = await GoogleFit.getCalories(
        startTime: startDate,
        endTime: endDate,
      );

      // 获取心率
      final heartRate = await GoogleFit.getHeartRateSamples(
        startTime: startDate,
        endTime: endDate,
      );

      // 获取睡眠
      final sleep = await GoogleFit.getSleep(
        startTime: startDate,
        endTime: endDate,
      );

      return _parseHealthData(
        steps: steps,
        calories: calories,
        heartRate: heartRate,
        sleep: sleep,
        date: startDate,
      );
    } catch (e) {
      print('获取数据范围失败: $e');
      return null;
    }
  }

  /// 获取心率数据
  Future<List<HealthDataPoint>> getHeartRateData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await GoogleFit.getHeartRateSamples(
        startTime: startDate,
        endTime: endDate,
      );

      return data
          .map((point) => HealthDataPoint(
            id: '${point['time']}',
            type: HealthDataType.heartRate,
            value: (point['value'] as num).toDouble(),
            unit: 'bpm',
            dateTime: DateTime.fromMillisecondsSinceEpoch(point['time']),
            source: 'google_fit',
          ))
          .toList();
    } catch (e) {
      print('获取心率数据失败: $e');
      return [];
    }
  }

  /// 获取步数数据
  Future<List<HealthDataPoint>> getStepsData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await GoogleFit.getSteps(
        startTime: startDate,
        endTime: endDate,
      );

      return data
          .map((point) => HealthDataPoint(
            id: '${point['time']}',
            type: HealthDataType.steps,
            value: (point['value'] as num).toDouble(),
            unit: 'count',
            dateTime: DateTime.fromMillisecondsSinceEpoch(point['time']),
            source: 'google_fit',
          ))
          .toList();
    } catch (e) {
      print('获取步数数据失败: $e');
      return [];
    }
  }

  /// 获取睡眠数据
  Future<List<HealthDataPoint>> getSleepData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await GoogleFit.getSleep(
        startTime: startDate,
        endTime: endDate,
      );

      return data
          .map((point) => HealthDataPoint(
            id: '${point['time']}',
            type: HealthDataType.sleepDuration,
            value: (point['duration'] as num).toDouble(),
            unit: 'minutes',
            dateTime: DateTime.fromMillisecondsSinceEpoch(point['time']),
            source: 'google_fit',
          ))
          .toList();
    } catch (e) {
      print('获取睡眠数据失败: $e');
      return [];
    }
  }

  DailyHealthSummary _parseHealthData({
    required List<dynamic> steps,
    required List<dynamic> calories,
    required List<dynamic> heartRate,
    required List<dynamic> sleep,
    required DateTime date,
  }) {
    // 解析数据并创建每日摘要
    // ... 实现细节
    return DailyHealthSummary(
      date: date,
      steps: 0,
      distance: 0,
      calories: 0,
      heartRateAvg: 0,
      heartRateMax: 0,
      heartRateMin: 0,
      sleepDuration: 0,
      sleepDeep: 0,
      sleepLight: 0,
      workouts: [],
    );
  }
}
```

### 第三步：统一的健康数据提供者

**lib/providers/health_provider.dart：**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/health_data.dart';
import '../services/healthkit_service.dart';
import '../services/google_fit_service.dart';

class HealthProvider with ChangeNotifier {
  late final HealthKitService _healthKitService;
  late final GoogleFitService _googleFitService;

  DailyHealthSummary? _todayData;
  List<DailyHealthSummary> _weekData = [];
  bool _isLoading = false;
  String? _error;

  HealthProvider() {
    _healthKitService = HealthKitService();
    _googleFitService = GoogleFitService();
  }

  // Getters
  DailyHealthSummary? get todayData => _todayData;
  List<DailyHealthSummary> get weekData => _weekData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 初始化并请求权限
  Future<bool> initialize() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      bool hasPermission = false;

      if (Platform.isIOS) {
        hasPermission = await _healthKitService.requestPermissions();
      } else if (Platform.isAndroid) {
        hasPermission = await _googleFitService.requestPermissions();
      }

      if (hasPermission) {
        await loadTodayData();
      }

      return hasPermission;
    } catch (e) {
      _error = '初始化失败: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载今天的数据
  Future<void> loadTodayData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (Platform.isIOS) {
        _todayData = await _healthKitService.getTodayHealthData();
      } else if (Platform.isAndroid) {
        _todayData = await _googleFitService.getTodayHealthData();
      }

      notifyListeners();
    } catch (e) {
      _error = '加载数据失败: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载周数据
  Future<void> loadWeekData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      final weekAgo = now.subtract(Duration(days: 7));

      _weekData = [];

      for (int i = 0; i < 7; i++) {
        final date = weekAgo.add(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(Duration(days: 1));

        DailyHealthSummary? data;

        if (Platform.isIOS) {
          data = await _healthKitService.getHealthDataForDateRange(
            startOfDay,
            endOfDay,
          );
        } else if (Platform.isAndroid) {
          data = await _googleFitService.getHealthDataForDateRange(
            startOfDay,
            endOfDay,
          );
        }

        if (data != null) {
          _weekData.add(data);
        }
      }

      notifyListeners();
    } catch (e) {
      _error = '加载周数据失败: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取心率数据
  Future<List<HealthDataPoint>> getHeartRateData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (Platform.isIOS) {
        return await _healthKitService.getHeartRateData(startDate, endDate);
      } else if (Platform.isAndroid) {
        return await _googleFitService.getHeartRateData(startDate, endDate);
      }
      return [];
    } catch (e) {
      _error = '获取心率数据失败: $e';
      notifyListeners();
      return [];
    }
  }

  /// 获取步数数据
  Future<List<HealthDataPoint>> getStepsData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (Platform.isIOS) {
        return await _healthKitService.getStepsData(startDate, endDate);
      } else if (Platform.isAndroid) {
        return await _googleFitService.getStepsData(startDate, endDate);
      }
      return [];
    } catch (e) {
      _error = '获取步数数据失败: $e';
      notifyListeners();
      return [];
    }
  }

  /// 获取睡眠数据
  Future<List<HealthDataPoint>> getSleepData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (Platform.isIOS) {
        return await _healthKitService.getSleepData(startDate, endDate);
      } else if (Platform.isAndroid) {
        return await _googleFitService.getSleepData(startDate, endDate);
      }
      return [];
    } catch (e) {
      _error = '获取睡眠数据失败: $e';
      notifyListeners();
      return [];
    }
  }
}
```

## 📊 支持的数据类型对比

| 数据类型 | HealthKit | Google Fit | 单位 |
|---------|-----------|-----------|------|
| 心率 | ✅ | ✅ | bpm |
| 步数 | ✅ | ✅ | count |
| 距离 | ✅ | ✅ | meters |
| 卡路里 | ✅ | ✅ | kcal |
| 睡眠时长 | ✅ | ✅ | minutes |
| 深睡 | ✅ | ⚠️ | minutes |
| 浅睡 | ✅ | ⚠️ | minutes |
| 血压 | ✅ | ❌ | mmHg |
| 血氧 | ✅ | ❌ | % |
| 体温 | ✅ | ❌ | °C |
| 运动 | ✅ | ✅ | various |

## 🔐 权限管理

### iOS 权限

```swift
// ios/Runner/Info.plist
<key>NSHealthShareUsageDescription</key>
<string>BlueWatch 需要访问你的健康数据</string>

<key>NSHealthUpdateUsageDescription</key>
<string>BlueWatch 需要保存你的健康数据</string>
```

### Android 权限

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.BODY_SENSORS" />
```

## 📈 实现时间表

| 阶段 | 任务 | 时间 |
|------|------|------|
| 1 | 项目配置和依赖安装 | 1 天 |
| 2 | iOS HealthKit 集成 | 2-3 天 |
| 3 | Android Google Fit 集成 | 2-3 天 |
| 4 | 统一数据模型和 Provider | 1-2 天 |
| 5 | UI 界面开发 | 2-3 天 |
| 6 | 测试和优化 | 2-3 天 |
| **总计** | | **10-15 天** |

## ✅ 成功标准

- [ ] iOS 应用能读取 HealthKit 数据
- [ ] Android 应用能读取 Google Fit 数据
- [ ] 数据正确转换为统一格式
- [ ] 权限请求正常工作
- [ ] 数据显示在 UI 中
- [ ] 错误处理完善
- [ ] 性能测试通过

---

**下一步：** 选择从 iOS 还是 Android 开始实现。
