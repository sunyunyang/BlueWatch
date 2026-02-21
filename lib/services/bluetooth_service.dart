import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device_data.dart';

/// 蓝牙服务类
///
/// 负责扫描、连接、断开蓝牙设备，以及读取数据
class BluetoothService {
  /// 扫描到的设备列表
  final List<DeviceModel> _scannedDevices = [];

  /// 当前连接的设备
  BluetoothDevice? _connectedDevice;

  /// 订阅的服务和特征值
  BluetoothCharacteristic? _heartRateCharacteristic;

  /// 扫描状态
  bool _isScanning = false;

  /// 连接状态
  bool _isConnected = false;

  /// 扫描到的设备列表
  List<DeviceModel> get scannedDevices => List.unmodifiable(_scannedDevices);

  /// 是否正在扫描
  bool get isScanning => _isScanning;

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 当前连接的设备
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// 扫描设备
  ///
  /// [duration] 扫描时长，默认 4 秒
  /// [timeout] 扫描超时时间
  Future<List<DeviceModel>> scanDevices({
    Duration duration = const Duration(seconds: 4),
    Duration? timeout,
  }) async {
    if (_isScanning) {
      return _scannedDevices;
    }

    _scannedDevices.clear();
    _isScanning = true;

    try {
      // 开始扫描
      await FlutterBluePlus.startScan(timeout: duration);

      // 监听扫描结果
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.device.name.isNotEmpty) {
            final device = DeviceModel(
              id: r.device.remoteId.str,
              name: r.device.name,
              rssi: r.rssi,
            );

            // 避免重复添加
            if (!_scannedDevices.any((d) => d.id == device.id)) {
              _scannedDevices.add(device);
            }
          }
        }
      });

      // 等待扫描完成
      await Future.delayed(timeout ?? duration);

      // 停止扫描
      await FlutterBluePlus.stopScan();
      await subscription.cancel();
    } catch (e) {
      print('扫描设备失败: $e');
    } finally {
      _isScanning = false;
    }

    return _scannedDevices;
  }

  /// 连接设备
  ///
  /// [deviceId] 设备 ID
  Future<bool> connectDevice(String deviceId) async {
    try {
      // 停止扫描
      if (_isScanning) {
        await FlutterBluePlus.stopScan();
      }

      // 查找设备
      final devices = await FlutterBluePlus.connectedDevices;
      BluetoothDevice? device;

      // 如果已连接，直接使用
      for (var d in devices) {
        if (d.remoteId.str == deviceId) {
          device = d;
          break;
        }
      }

      // 如果未连接，建立新连接
      if (device == null) {
        final scannedDevices = await FlutterBluePlus.connectedDevices;
        for (var d in scannedDevices) {
          if (d.remoteId.str == deviceId) {
            device = d;
            break;
          }
        }

        if (device == null) {
          device = BluetoothDevice.fromId(deviceId);
        }
      }

      // 连接设备
      await device!.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      // 等待连接状态
      await device.connectionState.firstWhere(
        (state) => state == BluetoothConnectionState.connected,
      );

      _connectedDevice = device;
      _isConnected = true;

      // 发现服务
      await _discoverServices(device);

      return true;
    } catch (e) {
      print('连接设备失败: $e');
      _isConnected = false;
      _connectedDevice = null;
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _isConnected = false;
      _heartRateCharacteristic = null;
    }
  }

  /// 发现服务和特征值
  Future<void> _discoverServices(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (var service in services) {
      print('发现服务: ${service.uuid}');

      final characteristics = await service.characteristics;
      for (var characteristic in characteristics) {
        print('发现特征值: ${characteristic.uuid}');

        // 心率服务 UUID: 0x180D
        if (service.uuid == BluetoothServiceUUID(0x180D)) {
          // 心率测量特征值 UUID: 0x2A37
          if (characteristic.uuid == BluetoothCharacteristicUUID(0x2A37)) {
            _heartRateCharacteristic = characteristic;
            print('找到心率特征值');
          }
        }
      }
    }
  }

  /// 订阅心率数据
  ///
  /// [onData] 数据回调
  Future<void> subscribeHeartRate(Function(int heartRate) onData) async {
    if (_heartRateCharacteristic == null) {
      print('心率特征值未找到');
      return;
    }

    await _heartRateCharacteristic!.setNotifyValue(true);

    _heartRateCharacteristic!.value.listen((value) {
      if (value.isEmpty) return;

      // 解析心率数据（标准 Heart Rate Profile）
      final heartRate = _parseHeartRate(value);
      if (heartRate > 0) {
        onData(heartRate);
      }
    });
  }

  /// 解析心率数据
  ///
  /// [value] 原始数据
  /// 返回心率值（BPM）
  int _parseHeartRate(List<int> value) {
    // 根据 Bluetooth Heart Rate Profile 规范
    final flags = value[0];
    final heartRateFormat16Bit = (flags & 0x01) != 0;

    if (heartRateFormat16Bit) {
      // 16 位心率值
      return (value[1] + (value[2] << 8));
    } else {
      // 8 位心率值
      return value[1];
    }
  }

  /// 读取心率数据（一次性）
  Future<int> readHeartRate() async {
    if (_heartRateCharacteristic == null) {
      print('心率特征值未找到');
      return 0;
    }

    final value = await _heartRateCharacteristic!.read();
    return _parseHeartRate(value);
  }

  /// 释放资源
  void dispose() {
    _scannedDevices.clear();
    _heartRateCharacteristic = null;
  }
}
