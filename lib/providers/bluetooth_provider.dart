import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/device_data.dart';
import '../services/bluetooth_service.dart';

/// 蓝牙状态管理
class BluetoothProvider with ChangeNotifier {
  final BluetoothService _bluetoothService = BluetoothService();

  /// 扫描到的设备列表
  List<DeviceModel> _devices = [];

  /// 当前连接的设备
  DeviceModel? _connectedDevice;

  /// 连接状态
  bool _isConnected = false;

  /// 扫描状态
  bool _isScanning = false;

  /// 心率数据流
  final StreamController<int> _heartRateController = StreamController<int>.broadcast();

  /// 当前心率
  int _currentHeartRate = 0;

  /// 历史心率数据
  final List<int> _heartRateHistory = [];

  /// 扫描到的设备列表
  List<DeviceModel> get devices => _devices;

  /// 当前连接的设备
  DeviceModel? get connectedDevice => _connectedDevice;

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 是否正在扫描
  bool get isScanning => _isScanning;

  /// 心率数据流
  Stream<int> get heartRateStream => _heartRateController.stream;

  /// 当前心率
  int get currentHeartRate => _currentHeartRate;

  /// 历史心率数据（最多 100 条）
  List<int> get heartRateHistory => _heartRateHistory.take(100).toList();

  /// 扫描设备
  Future<void> scanDevices() async {
    _isScanning = true;
    _devices.clear();
    notifyListeners();

    final results = await _bluetoothService.scanDevices();

    _devices = results;
    _isScanning = false;
    notifyListeners();
  }

  /// 连接设备
  ///
  /// [device] 要连接的设备
  Future<bool> connectDevice(DeviceModel device) async {
    final success = await _bluetoothService.connectDevice(device.id);

    if (success) {
      _connectedDevice = device;
      _isConnected = true;
      notifyListeners();

      // 订阅心率数据
      await _bluetoothService.subscribeHeartRate((heartRate) {
        _currentHeartRate = heartRate;
        _heartRateHistory.add(heartRate);
        _heartRateController.add(heartRate);
        notifyListeners();
      });
    }

    return success;
  }

  /// 断开连接
  Future<void> disconnect() async {
    await _bluetoothService.disconnect();
    _connectedDevice = null;
    _isConnected = false;
    _currentHeartRate = 0;
    notifyListeners();
  }

  /// 读取当前心率（一次性）
  Future<int> readHeartRate() async {
    return await _bluetoothService.readHeartRate();
  }

  /// 清空历史数据
  void clearHistory() {
    _heartRateHistory.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _heartRateController.close();
    _bluetoothService.dispose();
    super.dispose();
  }
}
