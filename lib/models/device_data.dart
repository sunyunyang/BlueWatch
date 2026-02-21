/// 设备信息模型
class DeviceModel {
  final String id;
  final String name;
  final int rssi; // 信号强度

  DeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
  });

  @override
  String toString() => 'DeviceModel(id: $id, name: $name, rssi: $rssi)';
}

/// 心率数据
class HeartRateData {
  final int heartRate;
  final DateTime timestamp;

  HeartRateData({
    required this.heartRate,
    required this.timestamp,
  });

  @override
  String toString() => 'HeartRateData(heartRate: $heartRate, time: $timestamp)';
}

/// 步数数据
class StepData {
  final int steps;
  final int calories;
  final int distance; // 米
  final DateTime timestamp;

  StepData({
    required this.steps,
    required this.calories,
    required this.distance,
    required this.timestamp,
  });

  @override
  String toString() =>
      'StepData(steps: $steps, calories: $calories, distance: $distance, time: $timestamp)';
}

/// 睡眠数据
class SleepData {
  final double hours; // 睡眠时长（小时）
  final int deepSleep; // 深睡时长（分钟）
  final int lightSleep; // 浅睡时长（分钟）
  final DateTime timestamp;

  SleepData({
    required this.hours,
    required this.deepSleep,
    required this.lightSleep,
    required this.timestamp,
  });

  @override
  String toString() =>
      'SleepData(hours: $hours, deep: $deepSleep, light: $lightSleep, time: $timestamp)';
}

/// 运动记录
class WorkoutData {
  final String type; // 运动类型：running, cycling, swimming 等
  final int duration; // 时长（秒）
  final int calories;
  final double distance; // 米
  final int averageHeartRate;
  final DateTime startTime;

  WorkoutData({
    required this.type,
    required this.duration,
    required this.calories,
    required this.distance,
    required this.averageHeartRate,
    required this.startTime,
  });

  @override
  String toString() =>
      'WorkoutData(type: $type, duration: $duration, calories: $calories)';
}
