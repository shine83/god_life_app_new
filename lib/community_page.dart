import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 포맷용
import 'post_detail_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String? title;
  String? content;

  // 파이어베이스를 제거했기 때문에, 임시 데이터 리스트를 사용
  final List<Map<String, dynamic>> _posts = [];

  void _showAddPostDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('새 글 작성'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: '제목'),
                  onChanged: (val) => title = val,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: '내용'),
                  maxLines: 4,
                  onChanged: (val) => content = val,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title != null &&
                    title!.isNotEmpty &&
                    content != null &&
                    content!.isNotEmpty) {
                  // ✅ 파이어베이스 제거, 로컬 리스트에 추가
                  setState(() {
                    _posts.insert(0, {
                      'title': title!,
                      'content': content!,
                      'author': '익명',
                      'createdAt': DateTime.now(),
                      'likes': 0,
                      'dislikes': 0,
                    });
                  });
                  if (ctx.mounted) Navigator.of(ctx).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('제목과 내용을 입력하세요!')),
                  );
                }
              },
              child: const Text('등록'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 기존 파이어베이스 StreamBuilder 제거, 단순 리스트뷰로 변경
    return Scaffold(
      appBar: AppBar(title: const Text('커뮤니티'), centerTitle: true),
      body: _posts.isEmpty
          ? const Center(child: Text('아직 등록된 글이 없습니다.'))
          : ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                final title = post['title'] ?? '';
                final content = post['content'] ?? '';
                final author = post['author'] ?? '익명';
                final likes = post['likes'] ?? 0;
                final dislikes = post['dislikes'] ?? 0;
                final date = post['createdAt'] as DateTime;
                final dateText = DateFormat('yyyy.MM.dd').format(date);

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailPage(
                          postId: '', // 파이어베이스 제거로 id는 없음
                          title: title,
                          content: content,
                          author: author,
                          dateText: dateText,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            content,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '✍️ $author · $dateText',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.thumb_up_alt_outlined,
                                    size: 14,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$likes',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.thumb_down_alt_outlined,
                                    size: 14,
                                    color: Colors.red[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$dislikes',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'community_fab',
        onPressed: _showAddPostDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
