import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grad_front/models/analysis_result.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class ReaderPage extends StatefulWidget{
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
  })  : super(key: key);

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage>{
  String? _token;
  late List<AnalysisResult> _results;
  bool _showUI = true;
  Timer? _hideTimer;
  final ScrollController _scrollController = ScrollController();

  bool _isPlaying = false;
  double _progress = 0.0;
  double _savedOffset = 0.0;
  Timer? _debounceTimer;

  late final List<GlobalKey> _itemKeys;

  late StreamSubscription<int?> _currentIndexSubscription;
  late StreamSubscription<PlayerState> _playerStateSubscription;

  // -------------- 서버 통신 함수 --------------
  // Get /reading-progress 엔드포인트 URI
  Uri get _getProgressUri => Uri.parse(
    '${widget.apiBaseUrl}/reading-progress'
  ).replace(queryParameters: {
    'userId': widget.userId,
    'bookId': widget.bookId,
  });


  // Put /reading-progress 엔드포인트 URI
  Uri get _putProgressUri => Uri.parse(
    '${widget.apiBaseUrl}/reading-progress'
  );

  // 서버에서 진행률 데이터를 가져오는 함수
  Future<Map<String, dynamic>?> _fetchProgress() async {
    if(_token == null) return null;
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
        debugPrint('Data received from server: $map');
        if(map is Map<String, dynamic>) return map;
      }
    } catch (_){}
    return null;
  }

  // 서버에 진행률 업데이트하는 함수
  Future<void> _upsertProgress({
    required double offset,   // 스크롤 오프셋
    required double ratio,    // 진행률
  }) async {
    if(_token == null) return;

    debugPrint('Saving progress offset: $offset, ratio: $ratio');

    try{
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
          'currentIndex': _currentIndex,
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

  // 서버에서 저장된 진행률 복원하는 함수
  Future<void> _restoreFromServer() async {
    final data = await _fetchProgress();
    if(!mounted || data == null) return;
    final hasOffset = data['offset'] is num;
    final hasRatio = data['ratio'] is num;
    final hasIndex = data['currentIndex'] is num;

    // 진행률이 있으면 업데이트
    if(hasRatio){
      setState(() => _progress = (data['ratio'] as num).toDouble().clamp(0.0, 1.0));
    }

    // 스크롤 오프셋이 있으면 복원
    if(hasOffset){
      _savedOffset = (data['offset'] as num).toDouble();

      // 프레임이 모두 렌더링된 후 스크롤 위치 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(!_scrollController.hasClients) return;
        final max = _scrollController.position.maxScrollExtent;

        // jumpTo를 이용해 즉시 스크롤 위치를 복원
        _scrollController.jumpTo(_savedOffset.clamp(0.0, max));
      });
    }

    // 마지막으로 읽은 문장 인덱스가 있으면 복원
    if(hasIndex){
      final int restoredIndex = (data['currentIndex'] as num).toInt();
      await _ttsPlayer.seek(Duration.zero, index: restoredIndex);
      setState(() {
        _currentIndex = restoredIndex;
      });
    }
  }

  // -------------- 오디오 플레이어 로직 --------------
  final _ttsPlayer = AudioPlayer();
  final _sfxPlayer = AudioPlayer();
  bool _audioReady = false;
  List<AnalysisResult> _analysis = [];
  int _currentIndex = 0;        // 현재 재생 중인 문장 인덱스
  String baseUrl = "http://127.0.0.1:8000";

  bool _sfxEnabled = true;
  double _sfxVolume = 0.2;
  int _lastEffectIndex = -1;      // 마지막으로 재생된 효과음의 인덱스

  // 미디어 파일 URL을 생성하는 함수
  String _buildMediaUrl(String base, String dir, String fileName){
    final encoded = Uri.encodeComponent(fileName);
    return '$base/$dir/$encoded';
  }

  // 오디오 플레이어를 초기화하는 함수
  Future<void> _initAudio() async{
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

      _analysis = widget.results;

      // TTS 오디오 파일명 -> URL로 변경하여 AudioSource 목록 생성
      final ttsList = _analysis
      .where((r) => r.ttsFile.isNotEmpty)
      .map((r) => AudioSource.uri(
        Uri.parse(_buildMediaUrl(baseUrl, 'tts', r.ttsFile)),
      )).toList();

      if(ttsList.isEmpty){
        throw Exception('재생 가능한 TTS가 없습니다.');
      }

      final playlist = ConcatenatingAudioSource(children: ttsList);
      await _ttsPlayer.setAudioSource(playlist, preload: true);

      // 현재 재생 중인 인덱스 변화를 감지하여 _currentIndex 업데이트
      _ttsPlayer.currentIndexStream.listen((i){
        if(i == null) return;
        setState(() => _currentIndex = i);
        _scrollToCurrentSentence();
      });
      
      _ttsPlayer.playerStateStream.listen((s) {
        setState(() => _isPlaying = s.playing);
      });

      _currentIndexSubscription = _ttsPlayer.currentIndexStream.listen((i){
        if(i == null) return;
        setState(() => _currentIndex = i);
        _scrollToCurrentSentence();
      });

      _playerStateSubscription = _ttsPlayer.playerStateStream.listen((s){
        setState(() => _isPlaying = s.playing);
      });

      await _sfxPlayer.setVolume(_sfxVolume);
      setState(() => _audioReady = true);
    } catch(e){
      debugPrint('오디오 초기화 실패: $e');
      
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오디오 초기화 실패: $e'))
        );
      }
    }
  }

  // 효과음 파일 한 번 재생하는 함수
  Future<void> _playEffectOnce(String url) async {
    try{
      await _sfxPlayer.setUrl(url);
      await _sfxPlayer.play();
    } catch(e){
      debugPrint('효과음 재생 실패: $e');
    }
  }

  // 현재 문장에 맞는 효과음이 있으면 재생하는 함수
  Future<void> _playEffect(int index) async {
    if (!_sfxEnabled) return;
    if (index < 0 || index >= _analysis.length) return;
    final effectFile = _analysis[index].effectFile;
    if (effectFile.isEmpty) return;   // 효과음 파일 없으면 종료
    final pos = _ttsPlayer.position;
    final isAtStart = pos <= const Duration(milliseconds: 250);
    if(_lastEffectIndex == index && !isAtStart) return;   //  중복 재생 방지
    _lastEffectIndex = index;
    final effectUrl = _buildMediaUrl(baseUrl, 'effects', effectFile);
    await _sfxPlayer.setVolume(_sfxVolume);
    await _playEffectOnce(effectUrl);
  }

  // -------------- 라이프 사이클 및 이벤트 핸들러 --------------

  // 위젯 생성 시 호출되는 함수
  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(widget.results.length, (index) => GlobalKey());
    _results = widget.results;
    _startHideTimer();    // UI 숨김 타이머 시작
    _scrollController.addListener(_handleScroll);   // 스크롤 리스너 등록
    SharedPreferences.getInstance().then((prefs){
      _token = prefs.getString('token');
      _restoreFromServer();
      _initAudio();
    });
  }

  // 위젯이 소멸될 때 호출되는 함수
  @override
  void dispose(){
    _hideTimer?.cancel();
    _debounceTimer?.cancel();
    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;

    _currentIndexSubscription.cancel();
    _playerStateSubscription.cancel();

    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _sfxPlayer.dispose();
    _ttsPlayer.dispose();
    super.dispose();
  }

  // 스크롤 시 진행률을 계산하고 서버에 저장하는 함수
  void _handleScroll(){
    if(!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final progress = (offset / (max == 0 ? 1: max)).clamp(0.0, 1.0);
    setState(() => _progress = progress);   // 진행률 UI 업데이트
    _debounceTimer?.cancel();

    // 0.5초 디바운스: 스크롤이 멈췄을 때만 서버에 저장하도록 함
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _upsertProgress(offset: offset, ratio: progress);
    });
  }

  // 현재 진행률을 강제로 저장하는 함수
  Future<void> _saveNow() async {
    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    await _upsertProgress(offset: offset, ratio: _progress);
  }

  // -------------- mp3 플레이어 컨트롤 --------------

  // 특정 인덱스부터 오디오를 재생하는 함수
  Future<void> _playFrom(int index) async {
    if(!_audioReady) return;
    _lastEffectIndex = -1;
    await _ttsPlayer.seek(Duration.zero, index: index);
    _playEffect(index);
    await _ttsPlayer.play();
  }

  // 이전 문장으로 이동하는 함수
  Future<void> _prev() async {
    if(!_audioReady) return;
    await _ttsPlayer.seekToPrevious();
    _playEffect(_currentIndex);
  }

  // 다음 문장으로 이동하는 함수
  Future<void> _next() async {
    if(!_audioReady) return;
    await _ttsPlayer.seekToNext();
    _playEffect(_currentIndex);
  }

  // tts 재생/일시정지
  void _togglePlayPause() {
    if(!_audioReady) return;
    if(_ttsPlayer.playing) {
      _ttsPlayer.pause();
      _sfxPlayer.pause();
    } else {
      _playEffect(_currentIndex);
      _ttsPlayer.play();
      _sfxPlayer.play();
    }
  }

  // 효과음 재생/일시정지
  void _toggleSfx() async {
   setState(() {
     _sfxEnabled = !_sfxEnabled;
   });

   if(_sfxEnabled){
     await _sfxPlayer.setVolume(_sfxVolume);
   } else {
     await _sfxPlayer.setVolume(0.0);
   }
  }

  // 상/하단 UI를 숨기는 타이머 시작 함수
  void _startHideTimer(){
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: 3), (){
      setState(() => _showUI = false);
    });
  }

  // UI 가시성을 토글하는 함수
  void _toggleUIVisibility() {
    setState(() => _showUI = !_showUI);
    if(_showUI) _startHideTimer();
  }

  // 현재 재생하는 문장으로 자동 스크롤하는 함수
  Future<void> _scrollToCurrentSentence() async {
    final key = _itemKeys[_currentIndex];
    final context = key.currentContext;

    if(context == null) return;

    await Scrollable.ensureVisible(
        context,
        alignment: 0.4,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }

  @override
  Widget build(BuildContext context){
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async{
        if(didPop) return;
        await _saveNow();
        if(mounted){
          final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
          Navigator.of(context).pop({'progress': _progress, 'offset':offset});
        }
      },

      child: GestureDetector(
        // 화면 탭 시에만 UI 보임
        onTap: _toggleUIVisibility,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // 텍스트 스크롤 화면
              ListView.builder(
                  controller: _scrollController,
                  itemCount: _results.length,
                  itemBuilder: (_, index) {
                    final isCurrent = index == _currentIndex;
                    return GestureDetector(
                      onTap: () {
                        _playFrom(index);
                      },
                      child: Padding(
                        key: _itemKeys[index],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Text(
                          _results[index].sentence,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.5,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight
                                .normal,
                            backgroundColor: isCurrent ? Colors.lime : Colors
                                .transparent,
                          ),
                        ),
                      ),
                    );
                  }
              ),
              
              // 상단바 UI
              AnimatedOpacity(
                  opacity: _showUI ? 1.0 : 0.0, 
                  duration: Duration(milliseconds: 300),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _buildTopBar(),
                ),
              ),
              
              // 하단바 UI
              AnimatedOpacity(
                opacity: _showUI ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildBottomBar(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTopBar(){
    return Column(
      children: [
        Container(
          height: 70,
          color: Color(0xDDB3C39C),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                  onPressed: () async {
                    await _saveNow();
                    if(mounted){
                      final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
                      Navigator.pop(context, {'progress':_progress, 'offset': offset});
                    }
                  }, 
                  icon: Image.asset('assets/icons/icon_arrowback.png', height: 28,)
              ),
              const Spacer(flex: 2),
              Image.asset('assets/logos/logo_horizontal.png', height: 40,),
              const Spacer(flex: 2),
            ],
          ),
        ),
        Container(
          color: Color(0xFFDEE5D4),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
            ],
          ),
        )
      ],
    );
  }
  
  Widget _buildBottomBar(){
    return Container(
      color: Colors.white54,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
                  onPressed: _toggleSfx,
                  icon: _sfxEnabled ? Image.asset('assets/icons/icon_volume-high.png', height: 36) : Image.asset('assets/icons/icon_volume-slash.png', height: 36,),
                ),
          ),
          LinearProgressIndicator(
            value: _progress,
            color: Colors.lightGreen,
            backgroundColor: Colors.grey.shade300,
          ),
          SizedBox(height: 4,),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                  onPressed: _prev,
                  icon: Image.asset('assets/icons/icon_previous.png', height: 40,)),
              IconButton(
                  onPressed: _togglePlayPause,
                  icon: Image.asset(
                    _isPlaying ? 'assets/icons/icon_pause.png' : 'assets/icons/icon_play.png',
                    height: 50,
                  )),
              IconButton(
                  onPressed: _next,
                  icon: Image.asset('assets/icons/icon_next.png', height: 40,))
            ],
          )
        ],
      ),
    );
  }
}