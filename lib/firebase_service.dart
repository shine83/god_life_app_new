// firebase_service.dart 전체 코드
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// (기존 함수들은 그대로 유지)
Future<void> createAccessPermission(String friendShareId) async {
  // ...
}

Future<void> addEventToMyCalendar({
  required String eventName,
  required DateTime startTime,
  required DateTime endTime,
  required Color color,
}) async {
  // ...
}

// +++ 추가: 내 메모장에 새 메모 추가
Future<void> addMemoToMyNotes({required String content}) async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final memoRef =
      FirebaseDatabase.instance.ref('users/${user.uid}/memos').push();
  await memoRef.set({
    'content': content,
    'createdAt': DateTime.now().toIso8601String(),
  });
}

// +++ 추가: 특정 사용자의 메모 목록을 실시간으로 가져오기
Stream<DatabaseEvent> getMemosForUser(String uid) {
  return FirebaseDatabase.instance.ref('users/$uid/memos').onValue;
}
