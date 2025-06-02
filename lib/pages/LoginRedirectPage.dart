// LoginRedirectPage.dart
import 'package:flutter/material.dart';

class LoginRedirectPage extends StatelessWidget {
  final String? token;

  const LoginRedirectPage({Key? key, this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 로그인 토큰 저장 및 이동 처리
    if (token != null && token!.isNotEmpty) {
      Future.microtask(() async {
        // SharedPreferences에 저장 등 처리
        Navigator.pushReplacementNamed(context, '/home');
      });
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
