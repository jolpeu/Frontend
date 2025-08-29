// LoginRedirectPage.dart (수정된 코드)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:grad_front/config.dart'; // Config 파일 import

class LoginRedirectPage extends StatefulWidget {
  final String? token;

  const LoginRedirectPage({Key? key, this.token}) : super(key: key);

  @override
  _LoginRedirectPageState createState() => _LoginRedirectPageState();
}

class _LoginRedirectPageState extends State<LoginRedirectPage> {
  @override
  void initState() {
    super.initState();
    if (widget.token != null && widget.token!.isNotEmpty) {
      // 위젯이 빌드된 후 바로 로그인 처리 함수를 호출
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLoginSuccess(widget.token!);
      });
    } else {
      // 토큰이 없는 경우 로그인 페이지로
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  // 로그인 성공 후 처리 로직
  Future<void> _handleLoginSuccess(String token) async {
    try {
      // 1. 새 토큰으로 서버에 사용자 정보(이메일 등)를 요청
      final profileUri = Uri.parse('${Config.apiBaseUrl}/auth/user/me');
      final response = await http.get(
        profileUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final userEmail = data['email']?.toString();

        if (userEmail != null && userEmail.isNotEmpty) {
          // 2. SharedPreferences에 새 토큰과 이메일을 저장
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('email', userEmail);
          await prefs.setBool('isLoggedIn', true);

          // 3. 홈 화면으로 이동
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          // 이메일을 받지 못한 경우 에러 처리
          _showErrorAndRedirect('사용자 정보를 가져오지 못했습니다.');
        }
      } else {
        // API 요청 실패 시 에러 처리
        _showErrorAndRedirect('인증에 실패했습니다. 다시 로그인해주세요.');
      }
    } catch (e) {
      // 네트워크 오류 등 예외 발생 시 에러 처리
      _showErrorAndRedirect('오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  void _showErrorAndRedirect(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 처리 중
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('로그인 정보를 처리 중입니다...'),
          ],
        ),
      ),
    );
  }
}