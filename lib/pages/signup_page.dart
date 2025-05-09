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
    if(_pwController.text != _pwCheckController.text){
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
      appBar: AppBar(title: Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: InputDecoration(labelText: '아이디'),
            ),
            TextField(
              controller: _pwController,
              decoration: InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            TextField(
              controller: _pwCheckController,
              decoration: InputDecoration(labelText: '비밀번호 확인'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _signUp, child: Text('회원가입')),
          ],
        ),
      ),
    );
  }
}
