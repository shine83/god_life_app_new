// lib/work_schedule_page.dart

import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'db_helper.dart';
import 'ai_service.dart';
import 'notification_service.dart';

class WorkSchedulePage extends StatefulWidget {
  const WorkSchedulePage({super.key});
  @override
  State<WorkSchedulePage> createState() => _WorkSchedulePageState();
}

class _WorkSchedulePageState extends State<WorkSchedulePage>
    with TickerProviderStateMixin {
  Map<DateTime, List<WorkSchedule>> scheduleMap = {};
  List<ShiftType> _shiftTypes = [];
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  late TabController _tabController;

  String _todayAIHealthTip = '건강 팁을 불러오는 중...';
  String _todayQuote = '오늘의 명언을 불러오는 중...';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final allSchedules = await DBHelper.getAllWorkSchedules();
    final allTypes = await DBHelper.getAllShiftTypes();
    final tempScheduleMap = <DateTime, List<WorkSchedule>>{};
    for (var s in allSchedules) {
      final d = DateTime.parse(s.startDate);
      final key = DateTime.utc(d.year, d.month, d.day);
      tempScheduleMap.putIfAbsent(key, () => []).add(s);
    }
    if (mounted) {
      setState(() {
        scheduleMap = tempScheduleMap;
        _shiftTypes = allTypes;
      });
      _fetchHomePageData();
    }
  }

  // ✅ [요청사항] AI 호출 대신 로컬 데이터를 가져오도록 함수 이름 및 내용 수정
  Future<void> _fetchHomePageData() async {
    final today = DateTime.now();
    final todayKey = DateTime.utc(today.year, today.month, today.day);
    final currentPattern = scheduleMap[todayKey]?.firstOrNull?.pattern ?? '휴일';

    // ✅ AI 호출 대신 로컬 팁 함수 호출
    final healthTip = _getLocalHealthTip(_getWorkTypeName(currentPattern));

    // 명언은 계속 AI 사용
    final quote = await AIService.getQuoteOfTheDay();

    if (mounted) {
      setState(() {
        _todayAIHealthTip = healthTip;
        _todayQuote = quote;
      });
    }
  }

  // ✅ [요청사항] 근무 유형에 따라 미리 준비된 팁을 랜덤으로 반환하는 함수
  String _getLocalHealthTip(String workType) {
    final Random random = Random();
    final Map<String, List<String>> tips = {
      '주간근무': [
        '점심 식사 후 가벼운 산책으로 활력을 더해보세요.',
        '중간중간 스트레칭으로 굳은 몸을 풀어주는 건 어때요?',
        '퇴근 후 스마트폰보다 따뜻한 차 한잔으로 하루를 마무리하세요.',
      ],
      '오후근무': [
        '근무 전 가벼운 식사로 에너지를 보충하세요.',
        '늦은 시간 퇴근 후 과식은 피하고 간단하게 허기를 채워보세요.',
        '오전 시간을 활용해 운동이나 취미 활동을 즐겨보세요.',
      ],
      '야간근무': [
        '근무 전 충분한 수면으로 밤샘 근무에 대비하세요.',
        '근무 중 카페인 섭취는 최소화하고 물을 자주 마시는 게 좋아요.',
        '퇴근 후에는 암막 커튼을 활용해 숙면 환경을 만들어보세요.',
      ],
      '휴일': [
        '오늘은 푹 쉬면서 재충전의 시간을 갖는 건 어때요?',
        '가까운 공원으로 산책을 나가 신선한 공기를 마셔보세요.',
        '그동안 미뤄왔던 취미 활동으로 스트레스를 풀어보세요.',
      ]
    };

    final tipList = tips[workType] ?? tips['휴일']!;
    return tipList[random.nextInt(tipList.length)];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _showInfoPanel(context);
  }

  String _getWorkTypeName(String pattern) {
    if (pattern == '휴일') return '휴일';
    final type = _shiftTypes.firstWhere((t) => t.abbreviation == pattern,
        orElse: () => ShiftType(
            name: '알 수 없음',
            abbreviation: '',
            startTime: TimeOfDay.now(),
            endTime: TimeOfDay.now(),
            color: Colors.grey));
    return type.name;
  }

  Color _getColorForPattern(String? pattern) {
    if (pattern == null) return Colors.transparent;
    final type = _shiftTypes.firstWhere((t) => t.abbreviation == pattern,
        orElse: () => ShiftType(
            name: '',
            abbreviation: '',
            startTime: TimeOfDay.now(),
            endTime: TimeOfDay.now(),
            color: Colors.transparent));
    return type.color;
  }

  void _showAdvancedScheduleDialog({WorkSchedule? schedule}) {
    showDialog(
        context: context,
        builder: (ctx) => Dialog.fullscreen(
            child: _AdvancedScheduleForm(
                initialShiftTypes: _shiftTypes,
                editingSchedule: schedule,
                selectedDate: _selectedDay,
                onSave: () {
                  Navigator.pop(ctx);
                  _loadData();
                })));
  }

  void _showInfoPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return _InfoPanel(
              key: ValueKey(_selectedDay),
              selectedDay: _selectedDay!,
              shiftTypes: _shiftTypes,
              scheduleMap: scheduleMap,
              scrollController: scrollController,
              tabController: _tabController,
              onEdit: (schedule) {
                Navigator.pop(context);
                _showAdvancedScheduleDialog(schedule: schedule);
              },
              onDelete: (schedule) async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                              title: const Text('삭제 확인'),
                              content: Text(
                                  '${DateFormat('M월 d일').format(DateTime.parse(schedule.startDate))}의 근무를 삭제할까요?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('취소')),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('삭제')),
                              ],
                            )) ??
                    false;
                if (confirm) {
                  await DBHelper.deleteWorkSchedule(schedule.id!);
                  _loadData();
                }
              },
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        _selectedDay = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('yyyy. M').format(_focusedDay),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.today),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime.now();
                });
              },
              tooltip: '오늘로 이동'),
          IconButton(
              icon: const Icon(Icons.add_task),
              onPressed: () => _showAdvancedScheduleDialog(),
              tooltip: '근무 추가'),
          IconButton(
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                          title: const Text('⚠️ 전체 일정 삭제'),
                          content: const Text(
                              '정말 모든 근무 일정을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('취소')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('삭제',
                                    style: TextStyle(color: Colors.red)))
                          ],
                        ));
                if (confirm == true) {
                  await DBHelper.clearAllSchedules();
                  _loadData();
                }
              },
              tooltip: '전체 일정 삭제'),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TableCalendar(
              locale: 'ko_KR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarFormat: CalendarFormat.month,
              daysOfWeekHeight: 24,
              headerStyle: const HeaderStyle(
                  formatButtonVisible: false, titleCentered: true),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) =>
                    _buildCalendarCell(day),
                todayBuilder: (context, day, focusedDay) =>
                    _buildCalendarCell(day, isToday: true),
                selectedBuilder: (context, day, focusedDay) =>
                    _buildCalendarCell(day, isSelected: true),
                outsideBuilder: (context, day, focusedDay) =>
                    _buildCalendarCell(day, isOutside: true),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: ListView(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("오늘의 건강 팁 💡",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                  icon: const Icon(Icons.refresh,
                                      size: 20, color: Colors.grey),
                                  onPressed: _fetchHomePageData,
                                  tooltip: '새로고침')
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_todayAIHealthTip,
                              style: TextStyle(fontSize: 15, height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("오늘의 명언 📖",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(_todayQuote,
                              style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day,
      {bool isToday = false, bool isSelected = false, bool isOutside = false}) {
    final dayKey = DateTime.utc(day.year, day.month, day.day);
    final schedule = scheduleMap[dayKey]?.firstOrNull;
    final cellColor = _getColorForPattern(schedule?.pattern);
    final isFilled = schedule != null;
    final dayColor = isOutside
        ? Colors.grey[400]
        : (isFilled
            ? Colors.white
            : (day.weekday == DateTime.sunday
                ? Colors.red[400]
                : (day.weekday == DateTime.saturday
                    ? Colors.blue[400]
                    : (isToday ? Colors.deepPurple : Colors.black87))));
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: isFilled ? cellColor.withOpacity(0.9) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        border: isSelected
            ? Border.all(color: Colors.deepPurple, width: 2)
            : (isToday && !isFilled
                ? Border.all(color: Colors.deepPurple.withOpacity(0.5))
                : null),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${day.day}',
                style: TextStyle(
                    color: dayColor,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
            if (isFilled)
              Text(schedule!.pattern,
                  style: TextStyle(color: dayColor, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatefulWidget {
  final DateTime selectedDay;
  final List<ShiftType> shiftTypes;
  final Map<DateTime, List<WorkSchedule>> scheduleMap;
  final ScrollController scrollController;
  final TabController tabController;
  final Function(WorkSchedule) onEdit;
  final Function(WorkSchedule) onDelete;

  const _InfoPanel(
      {super.key,
      required this.selectedDay,
      required this.shiftTypes,
      required this.scheduleMap,
      required this.scrollController,
      required this.tabController,
      required this.onEdit,
      required this.onDelete});
  @override
  State<_InfoPanel> createState() => _InfoPanelState();
}

class _InfoPanelState extends State<_InfoPanel> {
  String _detailedRecommendation = 'AI 추천을 불러오는 중...';
  String _workoutRecommendation = 'AI 운동 추천을 불러오는 중...';

  @override
  void initState() {
    super.initState();
    _fetchAllRecommendations();
  }

  @override
  void didUpdateWidget(covariant _InfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(widget.selectedDay, oldWidget.selectedDay)) {
      _fetchAllRecommendations();
    }
  }

  Future<void> _fetchAllRecommendations() async {
    _fetchDetailedRecommendation();
    _fetchWorkoutRecommendation();
  }

  Future<void> _fetchDetailedRecommendation() async {
    setState(() {
      _detailedRecommendation = 'AI 추천을 불러오는 중...';
    });
    final dayKey = DateTime.utc(widget.selectedDay.year,
        widget.selectedDay.month, widget.selectedDay.day);
    final currentSchedule = widget.scheduleMap[dayKey]?.firstOrNull;
    final currentPattern = currentSchedule?.pattern ?? '휴일';
    final previousPattern = widget
            .scheduleMap[dayKey.subtract(const Duration(days: 1))]
            ?.firstOrNull
            ?.pattern ??
        '정보 없음';
    final nextPattern = widget.scheduleMap[dayKey.add(const Duration(days: 1))]
            ?.firstOrNull?.pattern ??
        '정보 없음';

    final recommendation = await AIService.getDetailedRecommendation(
        currentWorkType: _getWorkTypeName(currentPattern),
        previousWorkType: _getWorkTypeName(previousPattern),
        nextWorkType: _getWorkTypeName(nextPattern));
    if (mounted) setState(() => _detailedRecommendation = recommendation);
  }

  Future<void> _fetchWorkoutRecommendation() async {
    setState(() {
      _workoutRecommendation = 'AI 운동 추천을 불러오는 중...';
    });
    final dayKey = DateTime.utc(widget.selectedDay.year,
        widget.selectedDay.month, widget.selectedDay.day);
    final currentSchedule = widget.scheduleMap[dayKey]?.firstOrNull;
    final currentPattern = currentSchedule?.pattern ?? '휴일';
    final previousPattern = widget
            .scheduleMap[dayKey.subtract(const Duration(days: 1))]
            ?.firstOrNull
            ?.pattern ??
        '정보 없음';

    final recommendation = await AIService.getWorkoutRecommendation(
      currentWorkType: _getWorkTypeName(currentPattern),
      previousWorkType: _getWorkTypeName(previousPattern),
    );
    if (mounted) setState(() => _workoutRecommendation = recommendation);
  }

  String _getWorkTypeName(String pattern) {
    if (pattern == '휴일') return '휴일';
    final type = widget.shiftTypes.firstWhere((t) => t.abbreviation == pattern,
        orElse: () => ShiftType(
            name: '알 수 없음',
            abbreviation: '',
            startTime: TimeOfDay.now(),
            endTime: TimeOfDay.now(),
            color: Colors.grey));
    return type.name;
  }

  @override
  Widget build(BuildContext context) {
    final dayKey = DateTime.utc(widget.selectedDay.year,
        widget.selectedDay.month, widget.selectedDay.day);
    final schedule = widget.scheduleMap[dayKey]?.firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12),
          Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10))),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildScheduleInfoCard(schedule, context)),
          TabBar(
              controller: widget.tabController,
              labelStyle: TextStyle(fontSize: 14),
              tabs: const [Tab(text: 'AI 추천팁'), Tab(text: '오늘의 운동')]),
          Expanded(
            child: TabBarView(controller: widget.tabController, children: [
              SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(_detailedRecommendation)),
              SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(_workoutRecommendation)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInfoCard(WorkSchedule? schedule, BuildContext context) {
    if (schedule == null) {
      return Card(
          elevation: 0,
          child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text("선택한 날짜에 근무 일정이 없습니다.",
                  style: TextStyle(fontSize: 14))));
    }
    final type = widget.shiftTypes.firstWhere(
        (t) => t.abbreviation == schedule.pattern,
        orElse: () => ShiftType(
            name: '알수없음',
            abbreviation: '?',
            startTime: TimeOfDay.now(),
            endTime: TimeOfDay.now(),
            color: Colors.grey));
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        '${DateFormat('M월 d일 (E)', 'ko_KR').format(widget.selectedDay)} 근무',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(type.name,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: type.color)),
                  ])),
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Colors.blue, size: 22),
                    onPressed: () => widget.onEdit(schedule),
                    tooltip: '근무 수정',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
                IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 22),
                    onPressed: () => widget.onDelete(schedule),
                    tooltip: '근무 삭제',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
              ]),
            ]),
            const SizedBox(height: 6),
            Text('⏰ ${schedule.startTime} ~ ${schedule.endTime}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}

class _AdvancedScheduleForm extends StatefulWidget {
  final VoidCallback onSave;
  final List<ShiftType> initialShiftTypes;
  final WorkSchedule? editingSchedule;
  final DateTime? selectedDate;

  const _AdvancedScheduleForm(
      {required this.onSave,
      required this.initialShiftTypes,
      this.editingSchedule,
      this.selectedDate});
  @override
  State<_AdvancedScheduleForm> createState() => _AdvancedScheduleFormState();
}

class _AdvancedScheduleFormState extends State<_AdvancedScheduleForm> {
  late List<ShiftType> _shiftTypes;
  late DateTime _startDate;
  late DateTime _endDate;
  final _patternController = TextEditingController();
  bool get _isEditing => widget.editingSchedule != null;

  @override
  void initState() {
    super.initState();
    _shiftTypes = widget.initialShiftTypes
        .map((type) => ShiftType.fromMap(type.toMap()))
        .toList();
    if (_isEditing) {
      _startDate = DateTime.parse(widget.editingSchedule!.startDate);
      _endDate = _startDate;
      _patternController.text = widget.editingSchedule!.pattern;
    } else {
      _startDate = widget.selectedDate ?? DateTime.now();
      _endDate = _startDate.add(const Duration(days: 29));
    }
  }

  @override
  void dispose() {
    _patternController.dispose();
    super.dispose();
  }

  double _calculateNightHours(TimeOfDay startTime, TimeOfDay endTime) {
    const nightStartHour = 22;
    const nightEndHour = 6;
    final nightStartMinutes = nightStartHour * 60;
    final nightEndMinutes = (nightEndHour + 24) * 60;
    var shiftStartMinutes = startTime.hour * 60 + startTime.minute;
    var shiftEndMinutes = endTime.hour * 60 + endTime.minute;
    if (shiftEndMinutes < shiftStartMinutes) shiftEndMinutes += 24 * 60;
    final overlapStart = max(shiftStartMinutes, nightStartMinutes);
    final overlapEnd = min(shiftEndMinutes, nightEndMinutes);
    final overlapDurationMinutes = overlapEnd - overlapStart;
    return (overlapDurationMinutes <= 0) ? 0.0 : overlapDurationMinutes / 60.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '근무 수정' : '근무 패턴 추가'), actions: [
        TextButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('저장'),
            onPressed: _saveSchedule,
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).textTheme.bodyLarge?.color)),
        const SizedBox(width: 8),
      ]),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('1. 근무 유형 설정'),
              Text('근무의 종류와 시간, 색상 등을 설정합니다.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              ..._shiftTypes.map((type) => _buildShiftTypeRow(type)).toList(),
              const SizedBox(height: 12),
              Center(
                  child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('근무 유형 추가'),
                      onPressed: _addShiftType,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))))),
              if (_isEditing) ...[
                const Divider(height: 40),
                _buildSectionTitle('2. 선택한 날짜 근무 수정'),
                Text(
                    '${DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(_startDate)}의 근무 약어를 선택하세요.',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _patternController,
                    maxLength: 1,
                    decoration: InputDecoration(
                        labelText: '근무 약어',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)))),
              ],
              if (!_isEditing) ...[
                const Divider(height: 40),
                _buildSectionTitle('2. 근무 기간 및 패턴 입력'),
                Text('설정한 근무 유형을 조합하여 패턴을 만듭니다.',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                ListTile(
                  leading:
                      const Icon(Icons.date_range, color: Colors.deepPurple),
                  title: Text(
                      '${DateFormat('yyyy.MM.dd').format(_startDate)} ~ ${DateFormat('yyyy.MM.dd').format(_endDate)}'),
                  trailing: const Icon(Icons.edit),
                  onTap: _pickDateRange,
                ),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _patternController,
                    decoration: InputDecoration(
                        labelText: '근무 약어 패턴 입력',
                        hintText: '예: 주야비휴',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)))),
              ],
              const SizedBox(height: 12),
              Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _shiftTypes.map((type) {
                    return ActionChip(
                      avatar: CircleAvatar(
                          backgroundColor: type.color,
                          child: Text(
                              type.abbreviation.isEmpty
                                  ? '?'
                                  : type.abbreviation[0],
                              style: const TextStyle(color: Colors.white))),
                      label: Text('${type.name} (${type.abbreviation})'),
                      onPressed: () {
                        if (_isEditing) {
                          _patternController.text = type.abbreviation;
                        } else {
                          _patternController.text =
                              '${_patternController.text}${type.abbreviation}';
                        }
                        _patternController.selection =
                            TextSelection.fromPosition(TextPosition(
                                offset: _patternController.text.length));
                      },
                    );
                  }).toList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 4.0, top: 16.0),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple)));

  Widget _buildShiftTypeRow(ShiftType type) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          children: [
            Row(children: [
              GestureDetector(
                  onTap: () => _pickColor(type),
                  child: CircleAvatar(backgroundColor: type.color, radius: 12)),
              const SizedBox(width: 12),
              Expanded(
                  child: TextFormField(
                      initialValue: type.name,
                      decoration: const InputDecoration(
                          labelText: '근무 이름',
                          isDense: true,
                          border: InputBorder.none),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      onChanged: (val) => type.name = val)),
              const SizedBox(width: 8),
              SizedBox(
                  width: 50,
                  child: TextFormField(
                      initialValue: type.abbreviation,
                      decoration: const InputDecoration(
                          labelText: '약어',
                          isDense: true,
                          border: InputBorder.none),
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                      onChanged: (val) => setState(
                          () => type.abbreviation = val.trim().toUpperCase()))),
              IconButton(
                  icon: const Icon(Icons.delete_forever,
                      color: Colors.redAccent, size: 22),
                  onPressed: () => setState(() => _shiftTypes.remove(type)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              TextButton(
                  child: Text(type.startTime.format(context),
                      style: const TextStyle(fontSize: 14)),
                  onPressed: () async {
                    final picked = await _pickTime(type.startTime);
                    if (picked != null)
                      setState(() {
                        type.startTime = picked;
                        type.nightHours =
                            _calculateNightHours(type.startTime, type.endTime);
                      });
                  }),
              const Text('~', style: TextStyle(fontSize: 14)),
              TextButton(
                  child: Text(type.endTime.format(context),
                      style: const TextStyle(fontSize: 14)),
                  onPressed: () async {
                    final picked = await _pickTime(type.endTime);
                    if (picked != null)
                      setState(() {
                        type.endTime = picked;
                        type.nightHours =
                            _calculateNightHours(type.startTime, type.endTime);
                      });
                  }),
            ]),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(children: [
                  const Icon(Icons.nightlight_round,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text('야간 시간', style: TextStyle(fontSize: 14)),
                  const Spacer(),
                  Text('${type.nightHours.toStringAsFixed(1)} 시간',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                ])),
          ],
        ),
      ),
    );
  }

  void _pickColor(ShiftType type) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('근무 색상 선택'),
              content: SingleChildScrollView(
                  child: ColorPicker(
                      pickerColor: type.color,
                      onColorChanged: (color) =>
                          setState(() => type.color = color))),
              actions: [
                ElevatedButton(
                    child: const Text('선택 완료'),
                    onPressed: () => Navigator.of(context).pop())
              ],
            ));
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        initialDateRange: DateTimeRange(start: _startDate, end: _endDate));
    if (picked != null)
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initialTime) async {
    return await showTimePicker(context: context, initialTime: initialTime);
  }

  void _addShiftType() {
    setState(() => _shiftTypes.add(ShiftType(
        name: '새 근무',
        abbreviation: '',
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0),
        color: Colors.grey)));
  }

  Future<void> _saveSchedule() async {
    for (var type in _shiftTypes) {
      if (type.name.isNotEmpty && type.abbreviation.isNotEmpty) {
        type.nightHours = _calculateNightHours(type.startTime, type.endTime);
        if (type.id != null)
          await DBHelper.updateShiftType(type);
        else
          await DBHelper.insertShiftType(type);
      }
    }
    final savedTypes = await DBHelper.getAllShiftTypes();

    if (_isEditing) {
      final updatedPattern = _patternController.text.toUpperCase();
      if (updatedPattern.isNotEmpty) {
        final schedule = widget.editingSchedule!;
        final type = savedTypes.firstWhere(
            (t) => t.abbreviation == updatedPattern,
            orElse: () => _shiftTypes.first);
        final date = DateTime.parse(schedule.startDate);
        final endDateObj = (type.endTime.hour < type.startTime.hour)
            ? date.add(const Duration(days: 1))
            : date;

        final updatedSchedule = WorkSchedule(
          id: schedule.id,
          startDate: schedule.startDate,
          startTime:
              '${type.startTime.hour.toString().padLeft(2, '0')}:${type.startTime.minute.toString().padLeft(2, '0')}',
          endDate: DateFormat('yyyy-MM-dd').format(endDateObj),
          endTime:
              '${type.endTime.hour.toString().padLeft(2, '0')}:${type.endTime.minute.toString().padLeft(2, '0')}',
          pattern: updatedPattern,
        );
        await DBHelper.updateWorkSchedule(updatedSchedule);
      }
    } else {
      final pattern =
          _patternController.text.toUpperCase().replaceAll(' ', '휴');
      if (pattern.isEmpty) {
        widget.onSave();
        return;
      }

      await NotificationService().cancelAllNotifications();
      final totalDays = _endDate.difference(_startDate).inDays + 1;
      for (int i = 0; i < totalDays; i++) {
        final date = _startDate.add(Duration(days: i));
        final dateString = DateFormat('yyyy-MM-dd').format(date);
        final token = pattern[i % pattern.length];

        await DBHelper.deleteWorkSchedulesForDate(dateString);

        if (token == '휴') continue;

        final type = savedTypes.firstWhere((t) => t.abbreviation == token,
            orElse: () => ShiftType(
                name: '',
                abbreviation: '',
                startTime: TimeOfDay.now(),
                endTime: TimeOfDay.now(),
                color: Colors.grey));
        if (type.abbreviation.isEmpty) continue;

        final startTimeStr =
            '${type.startTime.hour.toString().padLeft(2, '0')}:${type.startTime.minute.toString().padLeft(2, '0')}';
        final endDateObj = (type.endTime.hour < type.startTime.hour)
            ? date.add(const Duration(days: 1))
            : date;
        final endDateStr = DateFormat('yyyy-MM-dd').format(endDateObj);
        final endTimeStr =
            '${type.endTime.hour.toString().padLeft(2, '0')}:${type.endTime.minute.toString().padLeft(2, '0')}';

        await DBHelper.insertWorkSchedule(WorkSchedule(
            startDate: dateString,
            startTime: startTimeStr,
            endDate: endDateStr,
            endTime: endTimeStr,
            pattern: token));
      }
    }
    widget.onSave();
  }
}
