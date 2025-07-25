import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthConnectPage extends StatefulWidget {
  const HealthConnectPage({super.key});

  @override
  State<HealthConnectPage> createState() => _HealthConnectPageState();
}

class _HealthConnectPageState extends State<HealthConnectPage> {
  final HealthFactory health = HealthFactory();
  bool _isAuthorized = false;
  String _statusText = '연동 상태를 확인하려면 버튼을 눌러주세요.';

  Future<void> _requestPermissions() async {
    // ✅ 권한 요청 (Android는 Health Connect, iOS는 HealthKit)
    final types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.WEIGHT,
      HealthDataType.SLEEP_IN_BED,
    ];

    bool requested = await health.requestAuthorization(types);
    setState(() {
      _isAuthorized = requested;
      _statusText = requested ? '✅ 헬스 데이터 접근이 허용되었습니다.' : '❌ 접근 권한을 거부했습니다.';
    });
  }

  Future<void> _fetchTodaySteps() async {
    if (!_isAuthorized) {
      setState(() {
        _statusText = '먼저 권한을 허용해주세요!';
      });
      return;
    }

    DateTime endDate = DateTime.now();
    DateTime startDate = DateTime(endDate.year, endDate.month, endDate.day);

    try {
      final steps = await health.getTotalStepsInInterval(startDate, endDate);
      setState(() {
        _statusText =
            steps != null ? '오늘 걸음 수: $steps 걸음' : '오늘 걸음 수를 불러올 수 없습니다.';
      });
    } catch (e) {
      setState(() {
        _statusText = '오류: $e';
      });
    }
  }

  Future<void> _openSystemSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('헬스 연동'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '📲 Google Health Connect (Android) / Apple HealthKit (iOS)\n'
              '앱과 연동하여 걸음 수, 심박수 등의 데이터를 가져올 수 있습니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.favorite),
              label: const Text('헬스 데이터 접근 권한 요청'),
              onPressed: _requestPermissions,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.directions_walk),
              label: const Text('오늘 걸음 수 불러오기'),
              onPressed: _fetchTodaySteps,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('시스템 설정 열기'),
              onPressed: _openSystemSettings,
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _statusText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
