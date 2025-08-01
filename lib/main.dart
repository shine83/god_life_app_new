import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ Firebase Core
import 'firebase_options.dart'; // ✅ 생성된 Firebase 옵션 파일
import 'auth_gate.dart'; // AuthGate 임포트
import 'theme/app_theme.dart';
import 'home_page.dart';
import 'design_tokens.dart';
import 'share_settings_page.dart'; // ✅ 공유 설정 페이지 import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ko_KR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      // ✅ 3. 로케일 설정
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),

      // ✅ 4. 홈화면 설정
      home: const AuthGate(),
    );
  }
}
