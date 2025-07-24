import 'dart:async';
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
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  late TabController _tabController;
  String _aiRecommendation = '날짜를 선택하여 AI 추천을 받아보세요!';

  List<Routine> _allRoutines = [];
  Map<int, bool> _routineLog = {};

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
    final allRoutines = await DBHelper.getAllRoutines();

    final tempScheduleMap = <DateTime, List<WorkSchedule>>{};
    for (var s in allSchedules) {
      final d = DateTime.parse(s.startDate);
      final key = DateTime.utc(d.year, d.month, d.day);
      tempScheduleMap.putIfAbsent(key, () => []);
      tempScheduleMap[key]!.add(s);
    }

    if (mounted) {
      setState(() {
        scheduleMap = tempScheduleMap;
        _shiftTypes = allTypes;
        _allRoutines = allRoutines;
      });
      _onDaySelected(_selectedDay, _focusedDay);
    }
  }

  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    final dayKey =
        DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
    final dateString = DateFormat('yyyy-MM-dd').format(dayKey);

    setState(() {
      _selectedDay = dayKey;
      _focusedDay = focusedDay;
      _aiRecommendation = 'AI가 맞춤 조언을 생성 중입니다... 🤔';
    });

    final recommendation = await _fetchAIRecommendation(dayKey);
    final routineLog = await DBHelper.getRoutineLogForDate(dateString);

    if (mounted) {
      setState(() {
        _aiRecommendation = recommendation;
        _routineLog = routineLog;
      });
    }
  }

  Future<String> _fetchAIRecommendation(DateTime forDay) async {
    final currentSchedule = scheduleMap[forDay]?.first;
    final currentPattern = currentSchedule?.pattern ?? '휴일';
    final previousPattern =
        scheduleMap[forDay.subtract(const Duration(days: 1))]?.first.pattern ??
            '휴일';
    final nextPattern =
        scheduleMap[forDay.add(const Duration(days: 1))]?.first.pattern ?? '휴일';
    return await AIService.getRecommendation(
      currentWorkType: _getWorkTypeName(currentPattern),
      previousWorkType: _getWorkTypeName(previousPattern),
      nextWorkType: _getWorkTypeName(nextPattern),
    );
  }

  Future<void> _toggleRoutine(Routine routine, bool isCompleted) async {
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDay);
    await DBHelper.updateRoutineLog(routine.id, dateString, isCompleted);
    final updatedLog = await DBHelper.getRoutineLogForDate(dateString);
    setState(() {
      _routineLog = updatedLog;
    });
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

  void _showAdvancedScheduleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
          child: _AdvancedScheduleForm(
              initialShiftTypes: _shiftTypes,
              onSave: () {
                Navigator.pop(ctx);
                _loadData();
              })),
    );
  }

  void _showEditDialog(WorkSchedule schedule) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('근무 유형 변경'),
                content: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _shiftTypes.map((type) {
                          return ListTile(
                              leading: CircleAvatar(
                                  backgroundColor: type.color, radius: 12),
                              title: Text(type.name),
                              onTap: () async {
                                final updatedSchedule = WorkSchedule(
                                    id: schedule.id,
                                    startDate: schedule.startDate,
                                    startTime:
                                        '${type.startTime.hour}:${type.startTime.minute}',
                                    endDate: schedule.endDate,
                                    endTime:
                                        '${type.endTime.hour}:${type.endTime.minute}',
                                    pattern: type.abbreviation);
                                await DBHelper.updateWorkSchedule(
                                    updatedSchedule);
                                Navigator.pop(ctx);
                                _loadData();
                              });
                        }).toList())),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('취소'))
                ]));
  }

  void _showDeleteConfirmationDialog(WorkSchedule schedule) async {
    final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('삭제 옵션 선택'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  ListTile(
                      leading: const Icon(Icons.looks_one),
                      title: const Text('이 날짜만 삭제'),
                      onTap: () => Navigator.pop(ctx, 'single')),
                  ListTile(
                      leading: const Icon(Icons.delete_sweep),
                      title: const Text('모든 일정 삭제'),
                      onTap: () => Navigator.pop(ctx, 'all'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('취소'))
                ]));
    if (choice == 'single') {
      await DBHelper.deleteWorkSchedule(schedule.id!);
      _loadData();
    } else if (choice == 'all') {
      final confirmAll = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text('정말 모든 일정을 삭제하시겠어요?'),
                  content: const Text('이 작업은 되돌릴 수 없습니다.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('취소')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('전체 삭제'))
                  ]));
      if (confirmAll == true) {
        await DBHelper.clearAllSchedules();
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedRoutines = groupBy(_allRoutines, (Routine r) => r.category);
    final selectedSchedule = scheduleMap[DateTime.utc(
            _selectedDay.year, _selectedDay.month, _selectedDay.day)]
        ?.first;

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
              onPressed: () => _onDaySelected(DateTime.now(), DateTime.now()),
              tooltip: '오늘로 이동'),
          IconButton(
              icon: const Icon(Icons.add_task),
              onPressed: _showAdvancedScheduleDialog,
              tooltip: '근무 추가'),
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
              rowHeight: 60,
              daysOfWeekHeight: 24,
              headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 1.0),
                  leftChevronVisible: false,
                  rightChevronVisible: false),
              calendarStyle: CalendarStyle(
                tableBorder: TableBorder(
                    horizontalInside:
                        BorderSide(color: Colors.grey.shade200, width: 1.0)),
              ),
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
          const Divider(height: 1),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(
                              icon: Icon(Icons.auto_awesome_outlined),
                              text: 'AI 추천'),
                          Tab(icon: Icon(Icons.checklist_rtl), text: '오늘의 루틴'),
                        ],
                      ),
                    ),
                    if (selectedSchedule != null)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.green[700]),
                            onPressed: () => _showEditDialog(selectedSchedule),
                            tooltip: '수정하기',
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: Colors.red[700]),
                            onPressed: () =>
                                _showDeleteConfirmationDialog(selectedSchedule),
                            tooltip: '삭제하기',
                          ),
                        ],
                      ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(_aiRecommendation,
                              style:
                                  const TextStyle(fontSize: 15, height: 1.6))),
                      ListView(
                        children: groupedRoutines.entries.map((entry) {
                          final category = entry.key;
                          final routines = entry.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Text(category,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.deepPurple)),
                              ),
                              ...routines.map((routine) {
                                final isCompleted =
                                    _routineLog[routine.id] ?? false;
                                return CheckboxListTile(
                                  title: Text(routine.name),
                                  value: isCompleted,
                                  onChanged: (bool? value) {
                                    _toggleRoutine(routine, value ?? false);
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                );
                              }).toList(),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day,
      {bool isToday = false, bool isSelected = false, bool isOutside = false}) {
    final dayKey = DateTime.utc(day.year, day.month, day.day);
    final schedule = scheduleMap[dayKey]?.first;
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
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
            Text(
              '${day.day}',
              style: TextStyle(
                color: dayColor,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isFilled)
              Text(
                schedule!.pattern,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              )
          ],
        ),
      ),
    );
  }
}

class _AdvancedScheduleForm extends StatefulWidget {
  final VoidCallback onSave;
  final List<ShiftType> initialShiftTypes;
  const _AdvancedScheduleForm({
    required this.onSave,
    required this.initialShiftTypes,
  });

  @override
  State<_AdvancedScheduleForm> createState() => _AdvancedScheduleFormState();
}

class _AdvancedScheduleFormState extends State<_AdvancedScheduleForm> {
  late List<ShiftType> _shiftTypes;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 29));
  final _patternController = TextEditingController();
  final Map<int, int> _alarmSettings = {};

  @override
  void initState() {
    super.initState();
    _shiftTypes = widget.initialShiftTypes
        .map((type) => ShiftType.fromMap(type.toMap()))
        .toList();
  }

  @override
  void dispose() {
    _patternController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('근무 패턴 및 유형 설정'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('저장'),
            onPressed: _saveSchedule,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('1. 근무 유형 설정'),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              const Divider(height: 40),
              _buildSectionTitle('2. 근무 기간 설정'),
              ListTile(
                leading: const Icon(Icons.date_range, color: Colors.deepPurple),
                title: Text(
                  '${DateFormat('yyyy년 M월 d일').format(_startDate)} ~ ${DateFormat('yyyy년 M월 d일').format(_endDate)}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: _pickDateRange,
              ),
              const Divider(height: 40),
              _buildSectionTitle('3. 근무 패턴 입력'),
              TextFormField(
                controller: _patternController,
                decoration: InputDecoration(
                  labelText: '근무 약어 패턴 입력',
                  hintText: '예: 주야비휴 주야비휴 (띄어쓰기는 휴무)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _patternController.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _shiftTypes.map((type) {
                  return ActionChip(
                    avatar: CircleAvatar(
                      backgroundColor: type.color,
                      child: Text(
                        type.abbreviation.isEmpty ? '?' : type.abbreviation[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    label: Text('${type.name} (${type.abbreviation})'),
                    onPressed: () {
                      final currentText = _patternController.text;
                      _patternController.text =
                          '$currentText${type.abbreviation}';
                      _patternController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _patternController.text.length),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple),
      ),
    );
  }

  Widget _buildShiftTypeRow(ShiftType type) {
    final currentAlarmValue = _alarmSettings[type.id ?? -1] ?? 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _pickColor(type),
                  child: CircleAvatar(backgroundColor: type.color, radius: 14),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: type.name,
                    decoration: const InputDecoration(
                      labelText: '근무 이름',
                      border: UnderlineInputBorder(),
                    ),
                    onChanged: (val) => type.name = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: type.abbreviation,
                    decoration: const InputDecoration(
                      labelText: '약어',
                      border: UnderlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() {
                      type.abbreviation = val.trim().toUpperCase();
                    }),
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.delete_forever, color: Colors.redAccent),
                  onPressed: () => setState(() => _shiftTypes.remove(type)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: Text(type.startTime.format(context)),
                  onPressed: () async {
                    final picked = await _pickTime(type.startTime);
                    if (picked != null) setState(() => type.startTime = picked);
                  },
                ),
                const Text(' ~ '),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: Text(type.endTime.format(context)),
                  onPressed: () async {
                    final picked = await _pickTime(type.endTime);
                    if (picked != null) setState(() => type.endTime = picked);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.alarm, size: 20, color: Colors.deepPurple),
                const SizedBox(width: 12),
                const Text('알람 설정', style: TextStyle(fontSize: 15)),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    textStyle: const TextStyle(fontSize: 15),
                  ),
                  onPressed: () => _showAlarmOffsetPicker(type),
                  child: Text(_formatAlarmOffset(currentAlarmValue)),
                ),
              ],
            ),
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
            onColorChanged: (color) => setState(() => type.color = color),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('선택 완료'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initialTime) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _addShiftType() {
    setState(() {
      _shiftTypes.add(
        ShiftType(
          name: '새 근무',
          abbreviation: '',
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          color: Colors.grey,
        ),
      );
    });
  }

  Future<void> _showAlarmOffsetPicker(ShiftType type) async {
    int currentOffset = _alarmSettings[type.id ?? -1] ?? 0;
    int selectedHour = currentOffset ~/ 60;
    int selectedMinute = currentOffset % 60;

    final newOffset = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('알람 시간 설정'),
          content: SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 70,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    controller:
                        FixedExtentScrollController(initialItem: selectedHour),
                    onSelectedItemChanged: (index) {
                      selectedHour = index;
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 13,
                      builder: (context, index) =>
                          Center(child: Text('$index 시간')),
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    controller: FixedExtentScrollController(
                        initialItem: selectedMinute ~/ 5),
                    onSelectedItemChanged: (index) {
                      selectedMinute = index * 5;
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 12,
                      builder: (context, index) =>
                          Center(child: Text('${index * 5} 분')),
                    ),
                  ),
                ),
                const Text('전'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final totalMinutes = selectedHour * 60 + selectedMinute;
                Navigator.pop(context, totalMinutes);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    if (newOffset != null) {
      setState(() {
        if (type.id != null) {
          _alarmSettings[type.id!] = newOffset;
        } else {
          _alarmSettings[-1] = newOffset;
        }
      });
    }
  }

  String _formatAlarmOffset(int offset) {
    if (offset == 0) return '알람 없음';
    if (offset == 1) return '정시';
    final hours = offset ~/ 60;
    final minutes = offset % 60;
    String result = '';
    if (hours > 0) result += '$hours시간 ';
    if (minutes > 0) result += '$minutes분 ';
    return '${result.trim()} 전';
  }

  Future<void> _saveSchedule() async {
    int tempIdCounter = -1;
    for (var type in _shiftTypes) {
      if (type.name.isNotEmpty && type.abbreviation.isNotEmpty) {
        int newId;
        if (type.id != null) {
          await DBHelper.updateShiftType(type);
          newId = type.id!;
        } else {
          newId = await DBHelper.insertShiftType(type);
        }
        if (_alarmSettings.containsKey(tempIdCounter)) {
          _alarmSettings[newId] = _alarmSettings[tempIdCounter]!;
          _alarmSettings.remove(tempIdCounter);
          tempIdCounter--;
        }
      }
    }

    final savedTypes = await DBHelper.getAllShiftTypes();
    final patternWithSpaces = _patternController.text.toUpperCase();
    final pattern = patternWithSpaces.replaceAll(' ', '휴');
    if (pattern.isEmpty) return;

    await NotificationService().cancelAllNotifications();

    final totalDays = _endDate.difference(_startDate).inDays + 1;
    for (int i = 0; i < totalDays; i++) {
      final date = _startDate.add(Duration(days: i));
      final token = pattern[i % pattern.length];

      final existingSchedules = await DBHelper.getAllWorkSchedules();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final toDelete = existingSchedules.where((s) => s.startDate == dateKey);
      for (var item in toDelete) {
        await DBHelper.deleteWorkSchedule(item.id!);
      }

      if (token == '휴') continue;

      final type = savedTypes.firstWhere(
        (t) => t.abbreviation == token,
        orElse: () => ShiftType(
          name: '',
          abbreviation: '',
          startTime: TimeOfDay.now(),
          endTime: TimeOfDay.now(),
          color: Colors.grey,
        ),
      );
      if (type.abbreviation.isEmpty) continue;

      final startDateStr = DateFormat('yyyy-MM-dd').format(date);
      final startTimeStr =
          '${type.startTime.hour.toString().padLeft(2, '0')}:${type.startTime.minute.toString().padLeft(2, '0')}';

      final endDateObj = (type.endTime.hour < type.startTime.hour)
          ? date.add(const Duration(days: 1))
          : date;
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDateObj);
      final endTimeStr =
          '${type.endTime.hour.toString().padLeft(2, '0')}:${type.endTime.minute.toString().padLeft(2, '0')}';

      await DBHelper.insertWorkSchedule(WorkSchedule(
        startDate: startDateStr,
        startTime: startTimeStr,
        endDate: endDateStr,
        endTime: endTimeStr,
        pattern: token,
      ));

      final alarmOffset = _alarmSettings[type.id] ?? 0;
      if (alarmOffset > 0) {
        final scheduleDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          type.startTime.hour,
          type.startTime.minute,
        );
        final notificationTime = scheduleDateTime.subtract(
          Duration(minutes: alarmOffset == 1 ? 0 : alarmOffset),
        );
        final notificationId = int.parse(
            '${date.month}${date.day}${type.startTime.hour}${type.startTime.minute}');

        if (notificationTime.isAfter(DateTime.now())) {
          await NotificationService().scheduleNotification(
            id: notificationId,
            title: '곧 근무 시간입니다! ⏰',
            body: '${type.name} 근무가 잠시 후 시작됩니다. 💪',
            scheduledDate: notificationTime,
          );
        }
      }
    }
    widget.onSave();
  }
}
