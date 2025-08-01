import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:god_life_app/firebase_service.dart';

class MyMemosPage extends StatelessWidget {
  const MyMemosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));
    }

    final DatabaseReference memosRef =
        FirebaseDatabase.instance.ref('users/${user.uid}/memos');

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 메모'),
      ),
      body: StreamBuilder(
        stream: memosRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("작성된 메모가 없습니다."));
          }

          final memosMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          // 최신순으로 정렬
          final memoList = memosMap.entries.toList()
            ..sort(
                (a, b) => b.value['createdAt'].compareTo(a.value['createdAt']));

          return ListView.builder(
            itemCount: memoList.length,
            itemBuilder: (context, index) {
              final memoData = memoList[index].value as Map<dynamic, dynamic>;
              return ListTile(
                title: Text(memoData['content'] ?? '내용 없음'),
                subtitle: Text(DateTime.parse(memoData['createdAt'])
                    .toString()
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
    final TextEditingController memoController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
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
              child: const Text('저장'),
              onPressed: () {
                if (memoController.text.isNotEmpty) {
                  addMemoToMyNotes(content: memoController.text.trim());
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
