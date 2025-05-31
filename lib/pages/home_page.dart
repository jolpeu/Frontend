import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:grad_front/pages/library_page.dart';
import 'my_page.dart';
import 'dart:io';


/// 홈페이지 전체 구조 정의
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  List<Map<String, dynamic>> _books = [];

  @override
  Widget build(BuildContext context){
    
    // 화면 전환용 페이지 리스트 - 홈, 서재, 마이페이지
    final List<Widget> _pages = [
      LibraryPage(books: _books), // 서재
      HomeMainContent(
        onUpload: (newBook){  
          setState(() {
            _books.add(newBook);  // 새 책 추가
            _currentIndex = 0;    // 책 추가하면 서재 페이지로 전환
          });
        }
      ),
      MyPage(),   // 마이페이지
    ];

    return Scaffold(
      body:
      IndexedStack(
        index: _currentIndex,
        children: _pages,   // _currentIndex에 맞는 페이지 보여줌
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index){
          setState(() {
            _currentIndex = index;  //  하단바 전환
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: '서재',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}

/// 홈 화면 컨텐츠 - PDF 업로드 버튼
class HomeMainContent extends StatelessWidget {
  final Function(Map<String, dynamic>) onUpload;    // 업로드 콜백 함수

  const HomeMainContent({required this.onUpload});

  
  /// PDF 파일 선택 및 업로드 처리
  Future<void> _pickPdf(BuildContext context) async {
    final params = OpenFileDialogParams(
      dialogType: OpenFileDialogType.document,
      sourceType: SourceType.photoLibrary,
      fileExtensionsFilter: ['pdf'],    // PDF만 허용  
    );

    final filePath = await FlutterFileDialog.pickFile(params: params);

    if (filePath != null) {
      final file = File(filePath);
      final fileName = file.uri.pathSegments.last;

      // 업로드 확인 팝업
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: Text('$fileName 파일을 업로드하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // 팝업 닫고 다시 선택
                  child: Text('다시 선택'),
                ),
                TextButton(
                  onPressed: () {
                    final newBook = {
                      'title': fileName.replaceAll('.pdf', ' '),
                      'status': '읽고 있는 책',
                      'progress': 0.0,
                      // 더미 텍스트
                      'text':  '''  
“(중략)모두가 바쁜 평가 기간임에도 학급 내 분리 배출과 청소 같은 곳은 일도 마다하지 않는 학생입니다. 다만…”

지난 학기 성적표를 읽어 내려가던 하늘이 멈칫했다.
“다만 전하는 학생은 좋은 성적을 받기 위해 과도하게 집착하는 경향이 있습니다. 과한 성적 집착은 학생들로 하여금 긍정적이고 자발적인 성취 결과를 내지 못할 수 있으므로 전하는 학생은 이에 대한 각별한 유의가 필요합니다.”

평가를 마치 읽은 하늘은 한숨을 푹 내쉬면서 탭 화면을 껐다.

Academic Artificial Intelligence, 일명 AAI. 하늘이 고등학교 1학년일 때, 그러니까 불과 2년 전 대한민국 정부 주도 아래 전국 초, 중, 고등학교에 도입된 인공지능 학습 시스템이다. AAI는 명목상 학교 수업 ‘보조’, 시험 출제 ‘보조’, 재현 및 평가 ‘보조’ 등으로 개발되었지만 1년 만에 AAI의 편리함을 알아버린 선생님들이 어느 덧 AAI를 보조하지 못 참아있다.
''',
                    };
                    Navigator.of(context).pop();    // 팝업 닫기
                    onUpload(newBook);              // 부모에 업로드 전달
                  },
                  child: Text('확인'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
          onPressed: () => _pickPdf(context),   // 버튼 클릭 시 파일 선택
          child: Text('파일 업로드하기')
      ),
    );
  }
}