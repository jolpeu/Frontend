import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;
import 'package:grad_front/utils/http_errors.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  bool _submitting = false;

  static const _keyColor = Color(0xFFB3C39C);
  final _emailReg = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.[A-Za-z]{2,}$');

  bool get _canSubmit =>
      _emailReg.hasMatch(_idController.text.trim()) &&
          _pwController.text.trim().isNotEmpty;

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _login() async {
    if (!_canSubmit || _submitting) return;

    setState(() => _submitting = true);
    final url = Uri.parse('http://localhost:8080/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _idController.text.trim(),
          'password': _pwController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final token = data['token']?.toString() ?? '';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('email', _idController.text.trim());
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final msg = friendlyErrorFromResponse(
          response,
          overrides: {
            401: '이메일 또는 비밀번호를 확인해주세요.',
            400: '이메일 또는 비밀번호를 확인해주세요.',
          },
        );
        _showErrorSnackbar(msg);
      }
    } catch (e) {
      _showErrorSnackbar('서버에 연결할 수 없습니다. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _naverLogin() {
    web.window.location.href = 'http://localhost:8080/oauth2/authorization/naver';
  }

  void _googleLogin() {
    web.window.location.href = 'http://localhost:8080/oauth2/authorization/google';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Hero(
              tag: 'appLogo',
              child: Image.asset('assets/logos/logo.png', width: 200, height: 200),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    _buildLoginCard(),
                    const SizedBox(height: 32),
                    _buildSocialButton(
                      label: '네이버로 시작하기',
                      color: Colors.green,
                      onPressed: _naverLogin,
                    ),
                    const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: Colors.black12),
      ),
      child: Column(
        children: [
          TextField(
            controller: _idController,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: '이메일'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pwController,
            onChanged: (_) => setState(() {}),
            obscureText: true,
            decoration: const InputDecoration(hintText: '비밀번호'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _canSubmit ? _login : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canSubmit ? _keyColor : Colors.grey[300],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_submitting ? '처리 중...' : '로그인'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: const Text(
                '회원가입',
                style: TextStyle(color: Colors.black, decoration: TextDecoration.underline),
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
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(label),
      ),
    );
  }
}
