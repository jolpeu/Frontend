import 'package:flutter/material.dart';

class LibraryPage extends StatefulWidget{
  final List<Map<String, dynamic>> books;

  const LibraryPage({required this.books, super.key});
  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>{
  String _filter = '읽고 있는 책';
  String _viewMode = 'grid';


  List<Map<String, dynamic>> get _filteredBooks {
    if (_filter == '전체') return widget.books;
    return widget.books.where((book) => book['status'] == _filter).toList();
  }

  @override


  Widget _buildBookCard(Map<String, dynamic> book){
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(Icons.menu_book, size: 40, color: Colors.white),
                ),
              ),
          ),
          SizedBox(height: 8),
          Text(
            book['title'],
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: book['progress'],
            backgroundColor: Colors.grey.shade200,
            color: Colors.blueAccent,
            minHeight: 6,
          ),
          SizedBox(height: 4),
          Text(
            '${(book['progress'] * 100).toInt()}%',
            style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('내 서재')),
      body: Column(
        children: [
          // 상단 필터 + 보기 형식 아이콘
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 상단 필터 탭
                  Row(
                    children: ['읽고 있는 책', '다 읽은 책', '전체'].map((label) {
                      return GestureDetector(
                        onTap: () => setState(() => _filter = label),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _filter == label ? Colors.black : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _filter == label ? Colors.black : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.grid_view),
                        color: _viewMode == 'grid' ? Colors.black : Colors.grey,
                        onPressed: () => setState(() => _viewMode = 'grid'),
                          ),
                      IconButton(
                        icon: Icon(Icons.view_list),
                        color: _viewMode == 'list' ? Colors.black : Colors.grey,
                        onPressed: () => setState(() => _viewMode = 'list'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: _filteredBooks.isEmpty
          ?Center(
              child: Text(
                '책이 없습니다. \n 홈 화면에서 파일을 업로드해보세요!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
            : _viewMode == 'grid'
                ? GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 16,
                childAspectRatio: 0.6,
              ),
              itemCount: _filteredBooks.length,
              itemBuilder: (context, index) {
                final book = _filteredBooks[index];
                return _buildBookCard(book);
              },
            )
                : ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: _filteredBooks.length,
              itemBuilder: (context, index) {
                final book = _filteredBooks[index];
                return ListTile(
                  title: Text(book['title']),
                  subtitle: Text(book['status']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}