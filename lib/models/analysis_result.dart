class AnalysisResult {
  final String sentence;
  final String emotion;
  final String effectFile;
  final String ttsFile;

  AnalysisResult({
    required this.sentence,
    required this.emotion,
    required this.effectFile,
    required this.ttsFile,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      sentence: json['sentence'] ?? '',
      emotion: json['emotion'] ?? 'neutral',
      effectFile: json['effectFile'] ?? '',
      ttsFile: json['ttsFile'] ?? '',
    );
  }
}