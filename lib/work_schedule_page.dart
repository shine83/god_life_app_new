// lib/work_schedule_page.dart 최종 완성본

import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'db_helper.dart';
import 'ai_service.dart';
import 'notification_service.dart';
import 'package:god_life_app/theme/app_colors.dart';
import 'package:god_life_app/design_tokens.dart';

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
    await SharedPreferences.getInstance().then((prefs) => prefs.reload());

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

  Future<void> _fetchHomePageData() async {
    final today = DateTime.now();
    final todayKey = DateTime.utc(today.year, today.month, today.day);
    final currentPattern = scheduleMap[todayKey]?.firstOrNull?.pattern ?? '휴일';
    final healthTip = _getLocalHealthTip(_getWorkTypeName(currentPattern));
    final quote = await AIService.getQuoteOfTheDay();

    if (mounted) {
      setState(() {
        _todayAIHealthTip = healthTip;
        _todayQuote = quote;
      });
    }
  }

  String _getLocalHealthTip(String workType) {
    final Random random = Random();
    final Map<String, List<String>> tips = {
      '주간근무': [
        '점심 식사 후 가벼운 산책으로 활력을 더해보세요.',
        '중간중간 스트레칭으로 몸을 풀어보세요.',
        '퇴근 후 따뜻한 차로 하루를 마무리하세요.',
      ],
      '오후근무': [
        '근무 전 가벼운 식사로 에너지 보충!',
        '늦은 시간 퇴근 후 과식은 피하세요.',
        '오전 시간을 운동으로 활용해보세요.',
      ],
      '야간근무': [
        '근무 전 충분한 수면으로 대비하세요.',
        '물 많이 마시고 카페인은 적게!',
        '퇴근 후 암막커튼으로 숙면 환경을!',
      ],
      '휴일': [
        '푹 쉬면서 재충전해보세요.',
        '공원 산책으로 기분 전환!',
        '취미 활동으로 스트레스 해소!',
      ]
    };
    final tipList = tips[workType] ?? tips['휴일']!;
    return tipList[random.nextInt(tipList.length)];
  }

  // ✅ [최종 수정] async/await를 적용하여 데이터 로딩을 기다립니다.
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    await _loadData();
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

  void _showAdvancedScheduleDialog({WorkSchedule? schedule}) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: _AdvancedScheduleForm(
          initialShiftTypes: _shiftTypes,
          editingSchedule: schedule,
          selectedDate: _selectedDay,
          onSave: () {
            Navigator.pop(ctx);
          },
        ),
      ),
    );
    _loadData();
  }

  void _showInfoPanel(BuildContext context) {
    if (_selectedDay == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (ctx, controller) {
            return _InfoPanel(
              selectedDay: _selectedDay!,
              shiftTypes: _shiftTypes,
              scheduleMap: scheduleMap,
              scrollController: controller,
              tabController: _tabController,
              onEdit: (s) {
                Navigator.pop(ctx);
                _showAdvancedScheduleDialog(schedule: s);
              },
              onDelete: (s) async {
                Navigator.pop(ctx);
                await DBHelper.deleteWorkSchedule(s.id!);
                _loadData();
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('yyyy. M').format(_focusedDay),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: '오늘로 이동',
            onPressed: () {
              final today = DateTime.now();
              _onDaySelected(today, today);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: '근무 추가',
            onPressed: () => _showAdvancedScheduleDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: '전체 일정 삭제',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('⚠️ 전체 일정 삭제'),
                  content:
                      const Text('정말 모든 근무 일정을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('취소')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('삭제',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                await DBHelper.clearAllSchedules();
                _loadData();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TableCalendar(
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
            const SizedBox(height: 20),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("오늘의 건강 팁 💡",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: _fetchHomePageData,
                            tooltip: '새로고침'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_todayAIHealthTip,
                        style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 3),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("오늘의 명언 📖",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_todayQuote,
                        style: const TextStyle(
                            fontSize: 15, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isFilled ? cellColor.withOpacity(0.9) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
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

  const _InfoPanel({
    super.key,
    required this.selectedDay,
    required this.shiftTypes,
    required this.scheduleMap,
    required this.scrollController,
    required this.tabController,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_InfoPanel> createState() => _InfoPanelState();
}

class _InfoPanelState extends State<_InfoPanel> {
  String _detailedRecommendation = '';
  String _workoutRecommendation = '';
  bool _isLoading = true;
  final Map<String, Map<String, String>> _cache = {};

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void didUpdateWidget(covariant _InfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDay != oldWidget.selectedDay) {
      _fetchAll();
    }
  }

  Future<void> _fetchAll() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final bmiResult = prefs.getString('profile_bmiResult');
    final isBmiValid = bmiResult != null && bmiResult.contains('BMI:');

    if (!isBmiValid) {
      if (mounted) {
        setState(() {
          _detailedRecommendation =
              'AI가 맞춤형 건강 팁을 준비 중입니다. 먼저 프로필에서 BMI를 입력해주세요.';
          _workoutRecommendation =
              '프로필에서 BMI를 먼저 계산해주세요!\n나에게 맞는 운동을 추천해 드릴게요. 💪';
          _isLoading = false;
        });
      }
      return;
    }

    final dayKey = DateTime.utc(widget.selectedDay.year,
        widget.selectedDay.month, widget.selectedDay.day);
    final currentPattern =
        widget.scheduleMap[dayKey]?.firstOrNull?.pattern ?? '휴일';
    final previousPattern = widget
            .scheduleMap[dayKey.subtract(const Duration(days: 1))]
            ?.firstOrNull
            ?.pattern ??
        '휴일';
    final nextPattern = widget.scheduleMap[dayKey.add(const Duration(days: 1))]
            ?.firstOrNull?.pattern ??
        '휴일';

    final cacheKey = '$previousPattern-$currentPattern-$nextPattern';
    if (_cache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _detailedRecommendation = _cache[cacheKey]!['detail']!;
          _workoutRecommendation = _cache[cacheKey]!['workout']!;
          _isLoading = false;
        });
      }
      return;
    }

    final detail = await AIService.getDetailedRecommendation(
      currentWorkType: _getName(currentPattern),
      previousWorkType: _getName(previousPattern),
      nextWorkType: _getName(nextPattern),
    );
    final workout = await AIService.getWorkoutRecommendation(
      currentWorkType: _getName(currentPattern),
      previousWorkType: _getName(previousPattern),
    );

    _cache[cacheKey] = {'detail': detail, 'workout': workout};

    if (mounted) {
      setState(() {
        _detailedRecommendation = detail;
        _workoutRecommendation = workout;
        _isLoading = false;
      });
    }
  }

  String _getName(String pattern) {
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

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 200.0,
                height: 24.0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 16)),
            Container(
                width: double.infinity, height: 16.0, color: Colors.white),
            const SizedBox(height: 8.0),
            Container(
                width: double.infinity, height: 16.0, color: Colors.white),
            const SizedBox(height: 8.0),
            Container(width: 150.0, height: 16.0, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '${DateFormat('M월 d일 (E)', 'ko_KR').format(widget.selectedDay)} - ${_getName(widget.scheduleMap[DateTime.utc(widget.selectedDay.year, widget.selectedDay.month, widget.selectedDay.day)]?.firstOrNull?.pattern ?? '휴일')}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            TabBar(
              controller: widget.tabController,
              tabs: const [
                Tab(text: 'AI 추천팁'),
                Tab(text: '오늘의 운동'),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? _buildSkeletonLoader()
                  : TabBarView(
                      controller: widget.tabController,
                      children: [
                        SingleChildScrollView(
                          controller: widget.scrollController,
                          padding: const EdgeInsets.all(16),
                          child: Text(_detailedRecommendation),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Text(_workoutRecommendation),
                        ),
                      ],
                    ),
            ),
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
  const _AdvancedScheduleForm({
    super.key,
    required this.onSave,
    required this.initialShiftTypes,
    this.editingSchedule,
    this.selectedDate,
  });
  @override
  State<_AdvancedScheduleForm> createState() => _AdvancedScheduleFormState();
}

class _AdvancedScheduleFormState extends State<_AdvancedScheduleForm> {
  late List<ShiftType> _shiftTypes;
  late DateTime _startDate;
  late DateTime _endDate;
  final TextEditingController _patternController = TextEditingController();

  bool get _isEditing => widget.editingSchedule != null;

  @override
  void initState() {
    super.initState();
    _shiftTypes = widget.initialShiftTypes
        .map((t) => ShiftType.fromMap(t.toMap()))
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

  double _calculateNightHours(TimeOfDay start, TimeOfDay end) {
    const nightStartHour = 22;
    const nightEndHour = 6;
    const nightStart = nightStartHour * 60;
    const nightEnd = (nightEndHour + 24) * 60;
    int startMin = start.hour * 60 + start.minute;
    int endMin = end.hour * 60 + end.minute;
    if (endMin < startMin) endMin += 24 * 60;
    final overlapStart = max(startMin, nightStart);
    final overlapEnd = min(endMin, nightEnd);
    final overlap = overlapEnd - overlapStart;
    return overlap <= 0 ? 0 : overlap / 60.0;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
    return await showTimePicker(context: context, initialTime: initial);
  }

  void _pickColor(ShiftType type) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('근무 색상 선택'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: type.color,
              onColorChanged: (c) {
                setState(() {
                  type.color = c;
                });
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('확인'))
          ],
        );
      },
    );
  }

  void _addShiftType() {
    setState(() {
      _shiftTypes.add(ShiftType(
        name: '새 근무',
        abbreviation: '',
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0),
        color: Colors.grey,
      ));
    });
  }

  Future<void> _saveSchedule() async {
    for (var type in _shiftTypes) {
      if (type.name.isNotEmpty && type.abbreviation.isNotEmpty) {
        type.nightHours = _calculateNightHours(type.startTime, type.endTime);
        if (type.id != null) {
          await DBHelper.updateShiftType(type);
        } else {
          await DBHelper.insertShiftType(type);
        }
      }
    }
    final savedTypes = await DBHelper.getAllShiftTypes();
    if (_isEditing) {
      final pattern = _patternController.text.trim().toUpperCase();
      if (pattern.isNotEmpty) {
        final targetType = savedTypes.firstWhere(
            (t) => t.abbreviation == pattern,
            orElse: () => _shiftTypes.first);
        final original = widget.editingSchedule!;
        final startDateObj = DateTime.parse(original.startDate);
        final endDateObj = (targetType.endTime.hour < targetType.startTime.hour)
            ? startDateObj.add(const Duration(days: 1))
            : startDateObj;
        final updated = WorkSchedule(
          id: original.id,
          startDate: original.startDate,
          startTime:
              '${targetType.startTime.hour.toString().padLeft(2, '0')}:${targetType.startTime.minute.toString().padLeft(2, '0')}',
          endDate: DateFormat('yyyy-MM-dd').format(endDateObj),
          endTime:
              '${targetType.endTime.hour.toString().padLeft(2, '0')}:${targetType.endTime.minute.toString().padLeft(2, '0')}',
          pattern: pattern,
        );
        await DBHelper.updateWorkSchedule(updated);
      }
    } else {
      final pattern =
          _patternController.text.toUpperCase().replaceAll(' ', '휴');
      if (pattern.isNotEmpty) {
        await NotificationService().cancelAllNotifications();
        final totalDays = _endDate.difference(_startDate).inDays + 1;
        for (int i = 0; i < totalDays; i++) {
          final date = _startDate.add(Duration(days: i));
          final token = pattern[i % pattern.length];
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          await DBHelper.deleteWorkSchedulesForDate(dateStr);
          if (token == '휴') continue;
          final type = savedTypes.firstWhere((t) => t.abbreviation == token,
              orElse: () => ShiftType(
                  name: '',
                  abbreviation: '',
                  startTime: TimeOfDay.now(),
                  endTime: TimeOfDay.now(),
                  color: Colors.grey));
          if (type.abbreviation.isEmpty) continue;
          final endDateObj = (type.endTime.hour < type.startTime.hour)
              ? date.add(const Duration(days: 1))
              : date;
          final schedule = WorkSchedule(
            startDate: dateStr,
            startTime:
                '${type.startTime.hour.toString().padLeft(2, '0')}:${type.startTime.minute.toString().padLeft(2, '0')}',
            endDate: DateFormat('yyyy-MM-dd').format(endDateObj),
            endTime:
                '${type.endTime.hour.toString().padLeft(2, '0')}:${type.endTime.minute.toString().padLeft(2, '0')}',
            pattern: token,
          );
          await DBHelper.insertWorkSchedule(schedule);
        }
      }
    }
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '근무 수정' : '근무 유형 설정'),
        actions: [
          TextButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('저장'),
              onPressed: _saveSchedule),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('1. 근무 유형 설정'),
              const SizedBox(height: 8),
              ..._shiftTypes.map((t) => _buildShiftTypeRow(t)),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('근무 유형 추가',
                        style: TextStyle(color: Colors.white)),
                    onPressed: _addShiftType,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: DesignTokens.borderRadiusDefault),
                      padding: const EdgeInsets.symmetric(
                          vertical: DesignTokens.spacingSmall),
                    ),
                  ),
                ),
              ),
              const Divider(height: 32),
              if (_isEditing) _buildEditSection() else _buildPatternSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('2. 선택한 날짜 근무 수정'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _patternController,
          maxLength: 1,
          decoration: InputDecoration(
            labelText: '근무 약어',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _shiftTypes.map((t) {
            return ActionChip(
              avatar: CircleAvatar(backgroundColor: t.color),
              label: Text('${t.name} (${t.abbreviation})'),
              onPressed: () {
                _patternController.text = t.abbreviation;
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPatternSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('2. 근무 기간 및 패턴 입력'),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.date_range),
          title: Text(
              '${DateFormat('yyyy.MM.dd').format(_startDate)} ~ ${DateFormat('yyyy.MM.dd').format(_endDate)}'),
          trailing: const Icon(Icons.edit),
          onTap: _pickDateRange,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _patternController,
          decoration: InputDecoration(
            labelText: '근무 약어 패턴 입력 (예: 주야비휴)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _shiftTypes.map((t) {
            return ActionChip(
              avatar: CircleAvatar(backgroundColor: t.color),
              label: Text('${t.name} (${t.abbreviation})'),
              onPressed: () {
                _patternController.text =
                    '${_patternController.text}${t.abbreviation}';
                _patternController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _patternController.text.length));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildShiftTypeRow(ShiftType type) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _pickColor(type),
                  child: CircleAvatar(backgroundColor: type.color, radius: 12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: type.name,
                    decoration: const InputDecoration(
                        labelText: '근무 이름', border: InputBorder.none),
                    onChanged: (val) => type.name = val,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: type.abbreviation,
                    decoration: const InputDecoration(
                        labelText: '약어', border: InputBorder.none),
                    onChanged: (val) {
                      setState(() {
                        type.abbreviation = val.trim().toUpperCase();
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _shiftTypes.remove(type);
                    });
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  child: Text(type.startTime.format(context)),
                  onPressed: () async {
                    final picked = await _pickTime(type.startTime);
                    if (picked != null) {
                      setState(() {
                        type.startTime = picked;
                        type.nightHours =
                            _calculateNightHours(type.startTime, type.endTime);
                      });
                    }
                  },
                ),
                const Text('~'),
                TextButton(
                  child: Text(type.endTime.format(context)),
                  onPressed: () async {
                    final picked = await _pickTime(type.endTime);
                    if (picked != null) {
                      setState(() {
                        type.endTime = picked;
                        type.nightHours =
                            _calculateNightHours(type.startTime, type.endTime);
                      });
                    }
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.nightlight_round, size: 16),
                const SizedBox(width: 4),
                const Text('야간 시간'),
                const Spacer(),
                Text('${type.nightHours.toStringAsFixed(1)} 시간'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
    );
  }
}
