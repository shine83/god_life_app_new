// lib/work_stats_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'db_helper.dart';
import 'package:intl/intl.dart';

class WorkStatsPage extends StatefulWidget {
  const WorkStatsPage({super.key});

  @override
  State<WorkStatsPage> createState() => _WorkStatsPageState();
}

class _WorkStatsPageState extends State<WorkStatsPage> {
  late DateTime _startDate;
  late DateTime _endDate;
  List<WorkSchedule> _allSchedules = [];
  List<ShiftType> _shiftTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setToThisMonth();
    _loadData();
  }

  void _setToThisMonth() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  void _setToLastMonth() {
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    _startDate = DateTime(prevMonth.year, prevMonth.month, 1);
    _endDate = DateTime(prevMonth.year, prevMonth.month + 1, 0);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final schedules = await DBHelper.getAllWorkSchedules();
    final types = await DBHelper.getAllShiftTypes();
    if (mounted) {
      setState(() {
        _allSchedules = schedules;
        _shiftTypes = types;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 선택된 기간 내의 근무 기록만 필터링
    final filteredSchedules = _allSchedules.where((s) {
      final d = DateTime.parse(s.startDate);
      return d.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          d.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    int totalWorkDays = filteredSchedules.length;
    double totalWorkHours = 0;
    Map<String, int> patternCount = {};

    for (var schedule in filteredSchedules) {
      // ✅ 요청사항 반영: 야간 근무 시간 계산 로직 개선
      // 시작 날짜와 시간, 종료 날짜와 시간을 합쳐서 정확한 DateTime 객체를 생성합니다.
      final startDateTime =
          DateTime.parse('${schedule.startDate} ${schedule.startTime}');
      final endDateTime =
          DateTime.parse('${schedule.endDate} ${schedule.endTime}');

      // 두 DateTime 객체의 차이를 구하여 근무 시간을 계산합니다.
      // 이렇게 하면 날짜가 넘어가는 야간 근무도 정확하게 계산됩니다.
      final duration = endDateTime.difference(startDateTime);
      totalWorkHours += duration.inMinutes / 60.0;

      patternCount[schedule.pattern] =
          (patternCount[schedule.pattern] ?? 0) + 1;
    }

    final totalDaysInRange = _endDate.difference(_startDate).inDays + 1;
    final totalOffDays = totalDaysInRange - totalWorkDays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 근무 리포트'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('종합 근무 분석',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        '${DateFormat('yy.M.d').format(_startDate)} - ${DateFormat('yy.M.d').format(_endDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDateRange:
                              DateTimeRange(start: _startDate, end: _endDate),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked.start;
                            _endDate = picked.end;
                          });
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => setState(() => _setToThisMonth()),
                        child: const Text('이번 달')),
                    TextButton(
                        onPressed: () => setState(() => _setToLastMonth()),
                        child: const Text('지난 달')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryCards(totalWorkHours, totalWorkDays, totalOffDays),
                const SizedBox(height: 24),
                _buildPieChart(patternCount),
              ],
            ),
    );
  }

  Widget _buildSummaryCards(double hours, int workDays, int offDays) {
    return Row(
      children: [
        Expanded(
            child: _SummaryCard(
                title: '총 근무 시간',
                value: '${hours.toStringAsFixed(1)} 시간',
                icon: Icons.timer,
                color: Colors.orange)),
        const SizedBox(width: 12),
        Expanded(
            child: _SummaryCard(
                title: '총 근무일',
                value: '$workDays 일',
                icon: Icons.work,
                color: Colors.blue)),
        const SizedBox(width: 12),
        Expanded(
            child: _SummaryCard(
                title: '총 휴일',
                value: '$offDays 일',
                icon: Icons.beach_access,
                color: Colors.green)),
      ],
    );
  }

  Widget _buildPieChart(Map<String, int> patternCount) {
    if (patternCount.isEmpty) {
      return const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: Text('해당 기간의 근무 기록이 없습니다.')),
        ),
      );
    }

    final chartData = patternCount.entries.map((entry) {
      final type = _shiftTypes.firstWhere((t) => t.abbreviation == entry.key,
          orElse: () => ShiftType(
              name: '알 수 없음',
              abbreviation: '',
              startTime: TimeOfDay.now(),
              endTime: TimeOfDay.now(),
              color: Colors.grey));
      return PieChartSectionData(
        color: type.color,
        value: entry.value.toDouble(),
        title: '${entry.value}회',
        radius: 80,
        titleStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('근무 유형별 분석',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: chartData,
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: patternCount.keys.map((pattern) {
                final type = _shiftTypes.firstWhere(
                    (t) => t.abbreviation == pattern,
                    orElse: () => ShiftType(
                        name: '?',
                        abbreviation: '?',
                        startTime: TimeOfDay.now(),
                        endTime: TimeOfDay.now(),
                        color: Colors.grey));
                return _Indicator(color: type.color, text: type.name);
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _SummaryCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  const _Indicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
