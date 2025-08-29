import 'package:grad_front/models/analysis_result.dart';

class PdfAnalysis {
  final String id;
  final String userId;
  final String filename;
  final DateTime uploadedTime;
  final List<AnalysisResult> results;
  
  // 진행률
  double progress;

  PdfAnalysis({
    required this.id,
    required this.userId,
    required this.filename,
    required this.uploadedTime,
    required this.results,
    this.progress = 0.0, // 기본값은 0.0
  });

  factory PdfAnalysis.fromJson(Map<String, dynamic> json) {
    var resultsList = json['results'] as List? ?? [];
    List<AnalysisResult> parsedResults = resultsList
        .map((i) => AnalysisResult.fromJson(i))
        .toList();

    return PdfAnalysis(
      id: json['id'] ?? '',
      userId: json['userid'] ?? '',
      filename: json['filename'] ?? '제목 없음',
      uploadedTime: DateTime.tryParse(json['uploadedTime'] ?? '') ?? DateTime.now(),
      results: parsedResults,
      // progress는 이 모델에 없으므로 여기서 파싱하지 않음
    );
  }
}