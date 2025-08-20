// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// /// 회원가입 페이지
// class SignUpPage extends StatefulWidget{
//   @override
//   _SignUpPageState createState() => _SignUpPageState();
// }
//
// class _SignUpPageState extends State<SignUpPage>{
//   final _idController = TextEditingController();    // 이메일 입력 컨트롤러
//   final _pwController = TextEditingController();    // 비밀번호 입력 컨트롤러
//   final _pwCheckController = TextEditingController(); // 비밀번호 확인 컨트롤러
//
//   /// 회원가입 처리 로직
//   void _signUp() async {
//     // 이메일 미입력 시 안내
//     if(_idController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('이메일이 입력되지 않았습니다.')),
//       );
//       return;
//     }
//
//     // 비밀번호 미입력 시 안내
//     else if(_pwController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('비밀번호가 입력되지 않았습니다.')),
//       );
//       return;
//     }
//
//     // 비밀번호 확인란이 비어 있거나 불일치 시 안내
//     if(_pwController.text != _pwCheckController.text || _pwCheckController.text.isEmpty){
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
//       );
//       return;
//     }
//
//     final url = Uri.parse('http://localhost:8080/auth/signup'); // Flutter Web에서는 localhost 사용 가능
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'email': _idController.text.trim(),
//           'password': _pwController.text.trim(),
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('✅ 회원가입 완료')),
//         );
//         Navigator.pushReplacementNamed(context, '/login');
//       } else {
//         _showError("회원가입 실패: ${response.body}");
//       }
//     } catch (e) {
//       _showError("서버 연결 실패: $e");
//     }
//
//     // 홈 화면으로 이동
//     Navigator.pushReplacementNamed(context, '/login');
//   }
//
//   void _showError(String msg) {
//   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
// }
//
//   @override
//   Widget build(BuildContext context){
//     return Scaffold(
//       backgroundColor: Colors.white70,
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//
//           // 세로 가운데 정렬
//           children: [
//             SizedBox(height: 76),
//             // 상단 헤더 영억
//             Hero(
//               tag: 'appLogo',
//               child: Image.asset(
//                 'assets/logos/logo.png',
//                 width: 200, // 줄어든 크기
//                 height: 200,
//               ),
//             ),
//             SizedBox(height: 32),
//
//             // 흰색 카드형 컨테이너
//             Container(
//                 padding: EdgeInsets.all(24),
//                 margin: EdgeInsets.symmetric(horizontal: 24),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     width: 1,
//                     color: Colors.black12,
//                   ),
//                 ),
//                 child: Column(
//                 children: [
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: Text(
//                       '*필수입력사항',
//                       style: TextStyle(
//                         color: Colors.red,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                   // 이메일 입력 필드
//                   TextField(
//                       controller: _idController,
//                       decoration: InputDecoration(
//                         labelText: '이메일 *',
//                         hintText: 'example@email.com',
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: BorderSide(
//                             color: Colors.grey.shade100,
//                             width: 2.0,
//                           ),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderSide: BorderSide(
//                             color: Colors.grey.shade100,
//                             width: 2.0,
//                           ),
//                         ),
//                       ),
//                     ),
//                   SizedBox(height: 16),
//
//                   // 비밀번호 입력 필드
//                   TextField(
//                     controller: _pwController,
//                     decoration: InputDecoration(
//                       labelText: '비밀번호 *',
//                       hintText: '영문/숫자 조합, 8~16자',
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: BorderSide(
//                           color: Colors.grey.shade100,
//                           width: 2.0,
//                         ),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: BorderSide(
//                           color: Colors.grey.shade100,
//                           width: 2.0,
//                         ),
//                       ),
//                     ),
//                     obscureText: true,
//                   ),
//                   SizedBox(height: 16),
//
//                   // 비밀번호 확인 입력 필드
//                   TextField(
//                     controller: _pwCheckController,
//                     decoration: InputDecoration(
//                       labelText: '비밀번호 확인 *',
//                       hintText: '비밀번호를 다시 입력하십시오.',
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: BorderSide(
//                           color: Colors.grey.shade100,
//                           width: 2.0,
//                         ),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: BorderSide(
//                           color: Colors.grey.shade100,
//                           width: 2.0,
//                         ),
//                       ),
//                     ),
//                     obscureText: true,
//                   ),
//                   SizedBox(height: 24),
//
//                   // 회원가입 버튼
//                   SizedBox(
//                     width: double.infinity,
//                     child:
//                     ElevatedButton(
//                         onPressed: _signUp,
//                         child: Text('회원가입'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.grey[300],
//                           foregroundColor: Colors.white,
//                           minimumSize: Size(double.infinity, 48),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:grad_front/utils/http_errors.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _idController = TextEditingController();       // 이메일
  final _pwController = TextEditingController();       // 비밀번호
  final _pwCheckController = TextEditingController();  // 비밀번호 확인

  bool _submitting = false;
  bool _obscurePw = true;
  bool _obscurePw2 = true;

  static const _keyColor = Color(0xFFB3C39C);

  // 이메일/비밀번호 규칙
  final _emailReg = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.[A-Za-z]{2,}$');
  final _pwReg = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,16}$');

  bool get _allValid =>
      _emailReg.hasMatch(_idController.text.trim()) &&
          _pwReg.hasMatch(_pwController.text.trim()) &&
          _pwController.text.trim() == _pwCheckController.text.trim();

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final url = Uri.parse('http://localhost:8080/auth/signup');

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
        _showSnack('✅ 회원가입 완료');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final msg = friendlyErrorFromResponse(
          response,
          overrides: {
            409: '이미 가입된 이메일입니다.',
            400: '이메일 형식과 비밀번호 규칙을 확인해주세요.',
          },
        );
        _showSnack(msg);
      }
    } catch (e) {
      _showSnack('서버 연결 실패: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _pwCheckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 76),
            Hero(
              tag: 'appLogo',
              child: Image.asset('assets/logos/logo.png', width: 200, height: 200),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(width: 1, color: Colors.black12),
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: () => setState(() {}), // 입력 변화시 버튼 색 업데이트
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('*필수입력사항', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),

                    // 이메일
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: '이메일 *',
                        hintText: 'example@email.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return '이메일을 입력하세요.';
                        if (!_emailReg.hasMatch(s)) return '이메일 형식이 올바르지 않습니다.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 비밀번호
                    TextFormField(
                      controller: _pwController,
                      decoration: InputDecoration(
                        labelText: '비밀번호 *',
                        hintText: '영문/숫자 조합, 8~16자',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePw ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePw = !_obscurePw),
                        ),
                      ),
                      obscureText: _obscurePw,
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return '비밀번호를 입력하세요.';
                        if (!_pwReg.hasMatch(s)) return '영문/숫자 조합 8~16자로 입력하세요.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 비밀번호 확인
                    TextFormField(
                      controller: _pwCheckController,
                      decoration: InputDecoration(
                        labelText: '비밀번호 확인 *',
                        hintText: '비밀번호를 다시 입력하십시오.',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePw2 ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePw2 = !_obscurePw2),
                        ),
                      ),
                      obscureText: _obscurePw2,
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return '비밀번호 확인을 입력하세요.';
                        if (s != _pwController.text.trim()) return '비밀번호가 일치하지 않습니다.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 회원가입 버튼 (유효하면 키컬러, 아니면 회색)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_allValid && !_submitting) ? _signUp : null, // null이면 비활성
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _allValid ? _keyColor : Colors.grey[300],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(_submitting ? '처리 중...' : '회원가입'),
                      ),
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
}
