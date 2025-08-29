import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grad_front/models/analysis_result.dart';

// Reader Page
// 스크롤형 이북 리더 화면
// 상/하단바 UI는 일정 시간 후 사라짐(터치 시 생성)
// 문장 리스트(ListView)를 스크롤해서 읽는 구조
class ReaderPage extends StatefulWidget {
  final String title;                 // 책 제목 - 화면 상단 표기
  final List<AnalysisResult> results;       // 문장 단위로 나눠진 텍스트 목록

  final String bookId;
  final String userId;
  final String? apiBaseUrl;


  const ReaderPage({
    Key? key,
    required this.title,
    required this.results,
    required this.bookId,
    required this.userId,
    required this.apiBaseUrl,

  }) : super(key: key);

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  String? _token;
  late List<AnalysisResult> _results;
  bool _showUI = true;
  Timer? _hideTimer;
  final ScrollController _scrollController = ScrollController();

  bool _isPlaying = false;      // TTS 재생 상태(재생/일시정지 토글)
  double _progress = 0.0;       // 독서 진행률 - 하단바
  double _savedOffset = 0.0;
  Timer? _debounceTimer;


  // 서버 통신: 진행률 API

  // Get /reading-progress
  // - 특정 유저(userId)가 특정 책(bookId)을 어디까지 읽었는지 조회
  // - 쿼리 스트링으로 userId, bookId를 넘김

  // EX) GET http://localhost:8080/reading-progress?userId=XXX&bookId=XXX
  Uri get _getProgressUri => Uri.parse(
    '${widget.apiBaseUrl}/reading-progress')
      .replace(queryParameters: {
        'userId': widget.userId,
        'bookId': widget.bookId,
  });


  // Put /reading-progress
  // - 진행 상황 저장
  // - JSON 바디로 userId, bookId, offset, ratio, updateAt 전송
  // offset: 스크롤 위치, ratio: 전체 중 몇 %
  // EX) PUT http://localhost:8080/reading-progress
  Uri get _putProgressUri => Uri.parse(
    '${widget.apiBaseUrl}/reading-progress');


  // 서버에서 프론트로 진행률 불러오기(없으면 null)
  // GET /reading-progress?userId=xxx&bookId=xxx
  // 성공 시 200 JSON 객체 기대
  Future<Map<String, dynamic>?> _fetchProgress() async {
    if (_token == null) return null;
    try {
      final res = await http.get(
        _getProgressUri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      // 200이고 바디가 비어있지 않으면 JSON 파싱
      if(res.statusCode == 200 && res.body.isNotEmpty){
        final map = jsonDecode(res.body);
        if(map is Map<String, dynamic>) return map;
      }
    } catch (_) {}
    return null;
  }

  // 서버에 진행률 저장/업데이트(업서트)
  // PUT /reading-progress
  Future<void> _upsertProgress({
    required double offset,
    required double ratio,
}) async {
    if (_token == null) return;

    try {
      final res = await http.put(
        _putProgressUri,
        // 헤더에 인증 토큰 추가
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'userId': widget.userId,
          'bookId': widget.bookId,
          'offset': offset,         // 스크롤 위치
          'ratio': ratio,           // 진행률
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );
      if(res.statusCode != 200){
        debugPrint('진행률 업서트 실패: ${res.statusCode} ${res.body}');
      }
    } catch(e){
        debugPrint('진행률 업서트 에러: $e');
    }
  }

  // 앱 시작 시 서버 진행률(스크롤) 복원
  // 페이지가 그려지고 나서 저장된 offset으로 점프
  Future<void> _restoreFromServer() async {
    final data = await _fetchProgress();
    if(!mounted) return;

    if(data != null && data['offset'] is num){
      _savedOffset = (data['offset'] as num).toDouble();
      WidgetsBinding.instance.addPostFrameCallback((_){
        final max = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(_savedOffset.clamp(0.0, max));
      });
    }
  }

  // 라이프 사이클
  @override
  void initState() {
    super.initState();
    _results = widget.results;
    _startHideTimer();
    _scrollController.addListener(_handleScroll);   // 스크롤 시 진행률 계산하는 리스너
    _restoreFromServer();
    SharedPreferences.getInstance().then((prefs) {
      _token = prefs.getString('token');
      // 토큰을 가져온 후에 서버에서 진행률 복원
      _restoreFromServer();
    });
  }



  // 스크롤 리스너 - 스크롤 위치로부터 진행률 계산해 상태 반영
  // 사용자가 스크롤할 때마다 offset/ratio 계산
  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;   // 끝까지 내렸을 때의 최대 스크롤 범위
    final offset = _scrollController.offset;                  // 현재 스크롤 오프셋(위에서 얼마나 내려왔는지)
    final progress = (offset / (max == 0 ? 1 : max)).clamp(0.0, 1.0);   // 0으로 나누기 방지
    setState(() => _progress = progress);                     // 진행률 상태 업데이트

    // 디바운스
    // 스크롤 멈춘 뒤 500ms 지나면 저장
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), (){
      _upsertProgress(offset: offset, ratio: progress);
    });
  }

  // 페이지 닫기 직전에는 즉시 저장 한번 더
  Future<void> _saveNow() async {
    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    await _upsertProgress(offset: offset, ratio: _progress);
  }

  // 하단 재생/일시정지 버튼 토글 & TTS
  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
    // TODO: 연동할 TTS 기능 구현
  }


  // 상/하단바 숨기는 타이머 - 3초 뒤에 UI 숨김
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: 3), () {
      setState(() => _showUI = false);
    });
  }

  void _toggleUIVisibility() {
    setState(() => _showUI = !_showUI);
    if (_showUI) _startHideTimer();
  }

  void _onUserInteraction() {
    if (!_showUI) setState(() => _showUI = true);
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _debounceTimer?.cancel();

    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    Future(() async {
      try {
        await _upsertProgress(offset: offset, ratio: _progress);
      } catch (_) {}
    });


    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveNow();
        return true;
      },
      child: GestureDetector(
        // 탭하면 상/하단바 UI
        onTap: _toggleUIVisibility,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // 상단바 - 로고 + title
              // 페이드 인/아웃으로 UI 자동 숨김/표시
              AnimatedOpacity(
                opacity: _showUI ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: _buildTopBar(),
              ),

              // 본문: 문장 리스트(스크롤)
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (_) {
                    _onUserInteraction();
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,    // 진행률 계산 컨트롤러
                    itemCount: _results.length,
                    itemBuilder: (_, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(
                          _results[index].sentence,
                          style: TextStyle(fontSize: 18, height: 1.5),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 하단바 - 진행률, 재생/일시정지
              AnimatedOpacity(
                opacity: _showUI ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: _buildBottomBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 상단바
  // 1. 로고
  // 2. 제목
  Widget _buildTopBar() {
    return Column(
      children: [
        // 상단 로고
        Container(
          height: 70,
          color: Color(0xDDB3C39C),
          child: Center(
            child: Image.asset(
              'assets/logos/logo_horizontal.png',
              height: 40,
            ),
          ),
        ),

        // 제목
        Container(
          color: Color(0xFFDEE5D4),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 책 제목
              Text(
                widget.title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // 하단바
  Widget _buildBottomBar() {
    return Container(
      color: Colors.white54,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 진행률 바
          LinearProgressIndicator(value: _progress),
          SizedBox(height: 4),

          // 진행률 텍스트(%)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 10),

          // 플레이어 컨트롤
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [

              // 이전 문장
              IconButton(
                onPressed: () {},
                icon: Image.asset('assets/icons/icon_previous.png', height: 40),
              ),

              // 재생/일시정지
              IconButton(
                onPressed: _togglePlayPause,
                icon: Image.asset(
                  _isPlaying ? 'assets/icons/icon_pause.png' : 'assets/icons/icon_play.png',
                  height: 50,
                ),
              ),

              // 다음 문장
              IconButton(
                onPressed: () {},
                icon: Image.asset('assets/icons/icon_next.png', height: 40),
              ),
            ],
          )
        ],
      ),
    );
  }
}
