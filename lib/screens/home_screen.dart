import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bluetooth_provider.dart';
import '../models/device_data.dart';
import '../widgets/heart_rate_chart.dart';
import '../widgets/device_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BlueWatch'),
        elevation: 0,
        actions: [
          Consumer<BluetoothProvider>(
            builder: (context, bluetooth, child) {
              if (bluetooth.isConnected) {
                return IconButton(
                  icon: const Icon(Icons.bluetooth_connected),
                  onPressed: () => _showDisconnectDialog(context, bluetooth),
                );
              }
              return IconButton(
                icon: const Icon(Icons.bluetooth_searching),
                onPressed: () => _scanDevices(context, bluetooth),
              );
            },
          ),
        ],
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, bluetooth, child) {
          if (bluetooth.isConnected) {
            return _buildConnectedView(context, bluetooth);
          } else if (bluetooth.isScanning) {
            return _buildScanningView(context, bluetooth);
          } else if (bluetooth.devices.isEmpty) {
            return _buildEmptyView(context, bluetooth);
          } else {
            return _buildDeviceListView(context, bluetooth);
          }
        },
      ),
    );
  }

  /// 已连接的视图
  Widget _buildConnectedView(BuildContext context, BluetoothProvider bluetooth) {
    return Column(
      children: [
        // 设备信息卡片
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.watch, size: 48, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bluetooth.connectedDevice?.name ?? '未知设备',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '已连接',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 心率显示
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  '实时心率',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Consumer<BluetoothProvider>(
                  builder: (context, bluetooth, child) {
                    return Text(
                      '${bluetooth.currentHeartRate}',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    );
                  },
                ),
                const Text(
                  'BPM',
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                // 心率历史图表
                Expanded(
                  child: HeartRateChart(
                    data: bluetooth.heartRateHistory,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 扫描中视图
  Widget _buildScanningView(BuildContext context, BluetoothProvider bluetooth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            '正在扫描蓝牙设备...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '已找到 ${bluetooth.devices.length} 个设备',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 空视图
  Widget _buildEmptyView(BuildContext context, BluetoothProvider bluetooth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_disabled,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            '未发现设备',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _scanDevices(context, bluetooth),
            icon: const Icon(Icons.refresh),
            label: const Text('重新扫描'),
          ),
        ],
      ),
    );
  }

  /// 设备列表视图
  Widget _buildDeviceListView(BuildContext context, BluetoothProvider bluetooth) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '发现 ${bluetooth.devices.length} 个设备',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: bluetooth.devices.length,
            itemBuilder: (context, index) {
              final device = bluetooth.devices[index];
              return DeviceListItem(
                device: device,
                onTap: () => _connectDevice(context, bluetooth, device),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 扫描设备
  Future<void> _scanDevices(
    BuildContext context,
    BluetoothProvider bluetooth,
  ) async {
    await bluetooth.scanDevices();

    if (!context.mounted) return;

    if (bluetooth.devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未发现任何设备')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发现 ${bluetooth.devices.length} 个设备')),
      );
    }
  }

  /// 连接设备
  Future<void> _connectDevice(
    BuildContext context,
    BluetoothProvider bluetooth,
    DeviceModel device,
  ) async {
    final success = await bluetooth.connectDevice(device);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已连接到 ${device.name}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('连接失败，请重试')),
      );
    }
  }

  /// 显示断开连接对话框
  void _showDisconnectDialog(
    BuildContext context,
    BluetoothProvider bluetooth,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('断开连接'),
        content: Text('确定要断开与 ${bluetooth.connectedDevice?.name} 的连接吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              bluetooth.disconnect();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已断开连接')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
