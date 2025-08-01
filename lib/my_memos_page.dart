import 'package:flutter/material.dart';
import 'package:god_life_app/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyMemosPage extends StatefulWidget {
  const MyMemosPage({super.key});

  @override
  State<MyMemosPage> createState() => _MyMemosPageState();
}

class _MyMemosPageState extends State<MyMemosPage> {
  final TextEditingController memoController = TextEditingController();
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    memoController.dispose();
    super.dispose();
  }

  Future<void> addMemo(String content) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = {
      'user_id': user.id,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    };

    await supabase.from('memos').insert(data);
  }

  Stream<List<Map<String, dynamic>>> getMyMemosStream() {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return supabase
        .from('memos')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 메모'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getMyMemosStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("작성된 메모가 없습니다."));
          }

          final memoList = snapshot.data!;

          return ListView.builder(
            itemCount: memoList.length,
            itemBuilder: (context, index) {
              final memoData = memoList[index];
              return ListTile(
                title: Text(memoData['content'] ?? '내용 없음'),
                subtitle: Text(memoData['created_at']
                    .toString()
                    .replaceAll('T', ' ')
                    .substring(0, 16)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddMemoDialog(context),
      ),
    );
  }

  void _showAddMemoDialog(BuildContext context) {
    memoController.clear();
    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('새 메모 작성'),
              content: TextField(
                controller: memoController,
                decoration: const InputDecoration(hintText: "내용을 입력하세요"),
                maxLines: 5,
              ),
              actions: [
                TextButton(
                  child: const Text('취소'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: isSaving
                      ? const CircularProgressIndicator()
                      : const Text('저장'),
                  onPressed: () async {
                    final content = memoController.text.trim();
                    if (content.isEmpty) return;

                    setDialogState(() => isSaving = true);
                    await addMemo(content);
                    Navigator.of(context).pop(); // 저장 완료 후 닫기
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
