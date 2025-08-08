import 'package:flutter/material.dart';
import 'dart:async';

class ReaderPage extends StatefulWidget {
  final String title;
  final List<String> sentences;

  const ReaderPage({
    Key? key,
    required this.title,
    required this.sentences,
  }) : super(key: key);

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late List<String> _sentences;
  bool _showUI = true;
  Timer? _hideTimer;
  final ScrollController _scrollController = ScrollController();
  bool _isPlaying = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _sentences = widget.sentences;
    _startHideTimer();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final progress = (offset / (max == 0 ? 1 : max)).clamp(0.0, 1.0);
    setState(() => _progress = progress);
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
    // TODO: 연동할 TTS 기능 구현
  }

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
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                  itemCount: _sentences.length,
                  itemBuilder: (_, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        _sentences[index],
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
