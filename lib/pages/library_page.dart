import 'package:flutter/material.dart';
import 'package:grad_front/models/pdf_analysis.dart';
import 'package:grad_front/pages/reader_page.dart';

/// 사용자가 업로드한 책들
class LibraryPage extends StatefulWidget {
  final List<PdfAnalysis> books;

  final String userId;
  final String apiBaseUrl;

  const LibraryPage({
    required this.books,
    required this.userId,
    required this.apiBaseUrl,
    Key? key,
  }) : super(key: key);

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String _filter = '읽고 있는 책';   // 현재 선택된 카테고리 필터
  String _viewMode = 'grid';        // 보기 형식: grid or list

  /// 필터에 맞는 책 목록 반환
  List<PdfAnalysis> get _filteredBooks {
    bool completed(PdfAnalysis b) => (b.progress >= 0.999);

    switch (_filter) {
      case '다 읽은 책':
        return widget.books.where(completed).toList();
      case '읽고 있는 책':
        return widget.books.where((b) => !completed(b)).toList();
      case '전체':
      default:
        return widget.books;
    }
  }

  void _openReader(PdfAnalysis book) async {
    final String bookId = book.id;
    if (bookId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('bookId가 없어서 열 수 없습니다.')),
      );
      return;
    }


    // ReaderPage가 반환하는 값의 타입을 Map<String, dynamic>으로 명시함
    final result = await Navigator.push<Map<String, double>>(
      context, MaterialPageRoute(
        builder: (_) => ReaderPage(
          title: book.filename.replaceAll('.pdf', ''),
          results: book.results,
          bookId: bookId,
          userId: widget.userId,
          apiBaseUrl: widget.apiBaseUrl,
          ),
      ),
    );

    // 진행률이 넘어오면 책 카드의 진행률 갱신
    if (result != null) {
      final double? progress = (result['progress'] as num?)?.toDouble();
      final double? offset = (result['offset'] as num?)?.toDouble();

      setState(() {
        if (progress != null) {
          book.progress = progress.clamp(0.0, 1.0);
        }

        if (offset != null) {
          book.lastReadOffset = offset;
        }
      });
    }
  }

  /// 책 카드 UI 생성
  Widget _buildBookCard(PdfAnalysis book) {
    return GestureDetector(
      onTap: () => _openReader(book),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
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
                  child: Icon(Icons.menu_book, size: 36, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              book.filename.replaceAll('.pdf', ''),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: book.progress,
              backgroundColor: Colors.grey.shade200,
              color: Colors.lightGreen,
              minHeight: 6,
            ),
            SizedBox(height: 4),
            Text(
              '${(book.progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      body: Column(
        children: [
          Container(
            height: 70,
            color: Color(0xDDB3C39C),
            child: Center(
              child: Image.asset('assets/logos/logo_horizontal.png', height: 40),
            ),
          ),
          Container(
            color: Color(0xFFDEE5D4),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: ['읽고 있는 책', '다 읽은 책', '전체'].map((label) {
                    final isSelected = _filter == label;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = label),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected ? Colors.black : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Image.asset(
                        _viewMode == 'grid'
                            ? 'assets/icons/icon_grid-active.png'
                            : 'assets/icons/icon_grid-inactive.png',
                        height: 27,
                      ),
                      onPressed: () => setState(() => _viewMode = 'grid'),
                    ),
                    IconButton(
                      icon: Image.asset(
                        _viewMode == 'list'
                            ? 'assets/icons/icon_list-active.png'
                            : 'assets/icons/icon_list-inactive.png',
                        height: 24,
                      ),
                      onPressed: () => setState(() => _viewMode = 'list'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredBooks.isEmpty
                ? Center(
                    child: Text(
                      '책이 없습니다.\n홈 화면에서 파일을 업로드해보세요!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _viewMode == 'grid'
                    ? GridView.builder(
                        padding: EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.6,
                        ),
                        itemCount: _filteredBooks.length,
                        itemBuilder: (context, index) =>
                            _buildBookCard(_filteredBooks[index]),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = _filteredBooks[index];
                          return GestureDetector(
                            onTap: () => _openReader(book),
                            child: ListTile(
                              title: Text(book.filename.replaceAll('.pdf', '')),
                              // subtitle: Text(book.preview ?? ''), // preview 있으면 표시
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
