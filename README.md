# BlueWatch

通过蓝牙连接运动手表，读取心率、步数、睡眠等健康数据的 Flutter 应用。

## 功能特性

- ✅ 蓝牙设备扫描
- ✅ 设备连接/断开
- ✅ 实时心率监测
- ✅ 心率历史图表
- 🚧 步数读取（开发中）
- 🚧 睡眠数据读取（开发中）
- 🚧 运动记录读取（开发中）

## 技术栈

- **框架**: Flutter 3.x
- **语言**: Dart
- **蓝牙库**: flutter_blue_plus
- **状态管理**: Provider
- **图表**: fl_chart

## 项目结构

```
lib/
├── models/          # 数据模型
│   └── device_data.dart
├── services/        # 业务逻辑
│   └── bluetooth_service.dart
├── providers/       # 状态管理
│   └── bluetooth_provider.dart
├── screens/         # 页面
│   └── home_screen.dart
├── widgets/         # 组件
│   ├── device_list_item.dart
│   └── heart_rate_chart.dart
└── main.dart        # 应用入口
```

## 快速开始

### 环境要求

- Flutter SDK >= 3.11.0
- Android SDK >= 21 (Android 5.0)
- iOS >= 13.0

### 安装依赖

```bash
cd bluewatch
flutter pub get
```

### 运行应用

```bash
# 连接 Android 设备
flutter devices

# 运行应用
flutter run
```

## 蓝牙 GATT 服务说明

### 心率服务 (Heart Rate Service)
- **UUID**: `0x180D`
- **特征值**:
  - 心率测量: `0x2A37` (Notify)

### 标准蓝牙服务支持

本应用基于 Bluetooth Low Energy (BLE) 标准 GATT 服务实现，支持大多数支持标准心率服务的蓝牙设备。

## 权限说明

### Android
- `BLUETOOTH` - 蓝牙连接
- `BLUETOOTH_ADMIN` - 蓝牙管理
- `BLUETOOTH_SCAN` - 蓝牙扫描
- `BLUETOOTH_CONNECT` - 蓝牙连接
- `ACCESS_FINE_LOCATION` - 位置权限（扫描蓝牙需要）

### iOS
- 在 `Info.plist` 中添加:
  - `NSBluetoothAlwaysUsageDescription`
  - `NSBluetoothPeripheralUsageDescription`

## 开发计划

### V1.0（当前版本）
- [x] 蓝牙扫描
- [x] 设备连接
- [x] 心率读取和显示
- [x] 心率历史图表

### V1.1（计划中）
- [ ] 步数读取
- [ ] 卡路里读取
- [ ] 距离读取

### V1.2（计划中）
- [ ] 睡眠数据读取
- [ ] 睡眠质量分析
- [ ] 睡眠历史记录

### V2.0（远期）
- [ ] 运动记录读取
- [ ] 数据本地存储
- [ ] 数据导出功能
- [ ] 多语言支持

## 参考项目

- [running_page](https://github.com/yihong0618/running_page) - 运动数据展示页面
- [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus) - Flutter 蓝牙库

## 常见问题

### Q: 扫描不到设备？
A: 确保设备已开启蓝牙，并且在附近。某些设备需要先配对。

### Q: 连接失败？
A: 检查设备是否被其他应用占用，尝试重启设备或关闭其他蓝牙应用。

### Q: 心率数据不准确？
A: 不同品牌的手表可能有不同的 GATT 服务，需要针对性适配。

## License

MIT License
