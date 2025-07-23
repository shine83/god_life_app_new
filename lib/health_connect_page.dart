import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HealthConnectPage extends StatefulWidget {
  const HealthConnectPage({super.key});

  @override
  State<HealthConnectPage> createState() => _HealthConnectPageState();
}

class _HealthConnectPageState extends State<HealthConnectPage> {
  bool appleHealthEnabled = false;
  bool googleFitEnabled = false;
  bool samsungHealthEnabled = false;

  @override
  Widget build(BuildContext context) {
    // 현재 플랫폼 상태를 먼저 잡아줌
    final isIOS = !kIsWeb && Platform.isIOS;
    final isAndroid = !kIsWeb && Platform.isAndroid;

    return Scaffold(
      appBar: AppBar(title: const Text('건강앱 연동')),
      body: ListView(
        children: [
          if (isIOS) ...[
            SwitchListTile(
              title: const Text('Apple 건강앱 연동'),
              subtitle: const Text('iOS에서만 사용 가능'),
              value: appleHealthEnabled,
              onChanged: (val) {
                setState(() {
                  appleHealthEnabled = val;
                });
                // TODO: Apple HealthKit 연동 로직
              },
            ),
          ],
          if (isAndroid) ...[
            SwitchListTile(
              title: const Text('Google Fit 연동'),
              subtitle: const Text('안드로이드 기기용'),
              value: googleFitEnabled,
              onChanged: (val) {
                setState(() {
                  googleFitEnabled = val;
                });
                // TODO: Google Fit 연동 로직
              },
            ),
            SwitchListTile(
              title: const Text('Samsung Health 연동'),
              subtitle: const Text('삼성 기기용'),
              value: samsungHealthEnabled,
              onChanged: (val) {
                setState(() {
                  samsungHealthEnabled = val;
                });
                // TODO: Samsung Health 연동 로직
              },
            ),
          ],
          if (!isIOS && !isAndroid)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                '현재 플랫폼에서는 건강앱 연동이 지원되지 않습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
