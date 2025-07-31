import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'health_connect_page.dart'; // ✅ 1. 주석을 해제해서 파일을 불러옵니다.
import 'work_stats_page.dart';
import 'share_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ThemeMode _selectedThemeMode = ThemeMode.system;

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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('건강앱 연동'),
            subtitle: const Text('헬스케어 및 외부 앱과 연동'),
            trailing: const Icon(Icons.chevron_right),
            // ✅ 2. 비활성화된 기능을 페이지 이동 코드로 교체합니다.
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
