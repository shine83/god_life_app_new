import 'dart:async';
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

class _WorkSchedulePageState extends State<WorkSchedulePage> {
  Map<DateTime, List<WorkSchedule>> scheduleMap = {};
  List<ShiftType> _shiftTypes = [];
  String _aiRecommendation = '달력을 터치하여 AI 추천을 받아보세요!';
  bool _isLoading = false;
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final schedules = await DBHelper.getAllWorkSchedules();
    final types = await DBHelper.getAllShiftTypes();
    final tempMap = <DateTime, List<WorkSchedule>>{};
    for (var s in schedules) {
      final d = DateTime.parse(s.startDate);
      final key = DateTime(d.year, d.month, d.day);
      tempMap.putIfAbsent(key, () => []);
      tempMap[key]!.add(s);
    }
    if (mounted) {
      setState(() {
        scheduleMap = tempMap;
        _shiftTypes = types;
      });
      _onDaySelected(DateTime.now(), DateTime.now());
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final dayOnly =
          DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
      setState(() {
        _selectedDay = dayOnly;
        _focusedDay = focusedDay;
      });
      _fetchAIRecommendation();
    });
  }

  Future<void> _fetchAIRecommendation() async {
    if (_selectedDay == null) return;
    setState(() {
      _isLoading = true;
      _aiRecommendation = 'AI가 맞춤 조언을 생성 중입니다... 🤔';
    });
    final currentDate = _selectedDay!;
    final previousDate = currentDate.subtract(const Duration(days: 1));
    final nextDate = currentDate.add(const Duration(days: 1));
    final currentPattern = scheduleMap[currentDate]?.first.pattern ?? '휴일';
    final previousPattern = scheduleMap[previousDate]?.first.pattern ?? '휴일';
    final nextPattern = scheduleMap[nextDate]?.first.pattern ?? '휴일';
    final recommendation = await AIService.getRecommendation(
      currentWorkType: _getWorkTypeName(currentPattern),
      previousWorkType: _getWorkTypeName(previousPattern),
      nextWorkType: _getWorkTypeName(nextPattern),
    );
    if (mounted) {
      setState(() {
        _aiRecommendation = recommendation;
        _isLoading = false;
      });
    }
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
    if (pattern == null) return Colors.grey.shade400;
    final type = _shiftTypes.firstWhere((t) => t.abbreviation == pattern,
        orElse: () => ShiftType(
            name: '',
            abbreviation: '',
            startTime: TimeOfDay.now(),
            endTime: TimeOfDay.now(),
            color: Colors.grey));
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
          },
        ),
      ),
    );
  }

  void _showEditDialog(WorkSchedule existingSchedule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('근무 유형 변경'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _shiftTypes.map((type) {
              return ListTile(
                leading: CircleAvatar(backgroundColor: type.color, radius: 12),
                title: Text(type.name),
                onTap: () async {
                  final updatedSchedule = WorkSchedule(
                    id: existingSchedule.id,
                    startDate: existingSchedule.startDate,
                    startTime:
                        '${type.startTime.hour}:${type.startTime.minute}',
                    endDate: existingSchedule.endDate,
                    endTime: '${type.endTime.hour}:${type.endTime.minute}',
                    pattern: type.abbreviation,
                  );
                  await DBHelper.updateWorkSchedule(updatedSchedule);
                  Navigator.pop(ctx);
                  _loadData();
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedSchedule =
        _selectedDay != null ? scheduleMap[_selectedDay!]?.first : null;
    final selectedWorkTypeName = selectedSchedule != null
        ? _getWorkTypeName(selectedSchedule.pattern)
        : '휴일';

    return Scaffold(
      appBar: AppBar(title: const Text('AI 근무 캘린더'), centerTitle: true),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders(
              todayBuilder: (context, day, focusedDay) => _buildToday(day),
              selectedBuilder: (context, day, focusedDay) =>
                  _buildSelected(day),
              defaultBuilder: (context, day, focusedDay) => _buildDefault(day),
              markerBuilder: (context, day, events) {
                final key = DateTime(day.year, day.month, day.day);
                final scheduleList = scheduleMap[key];
                if (scheduleList != null && scheduleList.isNotEmpty) {
                  return Positioned(
                    bottom: 4,
                    child: Container(
                      height: 7,
                      width: 7,
                      decoration: BoxDecoration(
                        color: _getColorForPattern(scheduleList.first.pattern),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(selectedWorkTypeName, selectedSchedule),
                  const SizedBox(height: 12),
                  const Text("🤖 AI 추천",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      child: _isLoading
                          ? const Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('AI가 맞춤 조언을 생성 중입니다... 🤔',
                                    textAlign: TextAlign.center),
                              ],
                            )
                          : Text(
                              _aiRecommendation,
                              style: const TextStyle(fontSize: 16, height: 1.6),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'work_schedule_fab',
        onPressed: _showAdvancedScheduleDialog,
        child: const Icon(Icons.add_task),
      ),
    );
  }

  Widget _buildToday(DateTime day) => Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          width: 36,
          height: 36,
          child: Center(
            child: Text('${day.day}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      );

  Widget _buildSelected(DateTime day) => Center(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.deepPurple,
            shape: BoxShape.circle,
          ),
          width: 36,
          height: 36,
          child: Center(
            child:
                Text('${day.day}', style: const TextStyle(color: Colors.white)),
          ),
        ),
      );

  Widget _buildDefault(DateTime day) => Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
              color: day.weekday == DateTime.sunday ? Colors.red : null),
        ),
      );

  Widget _buildHeader(
      String selectedWorkTypeName, WorkSchedule? selectedSchedule) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _selectedDay != null
                    ? '${DateFormat('M월 d일 (E)', 'ko_KR').format(_selectedDay!)} '
                    : '날짜를 선택하세요',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                selectedWorkTypeName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getColorForPattern(selectedSchedule?.pattern),
                ),
              ),
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
                icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                onPressed: () async {
                  final choice = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('삭제 옵션 선택'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.looks_one),
                            title: const Text('이 날짜만 삭제'),
                            onTap: () => Navigator.pop(ctx, 'single'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_sweep),
                            title: const Text('모든 일정 삭제'),
                            onTap: () => Navigator.pop(ctx, 'all'),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('취소'),
                        ),
                      ],
                    ),
                  );

                  if (choice == 'single') {
                    await DBHelper.deleteWorkSchedule(selectedSchedule.id!);
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
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('전체 삭제'),
                          ),
                        ],
                      ),
                    );
                    if (confirmAll == true) {
                      await DBHelper.clearAllSchedules();
                      _loadData();
                    }
                  }
                },
                tooltip: '삭제하기',
              ),
            ],
          ),
      ],
    );
  }
}

// 아래에 AdvancedScheduleForm 전체를 이어서 붙인다
// (길이 문제로 따로 파일로 관리해도 되지만, 여기서는 하나에 포함)
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildShiftTypeRow(ShiftType type) {
    final currentAlarmValue = _alarmSettings[type.id ?? -1] ?? 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _pickColor(type),
                  child: CircleAvatar(backgroundColor: type.color, radius: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: type.name,
                    decoration: const InputDecoration(labelText: '근무 이름'),
                    onChanged: (val) => type.name = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: type.abbreviation,
                    decoration: const InputDecoration(labelText: '약어'),
                    onChanged: (val) => setState(() {
                      type.abbreviation = val.trim().toUpperCase();
                    }),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.grey),
                  onPressed: () => setState(() => _shiftTypes.remove(type)),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: Text(type.startTime.format(context)),
                  onPressed: () async {
                    final picked = await _pickTime(type.startTime);
                    if (picked != null) setState(() => type.startTime = picked);
                  },
                ),
                const Text('~'),
                TextButton(
                  child: Text(type.endTime.format(context)),
                  onPressed: () async {
                    final picked = await _pickTime(type.endTime);
                    if (picked != null) setState(() => type.endTime = picked);
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.alarm, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('알람 설정'),
                const Spacer(),
                TextButton(
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
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initialTime) async {
    return await showTimePicker(context: context, initialTime: initialTime);
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
    return result + '전';
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
        final notificationId =
            int.parse('${date.month}${date.day}${type.startTime.hour}');
        await NotificationService().scheduleNotification(
          id: notificationId,
          title: '곧 근무 시간입니다! ⏰',
          body: '${type.name} 근무가 잠시 후 시작됩니다. 💪',
          scheduledDate: notificationTime,
        );
      }
    }

    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나만의 근무 만들기'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('1. 적용 기간 설정'),
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(
                '${DateFormat('M/d').format(_startDate)} - ${DateFormat('M/d').format(_endDate)}',
              ),
              onPressed: _pickDateRange,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('2. 근무 유형 만들기'),
            ..._shiftTypes.map((type) => _buildShiftTypeRow(type)).toList(),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('근무 유형 추가'),
              onPressed: _addShiftType,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('3. 근무 패턴 입력'),
            TextField(
              controller: _patternController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: '예: D D N N (공백=휴일)',
                helperText:
                    '등록된 약어: ${_shiftTypes.map((t) => t.abbreviation).where((a) => a.isNotEmpty).join(', ')}',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('스케줄 자동 등록'),
              onPressed: _saveSchedule,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
