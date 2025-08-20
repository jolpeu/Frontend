import 'dart:convert';
import 'package:http/http.dart' as http;

String friendlyErrorFromResponse(
    http.Response r, {
      Map<int, String>? overrides,
    }) {
  final body = utf8.decode(r.bodyBytes);

  // 서버 메시지 추출 시도
  String? serverMsg;
  try {
    final j = jsonDecode(body);
    if (j is Map) {
      serverMsg = j['message']?.toString() ??
          j['error']?.toString() ??
          j['detail']?.toString();
    }
  } catch (_) {
    // JSON이 아니면 무시
  }

  final map = <int, String>{
    400: '입력값을 확인해주세요.',
    401: '이메일 또는 비밀번호를 확인해주세요.',
    403: '접근 권한이 없습니다.',
    404: '요청하신 정보를 찾을 수 없습니다.',
    409: '이미 사용 중인 이메일입니다.',
    422: '입력 형식이 올바르지 않습니다.',
    429: '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
    500: '일시적인 오류입니다. 잠시 후 다시 시도해주세요.',
    502: '서버 통신 오류입니다. 잠시 후 다시 시도해주세요.',
    503: '서비스 점검 중입니다. 잠시 후 다시 시도해주세요.',
    504: '응답 지연입니다. 잠시 후 다시 시도해주세요.',
  };

  if (overrides != null) map.addAll(overrides);

  return map[r.statusCode] ??
      serverMsg ??
      '요청 처리에 실패했습니다. 잠시 후 다시 시도해주세요.';
}
