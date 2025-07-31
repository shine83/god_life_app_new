import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:god_life_app/firebase_service.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class MyCalendarPage extends StatelessWidget {
  const MyCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(myUid)
            .collection('events')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Appointment(
              startTime: (data['startTime'] as Timestamp).toDate(),
              endTime: (data['endTime'] as Timestamp).toDate(),
              subject: data['eventName'] ?? '',
              isAllDay: data['isAllDay'] ?? false,
              color: data['color'] != null
                  ? Color(int.parse(data['color'], radix: 16))
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
    DateTime? startDate;
    DateTime? endDate;

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
                // TODO: 날짜/시간 선택 UI 추가 (showDatePicker, showTimePicker)
                // 우선은 현재 시간으로 임시 저장
                startDate = DateTime.now();
                endDate = DateTime.now().add(const Duration(hours: 1));

                if (eventNameController.text.isNotEmpty &&
                    startDate != null &&
                    endDate != null) {
                  await addEventToMyCalendar(
                    eventName: eventNameController.text,
                    startTime: startDate!,
                    endTime: endDate!,
                    color: Colors.blue, // TODO: 색상 선택 기능
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
