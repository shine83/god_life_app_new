import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page.dart';
import 'theme/app_theme.dart';
import 'design_tokens.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'share_settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Supabase 초기화 (아래 URL과 anonKey는 본인 프로젝트에 맞게 바꿔주세요!)
  await Supabase.initialize(
    url: 'https://ojcjalbvvhhispwsqpwi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qY2phbGJ2dmhoaXNwd3NxcHdpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQwMzMxNzcsImV4cCI6MjA2OTYwOTE3N30.vdeEfnDKblCww727P51oeT5BOZavg13RzwJIMJr94CA', // ✅ 실제 anonKey로 교체
  );

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

      // ✅ 앱 시작 시 바로 홈화면으로 진입
      home: const HomePage(),

      // ✅ 명시적 라우팅 등록
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/share-settings': (context) => const ShareSettingsPage(),
      },
    );
  }
}
