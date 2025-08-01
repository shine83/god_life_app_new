import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Stream<List<Map<String, dynamic>>> getMemosStream(String shareId) {
  final client = Supabase.instance.client;

  final stream =
      client.from('memos').stream(primaryKey: ['id']).eq('share_id', shareId);

  return stream;
}

class FriendsCalendarView extends StatefulWidget {
  const FriendsCalendarView({super.key});

  @override
  State<FriendsCalendarView> createState() => _FriendsCalendarViewState();
}

class _FriendsCalendarViewState extends State<FriendsCalendarView> {
  String? _selectedShareId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("공유 캘린더"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "공유 ID 입력",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                setState(() {
                  _selectedShareId = value.trim();
                });
              },
            ),
          ),
          Expanded(
            child: _selectedShareId == null
                ? SfCalendar(view: CalendarView.month)
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: getMemosStream(_selectedShareId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Stack(
                          children: [
                            SfCalendar(view: CalendarView.month),
                            const Center(child: CircularProgressIndicator()),
                          ],
                        );
                      }

                      final events = snapshot.data ?? [];
                      final appointments = events.map((data) {
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
