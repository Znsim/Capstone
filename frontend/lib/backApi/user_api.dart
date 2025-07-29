import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // kIsWeb 사용을 위해 추가

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000"; // 웹
    } else {
      return "http://10.0.2.2:8000"; // 모바일 (Android 에뮬레이터)
    }
  }

  // 로그인
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('${baseUrl}/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? '로그인 실패');
    }
  }

  // 회원가입 요청 및 인증 메일 발송
  static Future<Map<String, dynamic>?> join({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${baseUrl}/users/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? '회원가입 실패');
    }
  }

  // 채팅 메시지 전송
  static Future<bool> sendChatMessage({
    required int userPk,
    required String message,
    bool isFromAdmin = false,
  }) async {
    final url = Uri.parse('${baseUrl}/chat/send');

    final body = jsonEncode({
      "user_pk": userPk,
      "message": message,
      "is_from_admin": isFromAdmin,
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    return response.statusCode == 201;
  }

  // 특정 사용자 채팅 메시지 목록 조회
  static Future<List<Map<String, dynamic>>> fetchUserMessages(
    int userPk,
  ) async {
    final url = Uri.parse('${baseUrl}/chat/get_messages');

    final body = jsonEncode({
      "user_pk": userPk,
      "message": "",
      "is_from_admin": false,
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception('메시지 조회 실패');
    }
  }

  // 전체 사용자 대화 목록 조회 (관리자용)
  static Future<Map<String, dynamic>> fetchAllConversations() async {
    final url = Uri.parse('${baseUrl}/chat/all');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final Map<String, dynamic> conversations = data['conversations'];
      final List<Map<String, dynamic>> users = conversations.entries.map((e) {
        return {
          'user_id': e.value['user_info']['user_id'],
          'username': e.value['user_info']['username'],
          'email': e.value['user_info']['email'],
        };
      }).toList();

      return {'users': users, 'conversations': conversations};
    } else {
      throw Exception('전체 대화 조회 실패');
    }
  }
}
