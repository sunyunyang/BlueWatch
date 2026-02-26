import 'package:flutter/material.dart';

/// 简化版健康数据服务 - 仅使用模拟数据
class SimpleHealthService {
  static final SimpleHealthService _instance = SimpleHealthService._internal();

  factory SimpleHealthService() {
    return _instance;
  }

  SimpleHealthService._internal();

  // 模拟数据
  static const int _mockSteps = 8234;
  static const int _mockHeartRateAvg = 72;
  static const int _mockHeartRateMax = 95;
  static const int _mockHeartRateMin = 58;
  static const int _mockSleepTotal = 480; // 8 小时
  static const int _mockSleepDeep = 240; // 4 小时
  static const int _mockSleepLight = 240; // 4 小时

  /// 请求权限
  Future<bool> requestPermissions() async {
    print('✅ 权限已自动授予（测试模式）');
    return true;
  }

  /// 获取今日步数
  Future<int> getTodaySteps() async {
    print('📊 获取步数数据...');
    await Future.delayed(Duration(milliseconds: 500));
    return _mockSteps;
  }

  /// 获取今日心率
  Future<Map<String, int>> getTodayHeartRate() async {
    print('❤️ 获取心率数据...');
    await Future.delayed(Duration(milliseconds: 500));
    return {
      'avg': _mockHeartRateAvg,
      'max': _mockHeartRateMax,
      'min': _mockHeartRateMin,
    };
  }

  /// 获取睡眠数据
  Future<Map<String, int>> getTodaySleep() async {
    print('😴 获取睡眠数据...');
    await Future.delayed(Duration(milliseconds: 500));
    return {
      'total': _mockSleepTotal,
      'deep': _mockSleepDeep,
      'light': _mockSleepLight,
    };
  }

  /// 获取运动数据
  Future<List<Map<String, dynamic>>> getWorkouts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    print('🏃 获取运动数据...');
    await Future.delayed(Duration(milliseconds: 500));
    return [
      {
        'type': '跑步',
        'duration': 30,
        'startTime': DateTime.now().subtract(Duration(hours: 2)),
        'endTime': DateTime.now().subtract(Duration(hours: 1, minutes: 30)),
      },
      {
        'type': '骑行',
        'duration': 45,
        'startTime': DateTime.now().subtract(Duration(hours: 5)),
        'endTime': DateTime.now().subtract(Duration(hours: 4, minutes: 15)),
      },
    ];
  }

  /// 获取平台名称
  String getPlatformName() {
    return '测试模式 (Mock Data)';
  }
}
