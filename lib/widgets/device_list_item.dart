import 'package:flutter/material.dart';
import '../models/device_data.dart';

/// 设备列表项组件
class DeviceListItem extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onTap;

  const DeviceListItem({
    super.key,
    required this.device,
    required this.onTap,
  });

  /// 根据 RSSI 获取信号强度图标
  IconData _getSignalIcon(int rssi) {
    if (rssi >= -50) return Icons.signal_cellular_4_bar;
    if (rssi >= -60) return Icons.signal_cellular_3_bar;
    if (rssi >= -70) return Icons.signal_cellular_2_bar;
    if (rssi >= -80) return Icons.signal_cellular_1_bar;
    return Icons.signal_cellular_0_bar;
  }

  /// 根据 RSSI 获取信号强度颜色
  Color _getSignalColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -60) return Colors.lightGreen;
    if (rssi >= -70) return Colors.orange;
    if (rssi >= -80) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.watch,
            color: Colors.blue[700],
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '信号: ${device.rssi} dBm',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getSignalIcon(device.rssi),
              color: _getSignalColor(device.rssi),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
