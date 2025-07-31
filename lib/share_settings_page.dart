import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';

class ShareSettingsPage extends StatefulWidget {
  const ShareSettingsPage({super.key});

  @override
  State<ShareSettingsPage> createState() => _ShareSettingsPageState();
}

class _ShareSettingsPageState extends State<ShareSettingsPage> {
  String? _shareId;
  bool _shareWorkSchedule = false;
  bool _shareMemo = false;
  final TextEditingController _idController = TextEditingController();

  void _generateNewShareId() {
    final uuid = const Uuid().v4().substring(0, 8); // 짧은 ID 생성
    setState(() {
      _shareId = uuid;
      _idController.text = uuid;
    });
  }

  Future<void> _saveToRealtimeDatabase() async {
    if (_shareId == null || _shareId!.isEmpty) return;

    final data = {
      'share_work_schedule': _shareWorkSchedule,
      'share_memo': _shareMemo,
    };

    final ref = FirebaseDatabase.instance.ref('share_settings/$_shareId');
    await ref.set(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공유 설정이 저장되었습니다')),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('공유 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('📌 공유 ID 생성 또는 입력'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      hintText: '공유 ID 입력 또는 생성',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _shareId = value,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _generateNewShareId,
                  child: const Text('ID 생성'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            CheckboxListTile(
              title: const Text('근무일정 공유'),
              value: _shareWorkSchedule,
              onChanged: (value) {
                setState(() => _shareWorkSchedule = value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('메모 공유'),
              value: _shareMemo,
              onChanged: (value) {
                setState(() => _shareMemo = value ?? false);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveToRealtimeDatabase,
              icon: const Icon(Icons.save),
              label: const Text('공유 설정 저장'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
