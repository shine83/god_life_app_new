// lib/home_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'work_schedule_page.dart';
import 'community_page.dart';
import 'settings_page.dart';
import 'todo_page.dart';
import 'db_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeTabContent(),
    const WorkSchedulePage(),
    const TodoPage(),
    const CommunityPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: '캘린더'),
          BottomNavigationBarItem(
              icon: Icon(Icons.checklist_outlined),
              activeIcon: Icon(Icons.checklist),
              label: '할 일'),
          BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum),
              label: '커뮤니티'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: '설정'),
        ],
      ),
    );
  }
}

class _HomeTabContent extends StatefulWidget {
  const _HomeTabContent();

  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
  String _homeCardText = '정보를 불러오는 중...';

  @override
  void initState() {
    super.initState();
    _updateHomeCardText();
  }

  Future<void> _updateHomeCardText() async {
    try {
      final now = DateTime.now();
      final allSchedules = await DBHelper.getAllWorkSchedules();
      allSchedules.sort((a, b) {
        final aDateTime = DateTime.parse('${a.startDate} ${a.startTime}');
        final bDateTime = DateTime.parse('${b.startDate} ${b.startTime}');
        return aDateTime.compareTo(bDateTime);
      });

      WorkSchedule? nextSchedule;
      for (var schedule in allSchedules) {
        final scheduleDateTime =
            DateTime.parse('${schedule.startDate} ${schedule.startTime}');
        if (scheduleDateTime.isAfter(now)) {
          nextSchedule = schedule;
          break;
        }
      }

      String nextShiftText;
      if (nextSchedule != null) {
        nextShiftText =
            '🗓️ 다음 근무: ${nextSchedule.startDate} (${nextSchedule.pattern})';
      } else {
        nextShiftText = '🗓️ 다음 근무 일정이 없습니다.';
      }

      final prefs = await SharedPreferences.getInstance();
      final bmiStatus = prefs.getString('profile_bmiStatus');
      String healthText;
      if (bmiStatus != null && bmiStatus.isNotEmpty) {
        healthText = '💪 나의 건강 상태: $bmiStatus';
      } else {
        healthText = '💪 프로필에서 BMI를 계산해보세요!';
      }

      if (mounted) {
        setState(() {
          _homeCardText = '$nextShiftText\n$healthText';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _homeCardText = '정보를 불러오는 중 오류가 발생했습니다.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Text('교대근무자 갓생살기',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('교대근무자들의 건강관리 도우미 앱', style: TextStyle(fontSize: 20)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Image.asset(
                'assets/images/home_illustration.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.deepPurple, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_homeCardText,
                          style: const TextStyle(fontSize: 15, height: 1.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
