// ReaderPage.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grad_front/models/analysis_result.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:grad_front/config.dart';

// Reader Page
class ReaderPage extends StatefulWidget {
  final String title;
  final List<AnalysisResult> results;

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

  bool _isPlaying = false;
  double _progress = 0.0;
  double _savedOffset = 0.0;
  Timer? _debounceTimer;


  // 서버 통신: 진행률 API

  // Get /reading-progress
  Uri get _getProgressUri => Uri.parse(
      '${widget.apiBaseUrl}/reading-progress')
      .replace(queryParameters: {
    'userId': widget.userId,
    'bookId': widget.bookId,
  });


  // Put /reading-progress
  Uri get _putProgressUri => Uri.parse(
      '${widget.apiBaseUrl}/reading-progress');


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
      if(res.statusCode == 200 && res.body.isNotEmpty){
        final body = utf8.decode(res.bodyBytes);
        final map = jsonDecode(body);
        if(map is Map<String, dynamic>) return map;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _upsertProgress({
    required double offset,
    required double ratio,
  }) async {
    if (_token == null) return;
    try {
      final res = await http.put(
        _putProgressUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'userId': widget.userId,
          'bookId': widget.bookId,
          'offset': offset,
          'ratio': ratio,
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

  Future<void> _restoreFromServer() async {
    final data = await _fetchProgress();
    if (!mounted || data == null) return;
    final hasOffset = data['offset'] is num;
    final hasRatio  = data['ratio'] is num;
    if (hasRatio) {
      setState(() => _progress = (data['ratio'] as num).toDouble().clamp(0.0, 1.0));
    }
    if (hasOffset) {
      _savedOffset = (data['offset'] as num).toDouble();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final max = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(_savedOffset.clamp(0.0, max));
      });
    }
  }

  final _ttsPlayer = AudioPlayer();
  final _sfxPlayer = AudioPlayer();
  bool _audioReady = false;
  List<AnalysisResult> _analysis = [];
  int _currentIndex = 0;


  // --------- sfx 옵션
  bool _sfxEnabled = true;
  double _sfxVolume = 0.35;
  int _lastEffectIndex = -1;

  String _buildMediaUrl(String base, String dir, String fileName){
    final encoded = Uri.encodeComponent(fileName);
    // ⭐️ 이 부분을 수정했습니다. '/audio/' 경로를 제거했습니다.
    return '$base/$dir/$encoded';
  }


  // 오디오 초기화
  Future<void> _initAudio() async {
    try{
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());



      _analysis = widget.results;

      // 파일명 -> url로 변경
      final ttsChildren = _analysis
          .where((r) => r.ttsFile.isNotEmpty)
          .map((r) => AudioSource.uri(
        Uri.parse(_buildMediaUrl("http://127.0.0.1:8000", 'tts', r.ttsFile)),
      )).toList();

      for (var r in _analysis) {
        if (r.ttsFile.isNotEmpty) {
          final url = _buildMediaUrl("http://127.0.0.1:8000", 'tts', r.ttsFile);
          debugPrint('TTS URL: $url');
        }
      }

      if (ttsChildren.isEmpty) {
        throw Exception('재생 가능한 TTS가 없습니다.');
      }

      final playlist = ConcatenatingAudioSource(children: ttsChildren);
      await _ttsPlayer.setAudioSource(playlist, preload: true);

      _ttsPlayer.currentIndexStream.listen((i) {
        if (i == null) return;
        setState(() => _currentIndex = i);
        _maybePlayEffectIfNeeded(i);
      });

      _ttsPlayer.playerStateStream.listen((s) {
        setState(() => _isPlaying = s.playing);
      });

      await _sfxPlayer.setVolume(_sfxVolume);
      setState(() => _audioReady = true);
    } catch(e){
      debugPrint('오디오 초기화 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오디오 초기화 실패: $e')),
        );
      }
    }
  }


  Future<void> _playEffectOnce(String url) async {
    try {
      await _sfxPlayer.setUrl(url);
      await _sfxPlayer.play();
    } catch (e) {
      debugPrint('효과음 재생 실패: $e');
    }
  }

  Future<void> _maybePlayEffectIfNeeded(int index) async {
    if (!_sfxEnabled) return;
    if (index < 0 || index >= _analysis.length) return;
    final effectFile = _analysis[index].effectFile;
    if (effectFile.isEmpty) return;
    final pos = _ttsPlayer.position;
    final isAtStart = pos <= const Duration(milliseconds: 250);
    if (_lastEffectIndex == index && !isAtStart) return;
    _lastEffectIndex = index;
    // ⭐️ 이 부분을 수정했습니다. '/audio/' 경로를 제거했습니다.
    final effectUrl = _buildMediaUrl("http://127.0.0.1:8000", 'effects', effectFile);
    await _sfxPlayer.setVolume(_sfxVolume);
    await _playEffectOnce(effectUrl);
  }

  // 라이프 사이클
  @override
  void initState() {
    super.initState();
    _results = widget.results;
    _startHideTimer();
    _scrollController.addListener(_handleScroll);
    SharedPreferences.getInstance().then((prefs) {
      _token = prefs.getString('token');
      _restoreFromServer();
      _initAudio();
    });
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
    _sfxPlayer.dispose();
    _ttsPlayer.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final progress = (offset / (max == 0 ? 1 : max)).clamp(0.0, 1.0);
    setState(() => _progress = progress);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), (){
      _upsertProgress(offset: offset, ratio: progress);
    });
  }

  Future<void> _saveNow() async {
    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    await _upsertProgress(offset: offset, ratio: _progress);
  }

  // ---------------- 🔊 플레이어 컨트롤 ----------------
  Future<void> _playFrom(int index) async {
    if (!_audioReady) return;
    _lastEffectIndex = -1;
    await _ttsPlayer.seek(Duration.zero, index: index);
    await _maybePlayEffectIfNeeded(index);
    await _ttsPlayer.play();
  }

  Future<void> _prev() async {
    if (!_audioReady) return;
    await _ttsPlayer.seekToPrevious();
  }

  Future<void> _next() async {
    if (!_audioReady) return;
    await _ttsPlayer.seekToNext();
  }

  void _togglePlayPause() {
    if (!_audioReady) return;
    if (_ttsPlayer.playing) {
      _ttsPlayer.pause();
    } else {
      _maybePlayEffectIfNeeded(_currentIndex);
      _ttsPlayer.play();
    }
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
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveNow();
        return true;
      },
      child: GestureDetector(
        onTap: _toggleUIVisibility,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              AnimatedOpacity(
                opacity: _showUI ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: _buildTopBar(),
              ),

              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (_) {
                    _onUserInteraction();
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
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

  Widget _buildTopBar() {
    return Column(
      children: [
        Container(
          height: 70,
          color: Color(0xDDB3C39C),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: Image.asset('assets/icons/icon_arrowback.png', height: 28,),
                onPressed: () async {
                  await _saveNow();
                  if(mounted){
                    Navigator.pop(context, _progress);
                  }
                },
              ),

              const Spacer(),
              Image.asset('assets/logos/logo_horizontal.png', height: 40, ),
              const Spacer(flex: 2),
            ],
          ),
        ),
        Container(
          color: Color(0xFFDEE5D4),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text( widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white54,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress),
          SizedBox(height: 4),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [

              IconButton(
                onPressed: () {},
                icon: Image.asset('assets/icons/icon_previous.png', height: 40),
              ),

              IconButton(
                onPressed: _togglePlayPause,
                icon: Image.asset(
                  _isPlaying ? 'assets/icons/icon_pause.png' : 'assets/icons/icon_play.png',
                  height: 50,
                ),
              ),

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