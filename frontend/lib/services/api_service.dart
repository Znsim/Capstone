import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // kIsWeb 사용

class ApiService {
  
  // 💡 [새로 추가] 클라우드 타입에서 부여받은 실제 주소
  // '/docs'를 제외하고 앱이 접속할 수 있는 기본 경로만 설정합니다.
  static const String CLOUD_API_URL = 'https://port-0-capstonebackend-m7syarm12c5a1376.sel4.cloudtype.app'; 

  // 1. Base URL 설정 (클라우드 배포 주소로 변경)
  // 기존의 복잡한 로컬 주소 로직을 제거하고 배포 주소로 고정합니다.
  static String get baseUrl {
    return CLOUD_API_URL; 
  }

  // ------------------------------------------------------------------
  // A. [Orchestrator] 분석 API
  // ------------------------------------------------------------------

  // 2. 텍스트 분석 요청 API (POST /orchestrator/analyze)
  static Future<Map<String, dynamic>> analyzeText(String text) async {
    final url = Uri.parse('$baseUrl/orchestrator/analyze');
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}), 
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final detail = errorBody['detail'] ?? '분석 중 알 수 없는 오류가 발생했습니다.';
        throw Exception('분석 실패: $detail');
      }
    } catch (e) {
      throw Exception('서버 연결 오류: ${e.toString()}');
    }
  }

  // ------------------------------------------------------------------
  // B. [User] 인증 API
  // ------------------------------------------------------------------

  // 3. 회원가입 API (POST /users/join)
  static Future<void> join({
    required String username, 
    required String email, 
    required String password
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
        throw Exception(detail);
      }
    } catch (e) {
      throw Exception('회원가입 서버 연결 오류: ${e.toString()}');
    }
  }

  // 4. 로그인 API (POST /users/login)
  static Future<Map<String, dynamic>> login({
    required String email, 
    required String password
  }) async {
    final url = Uri.parse('$baseUrl/users/login');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );
      
      if (response.statusCode == 200) {
        // 로그인 성공 (토큰과 유저 정보 반환)
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        return decodedData; 
      } else if (response.statusCode == 401) {
        // 인증 실패 (이메일/비밀번호 불일치)
        throw Exception('이메일 또는 비밀번호가 일치하지 않습니다.');
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final detail = errorBody['detail'] ?? '로그인 중 알 수 없는 오류가 발생했습니다.';
        throw Exception(detail);
      }
    } catch (e) {
      throw Exception('로그인 서버 연결 오류: ${e.toString()}');
    }
  }
}