import 'package:flutter/material.dart';
import '../services/simple_health_service.dart';

class HealthDashboardScreen extends StatefulWidget {
  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  final SimpleHealthService _healthService = SimpleHealthService();

  int _steps = 0;
  Map<String, int> _heartRate = {'avg': 0, 'max': 0, 'min': 0};
  Map<String, int> _sleep = {'total': 0, 'deep': 0, 'light': 0};
  bool _isLoading = true;
  String _platformName = '';

  @override
  void initState() {
    super.initState();
    _platformName = _healthService.getPlatformName();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    setState(() => _isLoading = true);

    final hasPermission = await _healthService.requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('需要健康数据权限')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final steps = await _healthService.getTodaySteps();
    final heartRate = await _healthService.getTodayHeartRate();
    final sleep = await _healthService.getTodaySleep();

    if (mounted) {
      setState(() {
        _steps = steps;
        _heartRate = heartRate;
        _sleep = sleep;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('健康数据'),
            Text(
              _platformName,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHealthData,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '使用 $_platformName 读取健康数据',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('步数',
                              style: Theme.of(context).textTheme.titleLarge),
                          SizedBox(height: 8),
                          Text(
                            '$_steps 步',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('心率',
                              style: Theme.of(context).textTheme.titleLarge),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text('平均'),
                                  Text('${_heartRate['avg']} bpm'),
                                ],
                              ),
                              Column(
                                children: [
                                  Text('最高'),
                                  Text('${_heartRate['max']} bpm'),
                                ],
                              ),
                              Column(
                                children: [
                                  Text('最低'),
                                  Text('${_heartRate['min']} bpm'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('睡眠',
                              style: Theme.of(context).textTheme.titleLarge),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text('总时长'),
                                  Text(
                                      '${(_sleep['total']! / 60).toStringAsFixed(1)} 小时'),
                                ],
                              ),
                              Column(
                                children: [
                                  Text('深睡'),
                                  Text(
                                      '${(_sleep['deep']! / 60).toStringAsFixed(1)} 小时'),
                                ],
                              ),
                              Column(
                                children: [
                                  Text('浅睡'),
                                  Text(
                                      '${(_sleep['light']! / 60).toStringAsFixed(1)} 小时'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
