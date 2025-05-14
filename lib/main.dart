import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/library_page.dart';
import 'pages/login_page.dart';
import 'pages/my_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/reader_page.dart';
import 'pages/signup_page.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '졸업 프로젝트',
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: Color(0xFFFEF9D9),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
            hintStyle: TextStyle(color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.grey[400],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: Size(double.infinity, 48),
          ),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 16),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      initialRoute: '/onboarding', // 앱 켜면 온보딩화면으로 뜸
      routes: {
        '/home': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/my': (context) => MyPage(),
        '/library': (context) => LibraryPage(books: []),
        //'/reader': (context) => ReaderPage(),
        '/onboarding': (context) => OnboardingPage(),
      },
    );
  }
}

