import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// 웹 전용 네비게이션
import 'package:web/web.dart' as web;

/// 로그인 페이지
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  Future<void> _login() async {
    final url = Uri.parse('http://localhost:8080/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _idController.text.trim(),
        'password': _pwController.text.trim(),
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', _idController.text.trim());
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showErrorSnackbar('로그인 실패: \${response.body}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
  }

  /// 웹: 현재 창에서 직접 OAuth 흐름 시작
  void _naverLogin() {
    web.window.location.href =
        'http://localhost:8080/oauth2/authorization/naver';
  }

  void _googleLogin() {
    web.window.location.href =
        'http://localhost:8080/oauth2/authorization/google';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 100),
            Hero(
              tag: 'appLogo',
              child: Image.asset(
                'assets/logos/logo.png',
                width: 200,
                height: 200,
              ),
            ),
            SizedBox(height: 32),
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    _buildLoginCard(),
                    SizedBox(height: 32),
                    _buildSocialButton(
                      label: '네이버로 시작하기',
                      color: Colors.green,
                      onPressed: _naverLogin,
                    ),
                    SizedBox(height: 12),
                    _buildSocialButton(
                      label: '구글로 시작하기',
                      color: Colors.white,
                      textColor: Colors.black,
                      border: BorderSide(color: Colors.grey.shade100),
                      onPressed: _googleLogin,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: EdgeInsets.all(24),
      margin: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: Colors.black12),
      ),
      child: Column(
        children: [
          TextField(
            controller: _idController,
            decoration: InputDecoration(hintText: '이메일'),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _pwController,
            obscureText: true,
            decoration: InputDecoration(hintText: '비밀번호'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('로그인'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: Text(
                '회원가입',
                style: TextStyle(
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Color color,
    Color textColor = Colors.white,
    BorderSide? border,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 280,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          side: border,
          minimumSize: Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
