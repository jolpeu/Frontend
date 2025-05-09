import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  // stateful : 상태 변화
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>{
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(seconds: 3), (){
      checkLoginStatus();
    });
  }

  Future<void> checkLoginStatus() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;   // 로그인 상태 가져오기 : 없으면 false

    if(isLoggedIn){
      Navigator.pushReplacementNamed(context, '/home');
    } else{
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('온보딩'),
      ),
      body: Center(
        child: Text('온보딩 화면입니다.'),
      ),
    );
  }
}