import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/library_page.dart';
import 'pages/login_page.dart';
import 'pages/my_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/signup_page.dart';
import 'pages/LoginRedirectPage.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '졸업 프로젝트',
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.grey[400],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      initialRoute: '/onboarding',
      routes: {
        '/home': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/login-redirect': (context) => const LoginRedirectPage(), // fallback 용도
        '/my': (context) => MyPage(),
        // '/library': (context) => LibraryPage(books: []),
        '/library': (context) => const _LibraryRoute(),
        '/onboarding': (context) => OnboardingPage(),
      },

      // ✅ 쿼리 파라미터 있는 라우트 처리
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');

        if (uri.path == '/login-redirect') {
          final token = uri.queryParameters['token'];
          return MaterialPageRoute(
            builder: (_) => LoginRedirectPage(token: token),
          );
        }

        // ✅ fallback 처리 필수
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('페이지를 찾을 수 없습니다.')),
          ),
        );
      },
    );
  }
}

/// ✅ LibraryPage로 들어가기 전에 userId/email 과 apiBaseUrl을 준비하는 래퍼
class _LibraryRoute extends StatefulWidget {
  const _LibraryRoute({Key? key}) : super(key: key);

  @override
  State<_LibraryRoute> createState() => _LibraryRouteState();
}

class _LibraryRouteState extends State<_LibraryRoute> {
  String? _email;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? 'guest';
    setState(() => _email = email);
  }

  @override
  Widget build(BuildContext context) {
    if (_email == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return LibraryPage(
      books: const [],               // TODO: 서버에서 불러오면 이 자리에서 넣기
      userId: _email!,
      apiBaseUrl: Config.apiBaseUrl,
    );
  }
}