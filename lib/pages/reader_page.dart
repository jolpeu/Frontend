import 'package:flutter/material.dart';

/// 이북 리더 화면: 텍스트 보기, 페이지 넘기기, TTS 제어 UI 포함
class ReaderPage extends StatefulWidget{
  final String title;   // 책 제목
  final String content; // 전체 책 내용 (텍스트)

  const ReaderPage ({required this.title, required this.content, super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage>{
  int _currentPage = 0;         // 현재 페이지 인덱스
  late List<String> _pages;     // 나뉘어진 페이지 목록
  bool _isPlaying = false;      // TTS 재생 상태
  double _progress = 0.0;       // 진행률 (아직 사용 안함)

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // 텍스트를 여러 페이지로 분할
    _pages = _splitIntoPages(widget.content);
  }

  /// 긴 텍스트를 페이지 단위로 분리
  List<String> _splitIntoPages(String text) {
    const charsPerPage = 800;  // 한 페이지에 보여줄 문자 수 / 수정 가능
    List<String> result = [];
    for (int i = 0; i < text.length; i += charsPerPage){
      result.add(text.substring(i, i + charsPerPage > text.length ? text.length : i + charsPerPage));
    }
    return result;
  }

  /// 재생/일시정지 버튼 토글
  void _togglePlayPause(){
    setState(() {
      _isPlaying = !_isPlaying;
    });

    // TTS 시작/정지 기능 연결 예정
  }

  /// 이전 페이지로 이동
  void _goToPreviousPage(){
    if(_currentPage > 0){
      setState(() {
        _currentPage--;
      });
    }
  }

  /// 다음 페이지로 이동
  void _goToNextPage(){
    if(_currentPage < _pages.length - 1){
      setState(() {
        _currentPage++;
      });
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.yellow[50],
      appBar: AppBar(
        backgroundColor: Colors.yellow[50],
        elevation: 0,
        centerTitle: true,
        title: Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _pages[_currentPage],
            style: TextStyle(fontSize: 18, height: 1.6),
          ),
      ),
      bottomNavigationBar: Container(
        color: Colors.yellow[100],
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: (_currentPage + 1) / _pages.length),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(onPressed: _goToNextPage, icon: Icon(Icons.skip_previous)),
                IconButton(
                    onPressed: _togglePlayPause,
                    icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                    iconSize: 40,
                ),
                IconButton(onPressed: _goToNextPage, icon: Icon(Icons.skip_next)),
              ],
            )
          ],
        ),
      ),
    );
  }
}