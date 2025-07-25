import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ 날짜 포맷 초기화용 import
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ✅ 한국어 로케일 데이터 초기화
  await initializeDateFormatting('ko_KR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '교대근무자 갓생살기',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
