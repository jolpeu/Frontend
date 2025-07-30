import 'package:flutter/material.dart';
import 'dart:async';

class ReaderPage extends StatefulWidget {
  final String title;
  final String content;

  const ReaderPage({required this.title, required this.content, super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late List<String> _sentences;
  bool _showUI = true;
  Timer? _hideTimer;
  final ScrollController _scrollController = ScrollController();
  bool _isPlaying = false;
  double _Progress = 0.0;

  @override
  void initState() {
    super.initState();
    _sentences = widget.content.split(RegExp(r'(?<=[.?!])\s+')); // 문장 단위 분리
    _startHideTimer();

    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final progress = (offset / max).clamp(0.0, 1.0);

    setState(() {
      _Progress = progress;
    });
  }

  void _togglePlayPause(){
    setState(() {
      _isPlaying = !_isPlaying;
    });

    // TTS 시작/정지 기능 연결 예정
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();

    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        _showUI = false;
      });
    });
  }

  void _toggleUIVisibility() {
    setState(() => _showUI = !_showUI);
    if (_showUI) _startHideTimer();
  }

  void _onUserInteraction() {
    if (!_showUI) {
      setState(() => _showUI = true);
    }
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(

      onTap: _toggleUIVisibility,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // 상단바
            AnimatedOpacity(
              opacity: _showUI ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: _buildTopBar(),
            ),

            // 본문 스크롤
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scroll) {
                  _onUserInteraction();
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _sentences.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 20),
                      child: Text(
                        _sentences[index],
                        style: TextStyle(fontSize: 18, height: 1.5),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 숨김 UI
            AnimatedOpacity(
              opacity: _showUI ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: _buildBottomBar(_Progress),
            ),
          ],
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
          child: Center(
            child: Image.asset(
              'assets/logos/logo_horizontal.png',
              height: 40,
            ),
          ),
        ),
        Container(
          color: Color(0xFFDEE5D4),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(double progress) {
    return Container(
      color: Colors.white54,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: progress),
          SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: Colors.grey[600])),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(onPressed: (){}, /*_goToPreviousPage,*/ icon: Image.asset('assets/icons/icon_previous.png', height: 40,)),
              IconButton(onPressed: _togglePlayPause,
                icon: Image.asset(_isPlaying ? 'assets/icons/icon_play.png' : 'assets/icons/icon_pause.png',
                  height: 50,),
              ),
              IconButton(onPressed: (){},/*_goToNextPage,*/ icon: Image.asset('assets/icons/icon_next.png', height: 40,)),
            ],
          )
        ],
      ),
    );
  }
}
