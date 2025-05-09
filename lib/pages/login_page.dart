import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget{
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  void _login() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedId = prefs.getString('userId');
    String? savedPw = prefs.getString('userPw');

    if(_idController.text == savedId && _pwController.text == savedPw){
      await prefs.setBool('isLoggedIn', true);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('아이디 또는 비밀번호가 틀렸습니다.')),
      );
    }
  }

  void _naverLogin(){
    print('네이버 로그인 버튼 눌림');
  }

  void _googleLogin(){
    print('구글 로그인 버튼 눌림');
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('로그인')),
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
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text('로그인')),
            TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: Text('회원가입'),
            ),
            Divider(height: 40),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _naverLogin,
              icon: Icon(Icons.account_circle),
              label: Text('네이버로 로그인하기'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _googleLogin,
              icon: Icon(Icons.account_circle),
              label: Text('구글로 로그인하기'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

