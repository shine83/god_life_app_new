import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

// Realtime Database와 null 안전(null-safe) 코드로 수정한 함수
Stream<DatabaseEvent> getMyFollowingList() {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    return const Stream.empty();
  }

  final String myUid = currentUser.uid;
  return FirebaseDatabase.instance
      .ref('permissions')
      .orderByChild('accessorUid')
      .equalTo(myUid)
      .onValue;
}

class FriendsCalendarView extends StatefulWidget {
  const FriendsCalendarView({super.key});

  @override
  State<FriendsCalendarView> createState() => _FriendsCalendarViewState();
}

class _FriendsCalendarViewState extends State<FriendsCalendarView> {
  String? _selectedFriendUid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("공유 캘린더"),
      ),
      body: Column(
        children: [
          // 친구 선택 드롭다운 메뉴
          StreamBuilder<DatabaseEvent>(
            stream: getMyFollowingList(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("공유받은 캘린더가 없습니다."),
                );
              }

              final permissionsMap =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              final friendList = permissionsMap.entries
                  .where((entry) => entry.value['canViewCalendar'] == true)
                  .toList();

              if (friendList.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("캘린더를 공유받은 친구가 없습니다."),
                );
              }

              return DropdownButton<String>(
                hint: const Text("  캘린더를 볼 친구를 선택하세요"),
                value: _selectedFriendUid,
                isExpanded: true,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFriendUid = newValue;
                  });
                },
                items: friendList.map((entry) {
                  final String ownerUid = entry.value['ownerUid'];
                  return DropdownMenuItem<String>(
                    value: ownerUid,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("친구 ID: ${ownerUid.substring(0, 6)}..."),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // vvvv 이 부분이 수정되었습니다 vvvv
          Expanded(
            child: _selectedFriendUid == null
                // 친구 선택 전에는 빈 캘린더를 표시
                ? SfCalendar(view: CalendarView.month)
                // 친구 선택 후에는 해당 친구의 일정을 불러오는 캘린더를 표시
                : StreamBuilder<DatabaseEvent>(
                    stream: FirebaseDatabase.instance
                        .ref('users/$_selectedFriendUid/events')
                        .onValue,
                    builder: (context, snapshot) {
                      // 로딩 중에도 캘린더 UI의 배경은 계속 보여줌
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Stack(
                          children: [
                            SfCalendar(view: CalendarView.month),
                            const Center(child: CircularProgressIndicator()),
                          ],
                        );
                      }

                      List<Appointment> appointments = [];
                      if (snapshot.hasData &&
                          snapshot.data!.snapshot.value != null) {
                        final eventsMap = snapshot.data!.snapshot.value
                            as Map<dynamic, dynamic>;
                        appointments = eventsMap.entries.map((entry) {
                          final data = entry.value as Map<dynamic, dynamic>;
                          return Appointment(
                            startTime: DateTime.parse(data['startTime']),
                            endTime: DateTime.parse(data['endTime']),
                            subject: data['eventName'] ?? '',
                            isAllDay: data['isAllDay'] ?? false,
                            color: data['color'] != null
                                ? Color(int.parse(data['color'], radix: 16))
                                : Colors.blue,
                          );
                        }).toList();
                      }

                      return SfCalendar(
                        view: CalendarView.month,
                        dataSource: _AppointmentDataSource(appointments),
                        monthViewSettings: const MonthViewSettings(
                          appointmentDisplayMode:
                              MonthAppointmentDisplayMode.appointment,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
