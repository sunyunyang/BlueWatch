import 'dart:io';
import 'health_service.dart';
import 'google_fit_service.dart';

/// 测试模式的健康数据服务
class TestHealthService {
  static final TestHealthService _instance = TestHealthService._internal();

  factory TestHealthService() {
    return _instance;
  }

  TestHealthService._internal();

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
    print('测试模式：权限已自动授予');
    return true;
  }

  /// 获取今日步数
  Future<int> getTodaySteps() async {
    print('测试模式：返回模拟步数 $_mockSteps');
    await Future.delayed(Duration(milliseconds: 500)); // 模拟网络延迟
    return _mockSteps;
  }

  /// 获取今日心率
  Future<Map<String, int>> getTodayHeartRate() async {
    print('测试模式：返回模拟心率数据');
    await Future.delayed(Duration(milliseconds: 500));
    return {
      'avg': _mockHeartRateAvg,
      'max': _mockHeartRateMax,
      'min': _mockHeartRateMin,
    };
  }

  /// 获取睡眠数据
  Future<Map<String, int>> getTodaySleep() async {
    print('测试模式：返回模拟睡眠数据');
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
    print('测试模式：返回模拟运动数据');
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

/// 统一的健康数据服务，支持 iOS、Android 和测试模式
class UnifiedHealthService {
  static final UnifiedHealthService _instance =
      UnifiedHealthService._internal();

  factory UnifiedHealthService() {
    return _instance;
  }

  UnifiedHealthService._internal();

  late final HealthService _iosService = HealthService();
  late final GoogleFitService _androidService = GoogleFitService();
  late final TestHealthService _testService = TestHealthService();

  // 是否使用测试模式
  bool _useTestMode = false;

  /// 启用/禁用测试模式
  void setTestMode(bool enabled) {
    _useTestMode = enabled;
    print('测试模式: ${enabled ? '已启用' : '已禁用'}');
  }

  /// 获取当前平台的服务
  dynamic _getService() {
    if (_useTestMode) {
      return _testService;
    }

    if (Platform.isIOS) {
      return _iosService;
    } else if (Platform.isAndroid) {
      return _androidService;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// 请求权限
  Future<bool> requestPermissions() async {
    try {
      final service = _getService();
      return await service.requestPermissions();
    } catch (error) {
      print('权限请求失败: $error');
      return false;
    }
  }

  /// 获取今日步数
  Future<int> getTodaySteps() async {
    try {
      final service = _getService();
      return await service.getTodaySteps();
    } catch (error) {
      print('获取步数失败: $error');
      return 0;
    }
  }

  /// 获取今日心率
  Future<Map<String, int>> getTodayHeartRate() async {
    try {
      final service = _getService();
      return await service.getTodayHeartRate();
    } catch (error) {
      print('获取心率失败: $error');
      return {'avg': 0, 'max': 0, 'min': 0};
    }
  }

  /// 获取睡眠数据
  Future<Map<String, int>> getTodaySleep() async {
    try {
      final service = _getService();
      return await service.getTodaySleep();
    } catch (error) {
      print('获取睡眠数据失败: $error');
      return {'total': 0, 'deep': 0, 'light': 0};
    }
  }

  /// 获取运动数据
  Future<List<Map<String, dynamic>>> getWorkouts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final service = _getService();
      return await service.getWorkouts(startDate: startDate, endDate: endDate);
    } catch (error) {
      print('获取运动数据失败: $error');
      return [];
    }
  }

  /// 获取平台名称
  String getPlatformName() {
    final service = _getService();
    return service.getPlatformName();
  }
}
