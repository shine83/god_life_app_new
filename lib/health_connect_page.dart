import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:collection/collection.dart';

class HealthConnectPage extends StatefulWidget {
  const HealthConnectPage({super.key});

  @override
  State<HealthConnectPage> createState() => _HealthConnectPageState();
}

class _HealthConnectPageState extends State<HealthConnectPage> {
  final Health health = Health();
  String _statusText = '아래 버튼을 눌러 데이터를 불러오세요.';
  bool _isLoading = false;

  // 데이터 변수들
  int? _steps;
  double? _sleepMinutes;
  int? _heartRate;
  int? _activeEnergy;
  double? _weight;

  // SLEEP_IN_BED 타입으로 수면 데이터를 요청합니다.
  final types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WEIGHT,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_IN_BED,
  ];

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await health.installHealthConnect();
    }
    bool granted = await health.requestAuthorization(types);
    if (granted) {
      print("✅ 권한이 허용되었습니다.");
      _fetchAllData();
    } else {
      print("❌ 권한이 거부되었습니다.");
      if (mounted) {
        setState(() {
          _statusText = '데이터를 가져오려면 권한을 허용해야 합니다.';
        });
      }
    }
  }

  Future<void> _fetchAllData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _statusText = '건강 데이터 불러오는 중...';
      });
    }
    print("--- 🕵️ 데이터 불러오기 시작 ---");

    final now = DateTime.now();
    final startTime = now.subtract(const Duration(days: 3));
    DateTime wakeUpTime;

    try {
      List<HealthDataPoint> fetchedSleep = await health.getHealthDataFromTypes(
        startTime: startTime,
        endTime: now,
        types: [
          HealthDataType.SLEEP_IN_BED,
        ],
      );

      fetchedSleep = fetchedSleep.toSet().toList();

      final sleepInBedData = fetchedSleep
          .where((d) => d.type == HealthDataType.SLEEP_IN_BED)
          .toList();

      if (sleepInBedData.isNotEmpty) {
        sleepInBedData.sort((a, b) => a.dateTo.compareTo(b.dateTo));
        wakeUpTime = sleepInBedData.last.dateTo;
      } else {
        wakeUpTime = now.subtract(const Duration(days: 1));
      }
      print("--- ☀️ 계산된 기상 시간: $wakeUpTime ---");

      final fetchedSteps =
          await health.getTotalStepsInInterval(wakeUpTime, now);
      final otherData = await health.getHealthDataFromTypes(
        startTime: wakeUpTime,
        endTime: now,
        types: [
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.HEART_RATE,
          HealthDataType.WEIGHT,
        ],
      );

      _processHealthData(fetchedSteps, fetchedSleep, otherData);
    } catch (e) {
      if (mounted) setState(() => _statusText = '데이터 불러오기 실패: $e');
      print("--- 🔥 오류 발생: $e ---");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _processHealthData(
    int? fetchedSteps,
    List<HealthDataPoint> fetchedSleep,
    List<HealthDataPoint> otherData,
  ) {
    print("--- ⚙️ 가져온 데이터 처리 시작 ---");

    double totalSleep = 0.0;

    if (fetchedSleep.isNotEmpty) {
      fetchedSleep.sort((a, b) => a.dateTo.compareTo(b.dateTo));
      final finalSleepRecord = fetchedSleep.last;
      totalSleep = finalSleepRecord.dateTo
          .difference(finalSleepRecord.dateFrom)
          .inMinutes
          .toDouble();
      print("--- 🛌 중복 데이터 중 마지막 확정본 수면 시간: $totalSleep 분 ---");
    }

    HealthDataPoint? heartRateData =
        otherData.lastWhereOrNull((d) => d.type == HealthDataType.HEART_RATE);
    int? latestHeartRate = heartRateData == null
        ? null
        : (heartRateData.value as NumericHealthValue).numericValue.toInt();

    int totalActiveEnergy = otherData
        .where((d) => d.type == HealthDataType.ACTIVE_ENERGY_BURNED)
        .fold(
            0,
            (sum, d) =>
                sum + (d.value as NumericHealthValue).numericValue.toInt());

    HealthDataPoint? weightData =
        otherData.lastWhereOrNull((d) => d.type == HealthDataType.WEIGHT);
    double? latestWeight = weightData == null
        ? null
        : (weightData.value as NumericHealthValue).numericValue.toDouble();

    if (mounted) {
      setState(() {
        _steps = fetchedSteps;
        _sleepMinutes = totalSleep > 0 ? totalSleep : null;
        _heartRate = latestHeartRate;
        _activeEnergy = totalActiveEnergy > 0 ? totalActiveEnergy : null;
        _weight = latestWeight;
        _statusText = '✅ 데이터 불러오기 완료!';
      });
    }
    print("--- ✅ 데이터 처리 및 UI 업데이트 완료 ---");
  }

  Future<void> _openSystemSettings() async => await openAppSettings();

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '오늘의 건강 요약',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDataColumn('걸음 수', _steps?.toString() ?? '-', '걸음'),
                // 👇👇👇 이 부분이 수정되었습니다! 👇👇👇
                _buildDataColumn(
                    '수면',
                    _formatSleepDuration(_sleepMinutes), // 함수 호출
                    '' // 단위는 비워두기
                    ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDataColumn('심박수', _heartRate?.toString() ?? '-', 'BPM'),
                _buildDataColumn(
                    '소모 칼로리', _activeEnergy?.toString() ?? '-', 'kcal'),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 0.5, indent: 20, endIndent: 20),
            const SizedBox(height: 20),
            _buildDataColumn('체중', _weight?.toStringAsFixed(1) ?? '-', 'kg'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataColumn(String title, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  // ✅ [추가] 분(minute)을 'X시간 Y분' 형태로 변환하는 함수
  String _formatSleepDuration(double? totalMinutes) {
    if (totalMinutes == null || totalMinutes <= 0) {
      return '-';
    }

    final totalMinutesInt = totalMinutes.toInt();
    final hours = totalMinutesInt ~/ 60; // ~/ 연산자는 몫을 정수로 반환합니다.
    final minutes = totalMinutesInt % 60; // % 연산자는 나머지를 반환합니다.

    if (hours > 0 && minutes > 0) {
      return '$hours시간 ${minutes}분';
    } else if (hours > 0) {
      return '$hours시간';
    } else {
      return '$minutes분';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('건강앱 연동')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('앱과 연동하여 다양한 건강 데이터를 가져올 수 있습니다.'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white),
                icon: const Icon(Icons.verified_user),
                label: const Text('헬스 데이터 접근 권한 요청'),
                onPressed: _requestPermissions,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white),
                icon: const Icon(Icons.sync),
                label: const Text('모든 건강 데이터 불러오기'),
                onPressed: _fetchAllData,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white),
                icon: const Icon(Icons.settings),
                label: const Text('시스템 설정 열기'),
                onPressed: _openSystemSettings,
              ),
              const SizedBox(height: 20),
              Center(child: Text(_statusText)),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSummaryCard(),
            ],
          ),
        ),
      ),
    );
  }
}
