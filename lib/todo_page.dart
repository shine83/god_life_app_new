import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'design_tokens.dart';
import 'theme/app_colors.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<Routine> _allRoutines = [];
  Map<int, bool> _routineLog = {};
  bool _isLoading = true;
  final String _todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final List<String> _categories = ['건강 챙기기', '마음 챙기기', '숙면 돕기'];

  List<ShiftType> _shiftTypes = [];
  List<Routine> _displayedRoutines = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final allRoutines = await DBHelper.getAllRoutines();
    final log = await DBHelper.getRoutineLogForDate(_todayString);
    final shiftTypes = await DBHelper.getAllShiftTypes();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowSchedule = await DBHelper.getScheduleForDate(tomorrow);

    int? tomorrowShiftTypeId;
    if (tomorrowSchedule != null) {
      final foundType = shiftTypes.firstWhere(
        (type) => type.abbreviation == tomorrowSchedule.pattern,
        orElse: () => ShiftType(
            id: -1,
            name: '알수없음',
            abbreviation: '?',
            startTime: TimeOfDay.now(),
            endTime: TimeOfDay.now(),
            color: Colors.grey),
      );
      tomorrowShiftTypeId = foundType.id;
    }

    final displayedRoutines = allRoutines.where((routine) {
      return routine.linkedShiftTypeId == null ||
          routine.linkedShiftTypeId == tomorrowShiftTypeId;
    }).toList();

    if (mounted) {
      setState(() {
        _allRoutines = allRoutines;
        _routineLog = log;
        _shiftTypes = shiftTypes;
        _displayedRoutines = displayedRoutines;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRoutine(Routine routine, bool isCompleted) async {
    setState(() {
      _routineLog[routine.id!] = isCompleted;
    });
    await DBHelper.updateRoutineLog(routine.id!, _todayString, isCompleted);
  }

  void _showAddEditRoutineDialog({Routine? routine}) {
    final isEditing = routine != null;
    final _textController =
        TextEditingController(text: isEditing ? routine.name : '');
    String _selectedCategory = isEditing ? routine.category : _categories[0];
    int? _selectedShiftTypeId = isEditing ? routine.linkedShiftTypeId : null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? '루틴 수정' : '새 루틴 추가'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _textController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: '루틴 내용'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                          value: category, child: Text(category));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    decoration: const InputDecoration(labelText: '카테고리'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    value: _selectedShiftTypeId,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('모든 근무'),
                      ),
                      ..._shiftTypes.map((ShiftType type) {
                        return DropdownMenuItem<int?>(
                          value: type.id,
                          child: Text(type.name),
                        );
                      }).toList(),
                    ],
                    onChanged: (int? newValue) {
                      setDialogState(() {
                        _selectedShiftTypeId = newValue;
                      });
                    },
                    decoration:
                        const InputDecoration(labelText: '적용할 근무 (내일 기준)'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_textController.text.isEmpty) return;

                    final newOrUpdatedRoutine = Routine(
                      id: isEditing ? routine.id : null,
                      name: _textController.text,
                      category: _selectedCategory,
                      linkedShiftTypeId: _selectedShiftTypeId,
                    );

                    if (isEditing) {
                      await DBHelper.updateRoutine(newOrUpdatedRoutine);
                    } else {
                      await DBHelper.insertRoutine(newOrUpdatedRoutine);
                    }
                    Navigator.pop(ctx);
                    _loadData(); // 목록 새로고침
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: DesignTokens.borderRadiusDefault,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.spacingSmall,
                    ),
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Routine routine) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('삭제 확인'),
              content: Text('\'${routine.name}\' 루틴을 정말 삭제하시겠어요?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('취소')),
                TextButton(
                  onPressed: () async {
                    await DBHelper.deleteRoutine(routine.id!);
                    Navigator.pop(ctx);
                    _loadData();
                  },
                  child: const Text('삭제', style: TextStyle(color: Colors.red)),
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final groupedRoutines =
        groupBy(_displayedRoutines, (Routine r) => r.category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이루틴 (내일 근무 기준)'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _allRoutines.isEmpty
                ? const Center(child: Text('아래 + 버튼을 눌러 첫 루틴을 추가해보세요!'))
                : _displayedRoutines.isEmpty
                    ? const Center(child: Text('내일 근무에 해당하는 루틴이 없습니다.'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: groupedRoutines.keys.length,
                        itemBuilder: (context, index) {
                          final category = groupedRoutines.keys.toList()[index];
                          final routinesInCategory = groupedRoutines[category]!;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            elevation: 2,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 12, 16, 4),
                                    child: Text(category,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.deepPurple)),
                                  ),
                                  const Divider(),
                                  ...routinesInCategory.map((routine) {
                                    final isCompleted =
                                        _routineLog[routine.id] ?? false;
                                    final linkedShift =
                                        routine.linkedShiftTypeId != null
                                            ? _shiftTypes.firstWhere(
                                                (t) =>
                                                    t.id ==
                                                    routine.linkedShiftTypeId,
                                                orElse: () => ShiftType(
                                                    name: '알수없음',
                                                    abbreviation: '?',
                                                    startTime: TimeOfDay.now(),
                                                    endTime: TimeOfDay.now(),
                                                    color: Colors.grey))
                                            : null;

                                    return ListTile(
                                      leading: Checkbox(
                                        value: isCompleted,
                                        onChanged: (bool? value) {
                                          if (value != null)
                                            _toggleRoutine(routine, value);
                                        },
                                      ),
                                      title: Text(routine.name),
                                      subtitle: linkedShift != null
                                          ? Align(
                                              alignment: Alignment.centerLeft,
                                              child: Chip(
                                                label: Text(linkedShift.name,
                                                    style: TextStyle(
                                                        fontSize: 10)),
                                                backgroundColor: linkedShift
                                                    .color
                                                    .withOpacity(0.2),
                                                padding: EdgeInsets.zero,
                                                labelPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6.0),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            )
                                          : null,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                size: 20, color: Colors.grey),
                                            onPressed: () =>
                                                _showAddEditRoutineDialog(
                                                    routine: routine),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                size: 20, color: Colors.grey),
                                            onPressed: () =>
                                                _confirmDelete(routine),
                                          ),
                                        ],
                                      ),
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEditRoutineDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
