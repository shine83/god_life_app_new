// sharing_management_page.dart 전체 수정본
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:god_life_app/firebase_service.dart';

class SharingManagementPage extends StatelessWidget {
  const SharingManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // currentUser가 null일 수 있으므로 안전하게 처리
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('공유 관리')),
        body: const Center(child: Text("로그인이 필요합니다.")),
      );
    }

    final String myUid = currentUser.uid;
    final DatabaseReference permissionsRef =
        FirebaseDatabase.instance.ref('permissions');

    return Scaffold(
      appBar: AppBar(
        title: const Text('공유 관리'),
      ),
      body: StreamBuilder(
        stream: permissionsRef.orderByChild('ownerUid').equalTo(myUid).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("나의 정보를 구독하는 친구가 없습니다."));
          }

          final permissionsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final followerList = permissionsMap.entries.toList();

          return ListView.builder(
            itemCount: followerList.length,
            itemBuilder: (context, index) {
              final permissionKey = followerList[index].key as String;
              final data = followerList[index].value as Map<dynamic, dynamic>;
              final accessorUid = data['accessorUid'];
              final canViewCalendar = data['canViewCalendar'] ?? false;
              final canViewMemos = data['canViewMemos'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("구독자: ${accessorUid.substring(0, 6)}...",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      CheckboxListTile(
                        title: const Text("캘린더 공유 허용"),
                        value: canViewCalendar,
                        onChanged: (bool? value) {
                          updatePermissions(permissionKey,
                              canViewCalendar: value);
                        },
                      ),
                      CheckboxListTile(
                        title: const Text("메모 공유 허용"),
                        value: canViewMemos,
                        onChanged: (bool? value) {
                          updatePermissions(permissionKey, canViewMemos: value);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
