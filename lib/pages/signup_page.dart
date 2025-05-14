import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SignUpPage extends StatefulWidget{
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>{
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwCheckController = TextEditingController();

  void _signUp() async {
    if(_idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일이 입력되지 않았습니다..')),
      );
      return;
    }

    else if(_pwController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 입력되지 않았습니다..')),
      );
      return;
    }

    if(_pwController.text != _pwCheckController.text || _pwCheckController.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _idController.text);
    await prefs.setString('userPw', _pwController.text);
    await prefs.setBool('isLoggedIn', true);

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9D9),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                  Text(
                    '*필수입력사항',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
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
