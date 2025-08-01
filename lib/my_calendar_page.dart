import 'package:flutter/material.dart';
import 'package:god_life_app/supabase_service.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyCalendarPage extends StatefulWidget {
  const MyCalendarPage({super.key});

  @override
  State<MyCalendarPage> createState() => _MyCalendarPageState();
}

class _MyCalendarPageState extends State<MyCalendarPage> {
  late final String userId;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception("로그인이 필요합니다");
    }
    userId = user.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getCalendarEventsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = (snapshot.data ?? []).map((data) {
            return Appointment(
              startTime: DateTime.parse(data['startTime']),
              endTime: DateTime.parse(data['endTime']),
              subject: data['eventName'] ?? '',
              isAllDay: data['isAllDay'] ?? false,
              color: data['color'] != null
                  ? Color(int.tryParse(data['color'].toString()) ??
                      Colors.blue.value)
                  : Colors.blue,
            );
          }).toList();

          return SfCalendar(
            view: CalendarView.month,
            dataSource: _AppointmentDataSource(appointments),
            monthViewSettings: const MonthViewSettings(
              appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddEventDialog(context),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final TextEditingController eventNameController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(hours: 1));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('새 일정 추가'),
          content: TextField(
            controller: eventNameController,
            decoration: const InputDecoration(hintText: "일정 이름"),
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('저장'),
              onPressed: () async {
                if (eventNameController.text.isNotEmpty) {
                  await addEventToMyCalendar(
                    eventName: eventNameController.text,
                    startTime: startDate,
                    endTime: endDate,
                    color: Colors.blue,
                  );
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

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
