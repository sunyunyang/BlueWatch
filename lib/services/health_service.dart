import 'package:health/health.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();

  factory HealthService() {
    return _instance;
  }

  HealthService._internal();

  final HealthFactory _health = HealthFactory();

  // 请求权限
  Future<bool> requestPermissions() async {
    try {
      // iOS HealthKit 权限
      final types = [
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
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
        startOfDay,
        now,
        [HealthDataType.STEPS],
      );

      if (steps.isEmpty) return 0;

      return (steps.first.value as num).toInt();
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
        startOfDay,
        now,
        [HealthDataType.HEART_RATE],
      );

      if (heartRates.isEmpty) {
        return {'avg': 0, 'max': 0, 'min': 0};
      }

      final values = heartRates
          .map((e) => (e.value as num).toInt())
          .toList();

      return {
        'avg': (values.reduce((a, b) => a + b) / values.length).toInt(),
        'max': values.reduce((a, b) => a > b ? a : b),
        'min': values.reduce((a, b) => a < b ? a : b),
      };
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
        yesterday,
        now,
        [
          HealthDataType.SLEEP_IN_BED,
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_AWAKE,
        ],
      );

      if (sleepData.isEmpty) {
        return {'total': 0, 'deep': 0, 'light': 0};
      }

      // 计算睡眠时长（分钟）
      int totalSleep = 0;
      int deepSleep = 0;
      int lightSleep = 0;

      for (var data in sleepData) {
        if (data.type == HealthDataType.SLEEP_ASLEEP) {
          totalSleep += (data.value as num).toInt();
        } else if (data.type == HealthDataType.SLEEP_IN_BED) {
          deepSleep += (data.value as num).toInt();
        }
      }

      lightSleep = totalSleep - deepSleep;

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

  // 获取运动数据
  Future<List<Map<String, dynamic>>> getWorkouts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final workouts = await _health.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.WORKOUT],
      );

      return workouts
          .map((w) => {
                'type': w.typeString,
                'duration': w.value,
                'startTime': w.dateFrom,
                'endTime': w.dateTo,
              })
          .toList();
    } catch (error) {
      print('获取运动数据失败: $error');
      return [];
    }
  }
}
