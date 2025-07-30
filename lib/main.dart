import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart'; // ★
import 'theme/app_theme.dart';
import 'home_page.dart';
import 'design_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 원하는 로케일(예: 'ko_KR') 초기화
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

      // ─── 로케일 및 로컬라이제이션 위임자 ─────────────────────────
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
        // 필요에 따라 다른 로케일 추가
      ],
      locale: const Locale('ko', 'KR'),
      // ─────────────────────────────────────────────────────────────

      home: const HomePage(),
    );
  }
}
