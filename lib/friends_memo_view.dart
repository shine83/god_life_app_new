// friends_memo_view.dart 전체 코드
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:god_life_app/firebase_service.dart'; // 서비스 파일 임포트

class FriendsMemoView extends StatelessWidget {
  final String friendUid; // 어떤 친구의 메모를 보여줄지 ID를 받음

  const FriendsMemoView({super.key, required this.friendUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${friendUid.substring(0, 6)}...님의 메모'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: getMemosForUser(friendUid), // friendUid로 메모 스트림 가져오기
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("작성된 메모가 없습니다."));
          }

          final memosMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final memoList = memosMap.entries.toList()
            ..sort((a, b) =>
                b.value['createdAt'].compareTo(a.value['createdAt'])); // 최신순 정렬

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
    );
  }
}
