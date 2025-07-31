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

  int? _steps;
  double? _sleepMinutes;
  int? _heartRate;
  int? _activeEnergy;
  double? _weight;

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
      _fetchAllData();
    } else {
      if (mounted) {
        setState(() {
          _statusText = '데이터를 가져오려면 권한을 허용해야 합니다.';
        });
      }
    }
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _statusText = '건강 데이터 불러오는 중...';
    });

    final now = DateTime.now();
    final startTime = now.subtract(const Duration(days: 3));
    DateTime wakeUpTime;

    try {
      List<HealthDataPoint> fetchedSleep = await health.getHealthDataFromTypes(
        startTime: startTime,
        endTime: now,
        types: [HealthDataType.SLEEP_IN_BED],
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
      setState(() => _statusText = '데이터 불러오기 실패: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processHealthData(
    int? fetchedSteps,
    List<HealthDataPoint> fetchedSleep,
    List<HealthDataPoint> otherData,
  ) {
    double totalSleep = 0.0;

    if (fetchedSleep.isNotEmpty) {
      fetchedSleep.sort((a, b) => a.dateTo.compareTo(b.dateTo));
      final finalSleepRecord = fetchedSleep.last;
      totalSleep = finalSleepRecord.dateTo
          .difference(finalSleepRecord.dateFrom)
          .inMinutes
          .toDouble();
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

    setState(() {
      _steps = fetchedSteps;
      _sleepMinutes = totalSleep > 0 ? totalSleep : null;
      _heartRate = latestHeartRate;
      _activeEnergy = totalActiveEnergy; // 0이어도 표시
      _weight = latestWeight;
      _statusText = '✅ 데이터 불러오기 완료!';
    });
  }

  String _formatSleepDuration(double? totalMinutes) {
    if (totalMinutes == null || totalMinutes <= 0) return '-';
    final totalMinutesInt = totalMinutes.toInt();
    final hours = totalMinutesInt ~/ 60;
    final minutes = totalMinutesInt % 60;
    return '${hours}H ${minutes}M';
  }

  Widget _buildSummaryCard() {
    final titleStyle = TextStyle(fontSize: 13, color: Colors.grey.shade700);
    final valueStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          fontSize: 18,
        );
    final unitStyle = TextStyle(fontSize: 12, color: Colors.grey.shade600);

    Widget item(String title, String value, String unit) {
      return Column(
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 6),
          Text(value, style: valueStyle),
          const SizedBox(height: 2),
          Text(unit, style: unitStyle),
        ],
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
        child: Column(
          children: [
            Text(
              '오늘의 건강 요약',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                item('걸음 수', _steps?.toString() ?? '-', '걸음'),
                item('수면', _formatSleepDuration(_sleepMinutes), ''),
              ],
            ),
            const SizedBox(height: 20),
            Center(child: item('체중', _weight?.toStringAsFixed(1) ?? '-', 'kg')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                item('심박수', _heartRate?.toString() ?? '-', 'BPM'),
                item('소모 칼로리', _activeEnergy?.toString() ?? '-', 'kcal'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSystemSettings() async => await openAppSettings();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('건강앱 연동')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                  backgroundColor: Colors.green, foregroundColor: Colors.white),
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
            Text(_statusText),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : _buildSummaryCard(),
          ],
        ),
      ),
    );
  }
}
