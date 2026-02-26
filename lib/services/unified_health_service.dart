import 'dart:io';
import 'health_service.dart';
import 'google_fit_service.dart';

/// 统一的健康数据服务，支持 iOS HealthKit 和 Android Google Fit
class UnifiedHealthService {
  static final UnifiedHealthService _instance =
      UnifiedHealthService._internal();

  factory UnifiedHealthService() {
    return _instance;
  }

  UnifiedHealthService._internal();

  late final HealthService _iosService = HealthService();
  late final GoogleFitService _androidService = GoogleFitService();

  /// 获取当前平台的服务
  dynamic _getService() {
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
    if (Platform.isIOS) {
      return 'iOS HealthKit';
    } else if (Platform.isAndroid) {
      return 'Android Google Fit';
    }
    return 'Unknown';
  }
}
