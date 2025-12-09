import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // kIsWeb 사용

class ApiService {
  
  // 💡 클라우드 타입에서 부여받은 실제 주소
  static const String CLOUD_API_URL = 'https://port-0-capstonebackend-m7syarm12c5a1376.sel4.cloudtype.app'; 

  // 💡 [수정된 로컬 주소] (Base URL: /docs를 제외한 부분)
  // iOS 시뮬레이터, Desktop, 일반 브라우저에서 사용
  static const String LOCAL_API_URL_IOS_DESKTOP = 'http://127.0.0.1:8000'; 
  
  // Android Emulator에서 호스트 PC의 로컬 서버에 접근하기 위해 사용
  static const String LOCAL_API_URL_ANDROID = 'http://10.0.2.2:8000'; 
  
  // 1. Base URL 설정 (로컬 실행 환경 포함)
  static String get baseUrl {
    // kIsWeb: 현재 앱이 웹 환경에서 실행되고 있는지 여부를 알려줌
    if (kIsWeb) {
      // ✅ 웹 환경이거나 최종 배포 시 (클라우드 주소 사용)
      return CLOUD_API_URL;
    } else {
      // ✅ 모바일/데스크톱 환경 (개발 중 로컬 서버 주소 사용)
      // ⚠️ 주의: 테스트 환경에 맞춰 아래 둘 중 하나를 선택해야 합니다.
      
      // ➡️ 기본 설정 (iOS 시뮬레이터, Desktop, Mac/Linux/Windows 일반 실행)
      return LOCAL_API_URL_IOS_DESKTOP; 
      
      // ➡️ ★ 안드로이드 에뮬레이터에서 테스트할 경우 아래 코드를 대신 사용하세요.
      // return LOCAL_API_URL_ANDROID; 
    }
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
        throw Exception('분석 실패: $detail (URL: $url, Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('서버 연결 오류: ${e.toString()} (URL: $url)');
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
        throw Exception('$detail (URL: $url, Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('회원가입 서버 연결 오류: ${e.toString()} (URL: $url)');
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
