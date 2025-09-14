import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:grad_front/pages/reader_page.dart';
import 'package:grad_front/config.dart';
import 'package:grad_front/models/analysis_result.dart';
import 'package:http/http.dart' as http;

class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  // UI 상태
  bool _loading = true;
  bool _editingNick = false;

  // 사용자 정보
  String _email = '';
  String _nickname = 'Nickname';

  // 닉네임 입력 컨트롤러
  final _nickCtrl = TextEditingController();

  // 프로필 이미지 (모바일: 파일경로 / 웹: bytes)
  File? _profileFile;
  Uint8List? _profileBytes;

  // 통계 상태
  int totalBooks = 0;                // 총 책 수
  double completionRate = 0.0;       // 0.0 ~ 1.0
  List<Map<String, dynamic>> recentBooks = []; // 최근 3권 [{id,title,sentences/results}, ...]

  static const _keyColor = Color(0xFFB3C39C);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    final nickKey = 'nickname_$email';
    final imgKey = 'profile_img_$email'; // 웹: base64 저장, 모바일: 파일경로 저장

    final nick = prefs.getString(nickKey) ??
        (email.contains('@') ? email.split('@').first : 'Nickname');

    // 이미지 로드
    File? file;
    Uint8List? bytes;
    final saved = prefs.getString(imgKey);
    if (saved != null && saved.isNotEmpty) {
      if (kIsWeb) {
        try {
          bytes = base64Decode(saved);
        } catch (_) {}
      } else {
        final f = File(saved);
        if (await f.exists()) file = f;
      }
    }

    setState(() {
      _email = email;
      _nickname = nick;
      _nickCtrl.text = nick;
      _profileFile = file;
      _profileBytes = bytes;
      _loading = false;
    });

    await _loadStats(); // 통계 로드
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final email = _email;

    // 초기화
    int bookCount = 0;
    double completedRate = 0.0;
    List<Map<String, dynamic>> recent = [];

    if (token == null || email.isEmpty) {
      setState(() {
        totalBooks = bookCount;
        completionRate = completedRate;
        recentBooks = recent;
      });
      return;
    }

    // 1) 내 책 목록 가져오기
    final listUri = Uri.parse('${Config.apiBaseUrl}/api/files/list');
    final listRes = await http.get(
      listUri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (listRes.statusCode < 200 || listRes.statusCode >= 300) {
      // 실패해도 빈 값으로 갱신
      setState(() {
        totalBooks = 0;
        completionRate = 0.0;
        recentBooks = [];
      });
      return;
    }

    final listBody = utf8.decode(listRes.bodyBytes);
    final decoded = jsonDecode(listBody);
    if (decoded is! List) {
      setState(() { totalBooks = 0; completionRate = 0.0; recentBooks = []; });
      return;
    }
    final List<dynamic> listJson = decoded;

    // 파일목록 표준화
    final books = listJson.map<Map<String, dynamic>>((m) {
      final map = Map<String, dynamic>.from(m as Map);

      final resultsData = List<Map<String, dynamic>>.from(map['results'] ?? const []);

      final sentences = resultsData.map((r) => (r['sentence'] ?? '').toString()).toList();

      return {
        'id': (map['id'] ?? map['bookId'])?.toString(),
        'title': (map['filename'] ?? map['title'] ?? '').toString().replaceAll('.pdf', ''),
        'filename': (map['filename'] ?? '').toString(),
        'sentences': sentences,
        'results': resultsData,
        'raw': map,
      };
    }).toList();

    bookCount = books.length;

    // 2) 각 책의 진행률 조회(병렬)
    final futures = books.map((b) async {
      final bookId = (b['id'] ?? '').toString();
      if (bookId.isEmpty) {
        return {'book': b, 'ratio': 0.0, 'updatedAt': null};
      }
      final progressUri = Uri.parse('${Config.apiBaseUrl}/reading-progress')
          .replace(queryParameters: {'userId': email, 'bookId': bookId});

      try {
        final res = await http.get(
          progressUri,
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
        );
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          final body = utf8.decode(res.bodyBytes);
          final json = jsonDecode(body);
          final ratio = (json['ratio'] is num) ? (json['ratio'] as num).toDouble() : 0.0;
          final updatedAt = json['updatedAt']?.toString();
          return {'book': b, 'ratio': ratio, 'updatedAt': updatedAt};
        }
      } catch (_) {}
      return {'book': b, 'ratio': 0.0, 'updatedAt': null};
    }).toList();

    final progressList = await Future.wait(futures);

    // 3) 완료율 계산 (ratio >= 0.99 완독으로 간주)
    final completed = progressList.where((p) => (p['ratio'] as double) >= 0.99).length;
    completedRate = (bookCount > 0) ? (completed / bookCount) : 0.0;

    // 4) 최근 읽은 책 3권 (updatedAt desc)
    progressList.sort((a, b) {
      DateTime? pa, pb;
      try {
        if (a['updatedAt'] != null) {
          pa = DateTime.parse(a['updatedAt'].toString());
        }
      } catch (_) {}

      try {
        if (b['updatedAt'] != null) {
          pb = DateTime.parse(b['updatedAt'].toString());
        }
      } catch (_) {}

      if (pa == null && pb == null) return 0;
      if (pa == null) return 1;
      if (pb == null) return -1;
      return pb.compareTo(pa); // 최신순
    });

    recent = progressList
        .where((p) => p['updatedAt'] != null)
        .take(3)
        .map<Map<String, dynamic>>((p) {
      final b = Map<String, dynamic>.from(p['book'] as Map);
      return {
        'id': b['id'],
        'title': b['title'],
        'sentences': b['sentences'], // 위에서 만든 sentences 리스트
        'results': b['results'],     // 위에서 만든, emotion 정보 등이 포함된 results 리스트
      };
    }).toList();


    if (!mounted) return;
    setState(() {
      totalBooks = bookCount;
      completionRate = completedRate.clamp(0.0, 1.0);
      recentBooks = recent;
    });
  }


  @override
  void dispose() {
    _nickCtrl.dispose();
    super.dispose();
  }

  // 최근 책의 데이터(Map)에 따라 List<AnalysisResult>로 변환
  List<AnalysisResult> _toResults(Map<String, dynamic> book) {
    // 1) 이미 results가 들어온 경우
    final r = book['results'];
    if (r is List) {
      return r.map<AnalysisResult>((e) {
        // 이미 타입이면 그대로
        if (e is AnalysisResult) return e;

        // 문자열만 온 경우
        if (e is String) {
          return AnalysisResult(
            sentence: e,
            emotion: 'neutral',     // 기본 감정
            ttsFile: '',            // 기본 TTS 경로
            effectFile: '',         // 기본 효과음 경로
          );
        }

        // Map인 경우 키를 읽어 생성
        final m = Map<String, dynamic>.from(e as Map);
        return AnalysisResult(
          sentence: (m['sentence'] ?? '').toString(),
          emotion: (m['emotion'] ?? 'neutral').toString(),
          ttsFile:  (m['ttsFile']  ?? '').toString(),
          effectFile: (m['effectFile'] ?? '').toString(),
        );
      }).toList();
    }

    // 2) sentences만 있는 경우 → 문자열 리스트를 AnalysisResult로 변환
    final sentencesAny = book['sentences'];
    if (sentencesAny is List) {
      return sentencesAny.map<AnalysisResult>((s) {
        final text = (s is String) ? s : s.toString();
        return AnalysisResult(
          sentence: text,
          emotion: 'neutral',
          ttsFile: '',
          effectFile: '',
        );
      }).toList();
    }

    return const <AnalysisResult>[];
  }

  // 닉네임 유효성 (2~16자)
  bool get _nickValid {
    final s = _nickCtrl.text.trim();
    return s.isNotEmpty && s.length >= 2 && s.length <= 16;
  }

  // 변경 여부
  bool get _nickChanged => _nickCtrl.text.trim() != _nickname;

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final prefs = await SharedPreferences.getInstance();
    final imgKey = 'profile_img_$_email';

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      await prefs.setString(imgKey, base64Encode(bytes));
      setState(() => _profileBytes = bytes);
    } else {
      await prefs.setString(imgKey, picked.path);
      setState(() => _profileFile = File(picked.path));
    }
  }

  ImageProvider? _imageProvider() {
    if (kIsWeb) {
      if (_profileBytes != null) return MemoryImage(_profileBytes!);
    } else {
      if (_profileFile != null) return FileImage(_profileFile!);
    }
    return null;
  }

  Future<void> _saveNickname() async {
    if (!_nickValid) return;
    final newNick = _nickCtrl.text.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname_$_email', newNick);
    setState(() {
      _nickname = newNick;
      _editingNick = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('닉네임이 저장되었습니다.')));
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠어요?'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                // 취소
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(height: 8),
                // 로그아웃
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('로그아웃'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('token');
    await prefs.remove('isLoggedIn');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (Route<dynamic> route) => false);
  }

  // ─────────────────────────── 통계 위젯 ───────────────────────────
  Widget _buildStatsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "내 독서 통계",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // 통계 카드
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF6),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Stat(
                  label: '총 책 수',
                  number: '$totalBooks',
                ),
                const SizedBox(
                  height: 40,
                  child: VerticalDivider(color: Colors.black12, thickness: 1),
                ),
                _Stat(
                  label: '완료율',
                  number: '${(completionRate * 100).toInt()}%',
                  numberColor: _keyColor, // ▶ 키컬러 적용
                ),
              ],
            ),
          ),

          const Divider(height: 32),

          const Text(
            "최근 읽은 책",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (recentBooks.isEmpty)
            const Text("최근 읽은 책이 없어요.", style: TextStyle(color: Colors.grey))
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentBooks.length,
                itemBuilder: (_, i) {
                  final book = recentBooks[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReaderPage(
                            title: (book['title'] ?? '').toString(),
                            results: _toResults(book), // 여기서 변환 사용
                            bookId:
                            (book['id'] ?? book['bookId'] ?? '').toString(),
                            userId: _email,
                            apiBaseUrl: Config.apiBaseUrl,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book,
                              size: 36, color: Colors.grey[600]),
                          const SizedBox(height: 6),
                          Text(
                            (book['title'] ?? '').toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  // ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white70,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 상단 바
            Container(
              height: 70,
              color: const Color(0xDDB3C39C),
              child: Center(
                child: Image.asset('assets/logos/logo_horizontal.png', height: 40),
              ),
            ),
            const SizedBox(height: 36),

            // 프로필 사진 + 카메라 아이콘
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: CircleAvatar(
                      radius: 90,
                      backgroundColor: Colors.white,
                      backgroundImage: _imageProvider(),
                      child: _imageProvider() == null
                          ? Icon(Icons.person, size: 64, color: Colors.grey[400])
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: InkWell(
                      onTap: _pickProfileImage,
                      borderRadius: BorderRadius.circular(24),
                      child: CircleAvatar(
                        backgroundColor: _keyColor,
                        radius: 20,
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 닉네임 수정 UI (입력 + 체크/취소 아이콘)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _editingNick
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _nickCtrl,
                      textAlign: TextAlign.center,
                      maxLength: 16,
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '닉네임 (2~16자)',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    tooltip: '저장',
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: (_nickValid && _nickChanged)
                        ? _saveNickname
                        : null,
                  ),
                  IconButton(
                    tooltip: '취소',
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _nickCtrl.text = _nickname;
                        _editingNick = false;
                      });
                    },
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _nickname,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => setState(() => _editingNick = true),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Text(_email, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),

            // 통계 섹션
            _buildStatsSection(context),

            const SizedBox(height: 12),

            // 로그아웃 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: _confirmLogout,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.grey[300],
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('로그아웃'),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// 통계 카드 안에서 쓰는 작은 위젯
class _Stat extends StatelessWidget {
  final String label;
  final String number;
  final Color? numberColor;

  const _Stat({
    required this.label,
    required this.number,
    this.numberColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          number,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: numberColor, // null이면 기본 텍스트 색
          ),
        ),
      ],
    );
  }
}