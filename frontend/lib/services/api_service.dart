import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:flutter/foundation.dart'; // kIsWeb 불필요하여 제거

class ApiService {
  // 💡 [수정됨] 로컬 서버 주소로만 고정 (사용자 요청: 127.0.0.1:8000)
  // Android 에뮬레이터에서 테스트할 경우, 이 주소를 'http://10.0.2.2:8000'으로 수동 변경해야 합니다.
  static const String LOCAL_API_BASE_URL = 'http://127.0.0.1:8000';

  // 1. Base URL 설정 (로컬 주소로 고정)
  static String get baseUrl {
    // ✅ 모든 환경에서 로컬 주소 사용
    return LOCAL_API_BASE_URL;
  }

  // ------------------------------------------------------------------
  // A. [Orchestrator] 분석 API
  // ------------------------------------------------------------------

  // 2. 텍스트 분석 요청 API (POST /orchestrator/analyze)
  static Future<void> analyzeTextStream({
    required String text,
    required Function(Map<String, dynamic>) onMessage,
    required Function(dynamic) onError,
    required Function() onDone,
  }) async {
    try {
      final request = http.Request(
        "POST",
        Uri.parse('$baseUrl/orchestrator/analyze'),
      );
      request.headers["Content-Type"] = "application/json";
      request.body = jsonEncode({"text": text});

      final response = await request.send();

      response.stream
          .transform(utf8.decoder)
          .listen(
            (chunk) {
              for (final line in chunk.split(RegExp(r'[\r\n]+'))) {
                if (line.trim().isEmpty) continue;
                try {
                  onMessage(jsonDecode(line));
                } catch (_) {}
              }
            },
            onError: onError,
            onDone: onDone,
          );
    } catch (e) {
      onError(e);
    }
  }

  // ------------------------------------------------------------------
  // B. [User] 인증 API
  // ------------------------------------------------------------------

  // 3. 회원가입 API (POST /users/join)
  static Future<void> join({
    required String username,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/users/join');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final detail = errorBody['detail'] ?? '회원가입 중 알 수 없는 오류가 발생했습니다.';
        throw Exception('$detail (URL: $url, Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('회원가입 서버 연결 오류: ${e.toString()} (URL: $url)');
    }
  }

  // 4. 로그인 API (POST /users/login)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/users/login');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        // 로그인 성공 (토큰과 유저 정보 반환)
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        return decodedData;
      } else if (response.statusCode == 401) {
        // 인증 실패 (이메일/비밀번호 불일치)
        throw Exception('이메일 또는 비밀번호가 일치하지 않습니다. (URL: $url)');
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final detail = errorBody['detail'] ?? '로그인 중 알 수 없는 오류가 발생했습니다.';
        throw Exception('$detail (URL: $url, Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('로그인 서버 연결 오류: ${e.toString()} (URL: $url)');
    }
  }
}
