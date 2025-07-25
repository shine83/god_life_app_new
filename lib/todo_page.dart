import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final routines = await DBHelper.getAllRoutines();
    final log = await DBHelper.getRoutineLogForDate(_todayString);
    if (mounted) {
      setState(() {
        _allRoutines = routines;
        _routineLog = log;
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

  // ✅ 요청사항 1. 루틴 추가/수정 다이얼로그
  void _showAddEditRoutineDialog({Routine? routine}) {
    final isEditing = routine != null;
    final _textController =
        TextEditingController(text: isEditing ? routine.name : '');
    String _selectedCategory = isEditing ? routine.category : _categories[0];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          // 다이얼로그 내부 상태(카테고리 선택) 관리를 위해 사용
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
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        // 다이얼로그 내부 UI만 업데이트
                        _selectedCategory = newValue!;
                      });
                    },
                    decoration: const InputDecoration(labelText: '카테고리'),
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

                    if (isEditing) {
                      // 수정 로직
                      final updatedRoutine = Routine(
                        id: routine.id,
                        name: _textController.text,
                        category: _selectedCategory,
                      );
                      await DBHelper.updateRoutine(updatedRoutine);
                    } else {
                      // 추가 로직
                      final newRoutine = Routine(
                        name: _textController.text,
                        category: _selectedCategory,
                      );
                      await DBHelper.insertRoutine(newRoutine);
                    }
                    Navigator.pop(ctx);
                    _loadRoutines(); // 목록 새로고침
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ✅ 요청사항 2. 루틴 삭제 확인 다이얼로그
  void _confirmDelete(Routine routine) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('삭제 확인'),
              content: Text('\'${routine.name}\' 루틴을 정말 삭제하시겠어요?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () async {
                    await DBHelper.deleteRoutine(routine.id!);
                    Navigator.pop(ctx);
                    _loadRoutines(); // 목록 새로고침
                  },
                  child: const Text('삭제', style: TextStyle(color: Colors.red)),
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final groupedRoutines = groupBy(_allRoutines, (Routine r) => r.category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이루틴'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allRoutines.isEmpty
              ? const Center(
                  child: Text('아래 + 버튼을 눌러 첫 루틴을 추가해보세요!'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // FAB에 가려지지 않게
                  itemCount: groupedRoutines.keys.length,
                  itemBuilder: (context, index) {
                    final category = groupedRoutines.keys.toList()[index];
                    final routinesInCategory = groupedRoutines[category]!;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            const Divider(),
                            ...routinesInCategory.map((routine) {
                              final isCompleted =
                                  _routineLog[routine.id] ?? false;
                              return ListTile(
                                // ✅ 체크박스 부분
                                leading: Checkbox(
                                  value: isCompleted,
                                  onChanged: (bool? value) {
                                    if (value != null) {
                                      _toggleRoutine(routine, value);
                                    }
                                  },
                                ),
                                title: Text(routine.name),
                                // ✅ 요청사항 2. 수정/삭제 버튼
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
                                      onPressed: () => _confirmDelete(routine),
                                    ),
                                  ],
                                ),
                                dense: true, // 간격 조절
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      // ✅ 요청사항 1. 루틴 추가를 위한 + 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEditRoutineDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
