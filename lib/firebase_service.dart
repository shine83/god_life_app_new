// firebase_service.dart 전체 코드
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// shareId로 친구를 찾아 Realtime Database에 권한 생성
Future<void> createAccessPermission(String friendShareId) async {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  // 1. Realtime Database에서 shareId로 친구의 uid를 찾습니다.
  final query = FirebaseDatabase.instance
      .ref('users')
      .orderByChild('shareId')
      .equalTo(friendShareId);
  final snapshot = await query.get();

  if (snapshot.exists) {
    final Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
    final String ownerUid = users.keys.first;

    // 2. Realtime Database의 'permissions' 경로에 새 데이터를 추가합니다.
    DatabaseReference newPermissionRef =
        FirebaseDatabase.instance.ref('permissions').push();
    await newPermissionRef.set({
      'ownerUid': ownerUid,
      'accessorUid': currentUser.uid,
      'canViewCalendar': true,
      'canViewMemos': true,
    });
  }
}

// 내 캘린더에 새 일정 추가
Future<void> addEventToMyCalendar({
  required String eventName,
  required DateTime startTime,
  required DateTime endTime,
  required Color color,
}) async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final eventRef =
      FirebaseDatabase.instance.ref('users/${user.uid}/events').push();
  await eventRef.set({
    'eventName': eventName,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'isAllDay': false,
    'color': color.value.toRadixString(16), // Color를 String으로 저장
  });
}
