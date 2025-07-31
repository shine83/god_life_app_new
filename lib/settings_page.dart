import 'package:flutter/material.dart';
import 'package:god_life_app/firebase_service.dart';
import 'profile_page.dart';
import 'health_connect_page.dart';
import 'work_stats_page.dart';
import 'share_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ThemeMode _selectedThemeMode = ThemeMode.system;

  void _showAddFriendDialog(BuildContext context) {
    final TextEditingController idController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('친구 추가'),
          content: TextField(
            controller: idController,
            decoration: const InputDecoration(hintText: "친구의 공유 ID를 입력하세요"),
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('추가'),
              onPressed: () {
                final friendId = idController.text.trim();
                if (friendId.isNotEmpty) {
                  createAccessPermission(friendId);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showThemeModeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings_suggest),
                title: const Text('시스템 설정에 따름'),
                onTap: () {
                  setState(() => _selectedThemeMode = ThemeMode.system);
                  Navigator.pop(ctx);
                },
                selected: _selectedThemeMode == ThemeMode.system,
              ),
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text('라이트 모드'),
                onTap: () {
                  setState(() => _selectedThemeMode = ThemeMode.light);
                  Navigator.pop(ctx);
                },
                selected: _selectedThemeMode == ThemeMode.light,
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('다크 모드'),
                onTap: () {
                  setState(() => _selectedThemeMode = ThemeMode.dark);
                  Navigator.pop(ctx);
                },
                selected: _selectedThemeMode == ThemeMode.dark,
              ),
            ],
          ),
        );
      },
    );
  }

  String _getThemeModeLabel() {
    switch (_selectedThemeMode) {
      case ThemeMode.system:
        return '시스템 설정에 따름';
      case ThemeMode.light:
        return '라이트 모드';
      case ThemeMode.dark:
        return '다크 모드';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정'), centerTitle: true),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('프로필'),
            subtitle: const Text('내 정보 및 계정 관리'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add_alt_1_outlined),
            title: const Text('공유 ID로 친구 추가'),
            subtitle: const Text('친구의 ID를 입력하여 캘린더를 공유받으세요'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAddFriendDialog(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('건강앱 연동'),
            subtitle: const Text('헬스케어 및 외부 앱과 연동'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HealthConnectPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('알림 설정'),
            subtitle: const Text('푸시 알림, 소리, 진동'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 기능 비활성화
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('테마 모드'),
            subtitle: Text(_getThemeModeLabel()),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showThemeModeSelector,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('근무 통계'),
            subtitle: const Text('내 근무 패턴과 통계 보기'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkStatsPage()),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
