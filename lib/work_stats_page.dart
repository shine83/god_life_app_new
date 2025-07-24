import 'package:flutter/material.dart';
import 'db_helper.dart';

class WorkStatsPage extends StatefulWidget {
  const WorkStatsPage({super.key});

  @override
  State<WorkStatsPage> createState() => _WorkStatsPageState();
}

class _WorkStatsPageState extends State<WorkStatsPage> {
  // 통계 데이터를 저장할 변수들
  int _totalWorkDays = 0;
  int _totalWorkHours = 0;
  int _totalNightAllowanceHours = 0;
  Map<String, int> _workDaysByPattern = {};
  List<ShiftType> _shiftTypes = []; // 근무 유형 정보를 저장할 리스트
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final allShiftTypes = await DBHelper.getAllShiftTypes();
    final allSchedules = await DBHelper.getAllWorkSchedules();

    if (allSchedules.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    // --- 통계 계산 로직 ---
    final uniqueWorkDays = <String>{};
    for (var schedule in allSchedules) {
      uniqueWorkDays.add(schedule.startDate);
    }
    final totalWorkDays = uniqueWorkDays.length;
    final totalWorkHours = totalWorkDays * 8;

    final tempWorkDaysByPattern = <String, int>{};
    for (var type in allShiftTypes) {
      final count =
          allSchedules.where((s) => s.pattern == type.abbreviation).length;
      if (count > 0) {
        tempWorkDaysByPattern[type.name] = count;
      }
    }

    int nightShiftCount = 0;
    for (var schedule in allSchedules) {
      final startTime = TimeOfDay(
        hour: int.parse(schedule.startTime.split(':')[0]),
        minute: int.parse(schedule.startTime.split(':')[1]),
      );
      if (startTime.hour >= 22 || startTime.hour < 6) {
        nightShiftCount++;
      }
    }
    final totalNightAllowanceHours = nightShiftCount * 7;

    // 계산된 데이터를 상태 변수에 저장
    if (mounted) {
      setState(() {
        _shiftTypes = allShiftTypes; // 근무 유형 리스트 저장
        _totalWorkDays = totalWorkDays;
        _totalWorkHours = totalWorkHours;
        _workDaysByPattern = tempWorkDaysByPattern;
        _totalNightAllowanceHours = totalNightAllowanceHours;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ## 👈 여기가 수정된 부분입니다! ##
    // 근무 패턴별 통계를 보여주는 위젯들을 동적으로 생성합니다.
    List<Widget> patternStatWidgets = _workDaysByPattern.entries.map((entry) {
      // 현재 패턴 이름(entry.key)에 해당하는 근무 유형(ShiftType) 정보를 찾습니다.
      final shiftType = _shiftTypes.firstWhere(
        (type) => type.name == entry.key,
        // 혹시 못찾을 경우를 대비한 기본값
        orElse: () => ShiftType(
            name: '',
            abbreviation: '',
            startTime: TimeOfDay.now(),
            endTime: TimeOfDay.now(),
            color: Colors.grey),
      );

      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          // 찾은 근무 유형의 색상을 아이콘 색상으로 사용합니다.
          leading: Icon(Icons.label, color: shiftType.color, size: 28),
          title: Text(entry.key,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: Text(
            '${entry.value} 일',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('근무 통계'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _totalWorkDays == 0
              ? const Center(
                  child: Text(
                    '표시할 근무 기록이 없습니다.\n캘린더에서 근무를 먼저 추가해주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '종합 근무 분석',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today,
                              color: Colors.deepPurple),
                          title: const Text('총 근무일'),
                          trailing: Text(
                            '$_totalWorkDays 일',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.timer_outlined,
                              color: Colors.green),
                          title: const Text('총 근무 시간'),
                          subtitle: const Text('(1일 8시간 기준)'),
                          trailing: Text(
                            '$_totalWorkHours 시간',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.nightlight_round,
                              color: Colors.orange),
                          title: const Text('야간 수당 시간'),
                          subtitle: const Text('(1회 7시간 기준)'),
                          trailing: Text(
                            '$_totalNightAllowanceHours 시간',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const Divider(height: 40),
                      const Text(
                        '근무 패턴별 근무일',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // 여기에 패턴별 통계 위젯들이 들어옵니다.
                      ...patternStatWidgets,
                    ],
                  ),
                ),
    );
  }
}
