// supabase_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// ✅ 메모 추가
Future<void> addMemoToMyNotes({required String content}) async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final response = await supabase.from('memos').insert({
    'user_id': user.id,
    'content': content,
    'created_at': DateTime.now().toIso8601String(),
  });

  if (response.error != null) {
    print('메모 추가 실패: \${response.error!.message}');
  }
}

// ✅ 특정 사용자 메모 가져오기
Future<List<Map<String, dynamic>>> getMemosForUser(String uid) async {
  final response = await supabase
      .from('memos')
      .select()
      .eq('user_id', uid)
      .order('created_at', ascending: false);

  if (response.error != null) {
    print('메모 가져오기 실패: \${response.error!.message}');
    return [];
  }
  return List<Map<String, dynamic>>.from(response.data);
}

// ✅ 근무일정 이벤트 추가
Future<void> addEventToMyCalendar({
  required String eventName,
  required DateTime startTime,
  required DateTime endTime,
  required Color color,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final response = await supabase.from('calendar_events').insert({
    'user_id': user.id,
    'title': eventName,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'color': color.value.toRadixString(16),
  });

  if (response.error != null) {
    print('이벤트 추가 실패: \${response.error!.message}');
  }
}

// ✅ 공유 권한 생성
Future<void> createAccessPermission(String friendShareId) async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final response = await supabase.from('permissions').insert({
    'owner_id': user.id,
    'shared_with_id': friendShareId,
    'can_view_calendar': true,
    'can_view_memos': true,
    'created_at': DateTime.now().toIso8601String(),
  });

  if (response.error != null) {
    print('공유 권한 생성 실패: \${response.error!.message}');
  }
}

// ✅ 권한 업데이트
Future<void> updatePermissions(
  String permissionId, {
  bool? canViewCalendar,
  bool? canViewMemos,
}) async {
  final updates = <String, dynamic>{};
  if (canViewCalendar != null) updates['can_view_calendar'] = canViewCalendar;
  if (canViewMemos != null) updates['can_view_memos'] = canViewMemos;

  if (updates.isNotEmpty) {
    final response = await supabase
        .from('permissions')
        .update(updates)
        .eq('id', permissionId);

    if (response.error != null) {
      print('권한 업데이트 실패: \${response.error!.message}');
    }
  }
}
