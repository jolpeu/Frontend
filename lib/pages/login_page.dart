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
      backgroundColor: Color(0xFFFEF9D9),
      appBar: AppBar(title: Text('로그인')),
      body: SafeArea(
          child: Column(
            children: [
              Container(height: 60, color: Color(0xDDDEE5D4)),
              Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 흰색 카드 영역
                        Container(
                          padding: EdgeInsets.all(24),
                          margin: EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              width: 1,
                              color: Colors.grey,
                            )
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _idController,
                                decoration: InputDecoration(
                                  hintText: '이메일',
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
                              SizedBox(height: 12),
                              TextField(
                                controller: _pwController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: '비밀번호',
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
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child:
                                    TextButton(
                                      onPressed: (){},
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                        overlayColor: MaterialStateProperty.all(Colors.transparent),
                                        padding: MaterialStateProperty.all(EdgeInsets.zero),
                                        minimumSize: MaterialStateProperty.all(Size(0,0)),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text('이메일 찾기',
                                      style: TextStyle(
                                          color:Colors.black,
                                          decoration: TextDecoration.underline),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 0),
                                  Expanded(child:
                                    TextButton(
                                      onPressed: (){},
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                        overlayColor: MaterialStateProperty.all(Colors.transparent),
                                        padding: MaterialStateProperty.all(EdgeInsets.zero),
                                        minimumSize: MaterialStateProperty.all(Size(0,0)),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text('비밀번호 찾기',
                                        style: TextStyle(
                                            color:Colors.black,
                                            decoration: TextDecoration.underline),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 0),
                                  Expanded(child:
                                    TextButton(
                                        style: ButtonStyle(
                                          backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                          overlayColor: MaterialStateProperty.all(Colors.transparent),
                                          padding: MaterialStateProperty.all(EdgeInsets.zero),
                                          minimumSize: MaterialStateProperty.all(Size(0,0)),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed:() =>
                                          Navigator.pushNamed(context, '/signup'),
                                        child: Text('회원가입',
                                          style: TextStyle(
                                              color:Colors.black,
                                              decoration: TextDecoration.underline),),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 32),

                        // 소셜 로그인 버튼
                        SizedBox(
                          width: 280,
                          child: ElevatedButton.icon(
                              onPressed: _naverLogin,
                              //icon: Icon(Icons),
                              label: Text('네이버로 시작하기'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                            width: 280,
                            child: ElevatedButton.icon(
                              onPressed: _googleLogin,
                              //icon: Icon(Icons.g_mobiledata),
                              label: Text('구글로 시작하기'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                side: BorderSide(color: Colors.grey.shade100),
                                minimumSize: Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                          ),
                        ),
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

