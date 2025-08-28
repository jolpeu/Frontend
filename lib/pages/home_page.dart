import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:grad_front/pages/library_page.dart';
import 'package:grad_front/pages/my_page.dart';
import 'package:grad_front/config.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  List<Map<String, dynamic>> _books = [];

  String? _userId;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
    print('■ Home initState prefs 토큰: ${prefs.getString('token')}');

    _userId =prefs.getString('userId');
    setState(() {});
  });
    _fetchMyBooks();
  }

  Future<void> _fetchMyBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final uri = Uri.parse('http://localhost:8080/api/files/list');
    final resp = await http.get(
      uri,
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final utf8Body = utf8.decode(resp.bodyBytes);
      final List<dynamic> data = jsonDecode(utf8Body);
      final books = data.map((m) {
        final sentences = List<String>.from(m['sentences'] ?? []);
        return {
          'id': (m['id'] ?? m['bookId'])?.toString(),
          'title': m['filename'].toString().replaceAll('.pdf', ''),
          'status': '읽고 있는 책',
          'progress': 0.0,
          'preview': sentences.isNotEmpty ? sentences.first : '',
          'sentences': sentences,
        };
      }).toList();

      setState(() {
        _books = books;
      });
    } else {
      print('내 서재 불러오기 실패: ${resp.statusCode} ${resp.body}');
    }
  }

  void _handleNewBook(Map<String, dynamic> book) {
    setState(() {
      _books.add(book);
      _currentIndex = 0;
    });
    // 업로드 직후 서버에 저장된 전체 리스트 다시 불러오기
    _fetchMyBooks();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      LibraryPage(
        books: _books,
        userId: _userId ?? '',
        apiBaseUrl: apiBaseUrl,
      ),
      HomeMainContent(onUpload: _handleNewBook),
      MyPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        selectedItemColor: Color(0xFFB3C39C),
        unselectedItemColor: Color(0xFF676767),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: '서재',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}

class LoadingAnimation extends StatefulWidget {
  @override
  _LoadingAnimationState createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      4,
      (_) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500),
      ),
    );
    _animations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOut))
        .toList();
    _playForward();
  }

  Future<void> _playForward() async {
    for (var c in _controllers) {
      await Future.delayed(Duration(milliseconds: 300));
      c.forward();
    }
    await Future.delayed(Duration(milliseconds: 400));
    _playReverse();
  }

  Future<void> _playReverse() async {
    for (var c in _controllers.reversed) {
      await Future.delayed(Duration(milliseconds: 300));
      c.reverse();
    }
    await Future.delayed(Duration(milliseconds: 400));
    _playForward();
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    super.dispose();
  }

  Widget _buildLogo(Animation<double> ani, double angle, Offset off) {
    return Center(
      child: FadeTransition(
        opacity: ani,
        child: ScaleTransition(
          scale: ani,
          child: Transform.translate(
            offset: off,
            child: Transform.rotate(
              angle: angle,
              child: Image.asset('assets/icons/icon_leaf.png', width: 40),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          _buildLogo(_animations[0], 0, Offset(0, -24)),
          _buildLogo(_animations[1], 1.5708, Offset(24, 0)),
          _buildLogo(_animations[2], 3.1416, Offset(0, 24)),
          _buildLogo(_animations[3], 4.7124, Offset(-24, 0)),
        ],
      ),
    );
  }
}

class HomeMainContent extends StatefulWidget {
  final Function(Map<String, dynamic>) onUpload;
  const HomeMainContent({required this.onUpload});

  @override
  _HomeMainContentState createState() => _HomeMainContentState();
}

class _HomeMainContentState extends State<HomeMainContent> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  Uint8List? _pickedBytes;
  String? _pickedPath;
  String? _pickedName;

  final List<String> _cards = [
    'assets/images/1.png',
    'assets/images/2.png',
    'assets/images/3.png',
  ];

  @override
  void initState() {
    super.initState();
    _autoSlideTimer = Timer.periodic(Duration(seconds: 3), (_) {
      if (_pageController.hasClients) {
        final next = (_currentPage + 1) % _cards.length;
        _pageController.animateToPage(
          next,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage = next);
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null) return;

    _pickedBytes = result.files.single.bytes;
    _pickedPath = kIsWeb ? null : result.files.single.path;
    _pickedName = result.files.single.name;
    _confirmUpload(context);
  }

  void _confirmUpload(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('$_pickedName 파일을 업로드할까요?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pickPdf(ctx);
            },
            child: Text('다시 선택'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _uploadToServer();
            },
            child: Text('확인'),
          ),  
        ],
      ),
    );
  }

  Future<void> _uploadToServer() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      barrierColor: Colors.black54,
      builder: (_) => Center(child: LoadingAnimation()),
    );

    final bytes = _pickedBytes!;
    final name = _pickedName!;
    final path = _pickedPath;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('http://localhost:8080/api/files/analyze-pdf');
    final req = http.MultipartRequest('POST', uri);
    if (token != null) req.headers['Authorization'] = 'Bearer $token';

    if (kIsWeb || path == null) {
      req.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: name,
        contentType: MediaType('application', 'pdf'),
      ));
    } else {
      req.files.add(await http.MultipartFile.fromPath(
        'file',
        path,
        contentType: MediaType('application', 'pdf'),
      ));
    }

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    Navigator.of(context, rootNavigator: true).pop();

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      // analyze-pdf는 {id, filename} 객체 리턴
      final utf8Body = utf8.decode(resp.bodyBytes);
      final Map<String, dynamic> data = jsonDecode(utf8Body);
      final book = {
        'title': data['filename'].toString().replaceAll('.pdf', ''),
        'status': '읽고 있는 책',
        'progress': 0.0,
        'preview': '',
        'sentences': <String>[],
      };
      widget.onUpload(book);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('업로드 실패'),
          content: Text('${resp.statusCode}: ${resp.body}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('닫기'))
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 70,
          color: Color(0xDDB2C29B),
          child: Center(
            child: Image.asset('assets/logos/logo_horizontal.png', height: 40),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _cards.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(_cards[i], fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: ElevatedButton(
            onPressed: () => _pickPdf(context),
            child: Text('파일 업로드', style: TextStyle(fontSize: 40)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black54,
              padding: EdgeInsets.symmetric(horizontal: 60, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              elevation: 6,
            ),
          ),
        ),
      ],
    );
  }
}
