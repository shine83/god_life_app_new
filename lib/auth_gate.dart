import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_page.dart'; // 앞으로 만들 로그인 페이지

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginPage(); // 로그인 안됐으면 로그인 페이지로
        }
        return const HomePage(); // 로그인 됐으면 홈 페이지로
      },
    );
  }
}
