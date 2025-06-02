import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 회원가입 페이지
class SignUpPage extends StatefulWidget{
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>{
  final _idController = TextEditingController();    // 이메일 입력 컨트롤러
  final _pwController = TextEditingController();    // 비밀번호 입력 컨트롤러 
  final _pwCheckController = TextEditingController(); // 비밀번호 확인 컨트롤러

  /// 회원가입 처리 로직
  void _signUp() async {
    // 이메일 미입력 시 안내
    if(_idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일이 입력되지 않았습니다..')),
      );
      return;
    }

    // 비밀번호 미입력 시 안내
    else if(_pwController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 입력되지 않았습니다..')),
      );
      return;
    }

    // 비밀번호 확인란이 비어 있거나 불일치 시 안내
    if(_pwController.text != _pwCheckController.text || _pwCheckController.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    final url = Uri.parse('http://localhost:8080/auth/signup'); // Flutter Web에서는 localhost 사용 가능

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 회원가입 완료')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError("회원가입 실패: ${response.body}");
      }
    } catch (e) {
      _showError("서버 연결 실패: $e");
    }

    // 홈 화면으로 이동
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showError(String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9D9),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(

          // 세로 가운데 정렬
          children: [
            SizedBox(height: 32),
            // 상단 헤더 영억 - 로고 들어갈 예정
            Hero(
              tag: 'appLogo',
              child: Image.asset(
                'assets/images/logo.png',
                width: 200, // 줄어든 크기
                height: 200,
              ),
            ),
            SizedBox(height: 32),

            // 흰색 카드형 컨테이너
            Container(
                padding: EdgeInsets.all(24),
                margin: EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    width: 1,
                    color: Colors.grey,
                  ),
                ),
                child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '*필수입력사항',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  // 이메일 입력 필드
                  TextField(
                      controller: _idController,
                      decoration: InputDecoration(
                        labelText: '이메일 *',
                        hintText: 'example@email.com',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey.shade100,
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey.shade100,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 16),

                  // 비밀번호 입력 필드
                  TextField(
                    controller: _pwController,
                    decoration: InputDecoration(
                      labelText: '비밀번호 *',
                      hintText: '영문/숫자 조합, 8~16자',
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.shade100,
                          width: 2.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.shade100,
                          width: 2.0,
                        ),
                      ),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 16),

                  // 비밀번호 확인 입력 필드
                  TextField(
                    controller: _pwCheckController,
                    decoration: InputDecoration(
                      labelText: '비밀번호 확인 *',
                      hintText: '비밀번호를 다시 입력하십시오.',
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.shade100,
                          width: 2.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.shade100,
                          width: 2.0,
                        ),
                      ),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 24),

                  // 회원가입 버튼
                  SizedBox(
                    width: double.infinity,
                    child:
                    ElevatedButton(
                        onPressed: _signUp,
                        child: Text('회원가입'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
