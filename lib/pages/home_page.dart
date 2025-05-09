import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:grad_front/pages/library_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_page.dart';
import 'dart:io';


class HomePage extends StatefulWidget{
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{
  int _currentIndex = 1; // 기본값: 홈화면

  List<Map<String, dynamic>> _books = [];

  @override
  Widget build(BuildContext context){
    final List<Widget> _pages = [
      LibraryPage(books: _books),
      HomeMainContent(
        onUpload: (newBook){
          setState(() {
            _books.add(newBook);
            _currentIndex = 0;
          });
        }
      ),
      MyPage(),
    ];

    return Scaffold(
      body:
      IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index){
          setState(() {
            _currentIndex = index;
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

class HomeMainContent extends StatelessWidget {
  final Function(Map<String, dynamic>) onUpload;

  const HomeMainContent({required this.onUpload});

  Future<void> _pickPdf(BuildContext context) async {
    final params = OpenFileDialogParams(
      dialogType: OpenFileDialogType.document,
      sourceType: SourceType.photoLibrary,
      fileExtensionsFilter: ['pdf'],
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
                    };
                    Navigator.of(context).pop();
                    onUpload(newBook);
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
          onPressed: () => _pickPdf(context),
          child: Text('파일 업로드하기')
      ),
    );
  }
}