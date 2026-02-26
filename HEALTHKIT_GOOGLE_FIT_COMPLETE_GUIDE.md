# Apple HealthKit 和 Google Fit 集成 - 完整实现指南

## 📋 目录

1. [项目设置](#项目设置)
2. [iOS HealthKit 配置](#ios-healthkit-配置)
3. [Android Google Fit 配置](#android-google-fit-配置)
4. [核心实现](#核心实现)
5. [常见问题](#常见问题)
6. [测试指南](#测试指南)

## 项目设置

### 1. 创建新的 Flutter 项目或使用现有项目

```bash
# 如果需要创建新项目
flutter create bluewatch_health

cd bluewatch_health
```

### 2. 更新 pubspec.yaml

```yaml
name: bluewatch
description: A new Flutter project.

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Health Data
  health: ^9.0.0
  permission_handler: ^11.0.0

  # State Management
  provider: ^6.0.0

  # Local Storage
  hive: ^2.0.0
  hive_flutter: ^1.0.0

  # UI
  cupertino_icons: ^1.0.2
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^2.0.0
  hive_generator: ^2.0.0
  build_runner: ^2.0.0

flutter:
  uses-material-design: true
```

### 3. 运行 pub get

```bash
flutter pub get
```

## iOS HealthKit 配置

### 1. 编辑 ios/Podfile

```ruby
# 在 post_install 块中添加
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

### 2. 编辑 ios/Runner/Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>$(DEVELOPMENT_LANGUAGE)</string>
  <key>CFBundleExecutable</key>
  <string>$(EXECUTABLE_NAME)</string>
  <key>CFBundleIdentifier</key>
  <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>BlueWatch</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$(FLUTTER_BUILD_NAME)</string>
  <key>CFBundleSignature</key>
  <string>????</string>
  <key>CFBundleVersion</key>
  <string>$(FLUTTER_BUILD_NUMBER)</string>
  <key>LSRequiresIPhoneOS</key>
  <true/>

  <!-- HealthKit 权限 -->
  <key>NSHealthShareUsageDescription</key>
  <string>BlueWatch 需要访问你的健康数据来显示心率、步数、睡眠等信息。你的数据只会在本地存储，不会上传到任何服务器。</string>

  <key>NSHealthUpdateUsageDescription</key>
  <string>BlueWatch 需要保存你的健康数据。</string>

  <!-- 后台模式 -->
  <key>UIBackgroundModes</key>
  <array>
    <string>processing</string>
    <string>fetch</string>
  </array>

  <key>UILaunchStoryboardName</key>
  <string>LaunchScreen</string>
  <key>UIMainStoryboardFile</key>
  <string>Main</string>
  <key>UISupportedInterfaceOrientations</key>
  <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
  </array>
  <key>UISupportedInterfaceOrientationsIPad</key>
  <array>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
  </array>
  <key>UIViewControllerBasedStatusBarAppearance</key>
  <false/>
  <key>CADisableMinimumFrameDurationOnPhone</key>
  <true/>
  <key>UIApplicationSupportsIndirectInputEvents</key>
  <true/>
</dict>
</plist>
```

### 3. 在 Xcode 中启用 HealthKit

1. 打开 `ios/Runner.xcworkspace`
2. 选择 Runner 项目
3. 选择 Runner target
4. 进入 Signing & Capabilities
5. 点击 "+ Capability"
6. 搜索并添加 "HealthKit"

## Android Google Fit 配置

### 1. 编辑 android/app/build.gradle

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.example.bluewatch"
        minSdkVersion 21  // Google Fit 需要 API 21+
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 2. 编辑 android/app/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.bluewatch">

    <!-- Google Fit 权限 -->
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:label="BlueWatch"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### 3. 配置 Google Fit API

1. 访问 [Google Cloud Console](https://console.cloud.google.com/)
2. 创建新项目或选择现有项目
3. 启用 "Fitness REST API"
4. 创建 OAuth 2.0 凭证（Android 应用）
5. 下载凭证 JSON 文件

## 核心实现

### 1. 创建健康数据模型

创建 `lib/models/health_data.dart`：

```dart
class HealthDataPoint {
  final String id;
  final String type; // 'heart_rate', 'steps', 'sleep', etc.
  final double value;
  final String unit;
  final DateTime dateTime;
  final String source; // 'healthkit' 或 'google_fit'

  HealthDataPoint({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.dateTime,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'value': value,
    'unit': unit,
    'dateTime': dateTime.toIso8601String(),
    'source': source,
  };

  factory HealthDataPoint.fromJson(Map<String, dynamic> json) =>
      HealthDataPoint(
        id: json['id'],
        type: json['type'],
        value: json['value'],
        unit: json['unit'],
        dateTime: DateTime.parse(json['dateTime']),
        source: json['source'],
      );
}

class DailyHealthSummary {
  final DateTime date;
  final int steps;
  final double distance;
  final double calories;
  final int heartRateAvg;
  final int heartRateMax;
  final int heartRateMin;
  final int sleepDuration;
  final int sleepDeep;
  final int sleepLight;

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
  });
}
```

### 2. 创建健康数据服务

创建 `lib/services/health_service.dart`：

```dart
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/health_data.dart';

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
      final types = [
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.DISTANCE,
        HealthDataType.CALORIES_BURNED,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.WORKOUT,
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

      int totalSteps = 0;
      for (var step in steps) {
        totalSteps += (step.value as num).toInt();
      }

      return totalSteps;
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

      final avg = (values.reduce((a, b) => a + b) / values.length).toInt();
      final max = values.reduce((a, b) => a > b ? a : b);
      final min = values.reduce((a, b) => a < b ? a : b);

      return {'avg': avg, 'max': max, 'min': min};
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

      int totalSleep = 0;
      int deepSleep = 0;

      for (var data in sleepData) {
        final minutes = (data.value as num).toInt();
        if (data.type == HealthDataType.SLEEP_ASLEEP) {
          totalSleep += minutes;
        } else if (data.type == HealthDataType.SLEEP_IN_BED) {
          deepSleep += minutes;
        }
      }

      final lightSleep = totalSleep - deepSleep;

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

  // 获取日期范围内的数据
  Future<DailyHealthSummary> getDailySummary(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final steps = await getTodaySteps();
      final heartRate = await getTodayHeartRate();
      final sleep = await getTodaySleep();

      return DailyHealthSummary(
        date: date,
        steps: steps,
        distance: steps * 0.762, // 平均步长 0.762 米
        calories: (steps * 0.04).toInt(), // 平均每步消耗 0.04 卡路里
        heartRateAvg: heartRate['avg'] ?? 0,
        heartRateMax: heartRate['max'] ?? 0,
        heartRateMin: heartRate['min'] ?? 0,
        sleepDuration: sleep['total'] ?? 0,
        sleepDeep: sleep['deep'] ?? 0,
        sleepLight: sleep['light'] ?? 0,
      );
    } catch (error) {
      print('获取日期摘要失败: $error');
      rethrow;
    }
  }
}
```

### 3. 创建状态管理 Provider

创建 `lib/providers/health_provider.dart`：

```dart
import 'package:flutter/foundation.dart';
import '../models/health_data.dart';
import '../services/health_service.dart';

class HealthProvider with ChangeNotifier {
  final HealthService _healthService = HealthService();

  DailyHealthSummary? _todaySummary;
  bool _isLoading = false;
  String? _error;

  DailyHealthSummary? get todaySummary => _todaySummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> requestPermissions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final granted = await _healthService.requestPermissions();
      if (!granted) {
        _error = '权限被拒绝';
      }
    } catch (e) {
      _error = '权限请求失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTodayData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todaySummary = await _healthService.getDailySummary(DateTime.now());
    } catch (e) {
      _error = '加载数据失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    await loadTodayData();
  }
}
```

### 4. 创建 UI 屏幕

创建 `lib/screens/health_dashboard_screen.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';

class HealthDashboardScreen extends StatefulWidget {
  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HealthProvider>();
      provider.requestPermissions().then((_) {
        provider.loadTodayData();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('健康数据'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              context.read<HealthProvider>().refreshData();
            },
          ),
        ],
      ),
      body: Consumer<HealthProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(provider.error ?? '未知错误'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadTodayData();
                    },
                    child: Text('重试'),
                  ),
                ],
              ),
            );
          }

          final summary = provider.todaySummary;
          if (summary == null) {
            return Center(child: Text('暂无数据'));
          }

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              // 步数卡片
              _buildCard(
                title: '步数',
                value: '${summary.steps}',
                unit: '步',
                icon: Icons.directions_walk,
                color: Colors.blue,
              ),
              SizedBox(height: 16),

              // 心率卡片
              _buildCard(
                title: '心率',
                value: '${summary.heartRateAvg}',
                unit: 'bpm',
                icon: Icons.favorite,
                color: Colors.red,
                subtitle: '平均 | 最高 ${summary.heartRateMax} | 最低 ${summary.heartRateMin}',
              ),
              SizedBox(height: 16),

              // 睡眠卡片
              _buildCard(
                title: '睡眠',
                value: '${(summary.sleepDuration / 60).toStringAsFixed(1)}',
                unit: '小时',
                icon: Icons.bedtime,
                color: Colors.purple,
                subtitle: '深睡 ${summary.sleepDeep}分 | 浅睡 ${summary.sleepLight}分',
              ),
              SizedBox(height: 16),

              // 距离和卡路里
              Row(
                children: [
                  Expanded(
                    child: _buildSmallCard(
                      title: '距离',
                      value: '${(summary.distance / 1000).toStringAsFixed(2)}',
                      unit: 'km',
                      icon: Icons.map,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildSmallCard(
                      title: '卡路里',
                      value: '${summary.calories}',
                      unit: 'kcal',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(unit, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 4),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 2),
                Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5. 更新 main.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/health_provider.dart';
import 'screens/health_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlueWatch',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(
        create: (_) => HealthProvider(),
        child: HealthDashboardScreen(),
      ),
    );
  }
}
```

## 常见问题

### iOS 问题

**Q: HealthKit 权限一直被拒绝**
A: 检查 Info.plist 中的权限描述是否正确，并在 Xcode 中添加 HealthKit capability。

**Q: 无法读取睡眠数据**
A: 睡眠数据需要用户在 Apple Health 应用中手动添加或从兼容设备同步。

### Android 问题

**Q: Google Fit 权限请求失败**
A: 确保已在 Google Cloud Console 中启用 Fitness API，并配置了 OAuth 凭证。

**Q: 无法获取步数数据**
A: 确保用户已在 Google Fit 应用中授予权限，并且设备已同步数据。

## 测试指南

### 1. 在模拟器中测试

```bash
# iOS
flutter run -d iPhone

# Android
flutter run -d emulator-5554
```

### 2. 在真实设备中测试

```bash
# iOS
flutter run -d <device-id>

# Android
flutter run -d <device-id>
```

### 3. 测试权限流程

1. 启动应用
2. 允许权限请求
3. 验证数据是否正确加载

### 4. 测试数据刷新

1. 在 Health 应用中添加新数据
2. 点击应用中的刷新按钮
3. 验证新数据是否显示

## 下一步

1. 添加数据持久化（Hive）
2. 实现数据同步到后端
3. 添加数据分析和统计
4. 实现数据导出功能
5. 添加通知和提醒

---

**完成！** 你现在有了一个完整的 Apple HealthKit 和 Google Fit 集成方案。
