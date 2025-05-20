import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 페이지
class LoginPage extends StatefulWidget{
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  void _login() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedId = prefs.getString('userId');    // 아이디 입력 컨트롤러
    String? savedPw = prefs.getString('userPw');    // 비밀번호 입력 컨트롤러

    /// 로컬에 저장된 ID/PW와 비교 후 로그인 처리
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
      body: SafeArea(
          child: Column(
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

              // 메인 로그인 영역
              Expanded(
                  child: Center(
                    child: Column(
                      //mainAxisSize: MainAxisSize.min,
                      children: [
                        // 흰색 카드 형태의 입력 박스
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
                              // 이메일 입력창(ID)
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
                              // 비밀번호 입력창
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
                              // 로그인 버튼
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

                              // 이메일 찾기 / 비밀번호 찾기 / 회원가입
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // 이메일 찾기 버튼
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
                                  // 비밀번호 찾기 버튼
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

                                  // 회원가입 이동 버튼
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

                        // 네이버 소셜 로그인 버튼
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

                        // 구글 소셜 로그인 버튼
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

