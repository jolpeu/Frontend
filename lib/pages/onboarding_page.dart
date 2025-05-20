import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  // stateful : 상태 변화
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with SingleTickerProviderStateMixin{
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // fade in/out 설정
    _controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 2),
    )..forward();

    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(_controller);

    // 로그인 여부 확인 후 이동
    Future.delayed(Duration(seconds: 3), (){
      checkLoginStatus();
    });
  }

  @override
  void dispose(){
    _controller.dispose();
    super.dispose();
  }

  Future<void> checkLoginStatus() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;   // 로그인 상태 가져오기 : 없으면 false

    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacementNamed(context,'/login');

    /*if(isLoggedIn){
      Navigator.pushReplacementNamed(context, '/home');
    } else{
      Navigator.pushReplacementNamed(context, '/login');
    }*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEF9D9),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
           child: Hero(
             tag: 'appLogo',
           child: Image.asset(
              'assets/images/logo.png',
              width: 300,
              height: 300,
           ),
          ),
        ),
      ),
    );
  }
}