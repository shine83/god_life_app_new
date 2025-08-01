import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsMemoView extends StatelessWidget {
  final String shareId; // Supabase에서는 공유 ID를 기준으로 메모를 조회

  const FriendsMemoView({super.key, required this.shareId});

  Stream<List<Map<String, dynamic>>> getMemosStream(String shareId) {
    final client = Supabase.instance.client;
    return client
        .from('memos')
        .stream(primaryKey: ['id']) // primaryKey 꼭 명시해야 실시간 반영됨
        .eq('share_id', shareId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${shareId.substring(0, 6)}...님의 메모'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getMemosStream(shareId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final memos = snapshot.data ?? [];
          if (memos.isEmpty) {
            return const Center(child: Text("작성된 메모가 없습니다."));
          }

          // 최신순 정렬
          memos.sort((a, b) => DateTime.parse(b['createdAt'])
              .compareTo(DateTime.parse(a['createdAt'])));

          return ListView.builder(
            itemCount: memos.length,
            itemBuilder: (context, index) {
              final memo = memos[index];
              return ListTile(
                title: Text(memo['content'] ?? '내용 없음'),
                subtitle: Text(DateTime.parse(memo['createdAt'])
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
