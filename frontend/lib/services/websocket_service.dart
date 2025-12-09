import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'user_api.dart';
import '../featutres/chat/chat_controller.dart';
import 'dart:convert';

class ChatInquirySocket {
  WebSocketChannel? _channel;
  bool _isConnected = false;

  final ChatInquiryLogic logic;

  ChatInquirySocket(this.logic);

  // WebSocket 서버 연결
  void connectWebSocket() {
    try {
      // WebSocket 채널 생성
      _channel = WebSocketChannel.connect(ApiService.webSocketUri);
      _updateConnectionStatus(true); // 연결 상태 갱신
      _sendConnectMessage(); // 접속 메시지 전송

      // 수신 스트림 리스너 설정
      _channel!.stream.listen(
        // 메시지 수신 시 처리 함수
        _handleIncomingMessage,
        onError: (error) {
          print('WebSocket 오류: $error');
          _updateConnectionStatus(false);
        },
        onDone: () {
          print('WebSocket 연결 종료됨');
          _updateConnectionStatus(false);
        },
      );
    } catch (e) {
      print('WebSocket 연결 시도 실패: $e');
      _updateConnectionStatus(false);
    }
  }

  // 연결 상태 업데이트
  void _updateConnectionStatus(bool connected) {
    _isConnected = connected;
  }

  // 서버 접속 메시지 전송
  void _sendConnectMessage() {
    final connectMessage = jsonEncode({
      "user_pk": logic.userPk,
      "message": "__CONNECT__",
    });
    print('connectMessage 보내기: $connectMessage');
    _channel?.sink.add(connectMessage);
  }

  // 수신된 메시지 처리
  Future<void> _handleIncomingMessage(dynamic data) async {
    if (data is! String) {
      print('수신 데이터 형식 오류: 문자열이 아님');
      return;
    }
    try {
      // JSON 문자열을 맵으로 변환
      final messageData = jsonDecode(data) as Map<String, dynamic>;

      // 필수 필드 체크
      final msgId = messageData["id"];
      final senderPk = messageData["user_pk"];
      if (msgId == null || senderPk == null) {
        print('수신 메시지에 필수 필드(id 또는 user_pk) 없음');
        return;
      }

      // 메시지 정보 추출
      final msgText = messageData["message"] ?? "";
      final isFromAdmin = messageData["is_from_admin"] ?? false;
      final timestamp = logic.parseDateTime(messageData["created_at"]);

      final isMe = logic.isMessageFromMe(isFromAdmin);
      final shouldShow = logic.shouldShowInCurrentChat(senderPk, isFromAdmin);
      final convPk = logic.isAdmin ? senderPk : logic.userPk;

      // 새로운 사용자일 때 갱신
      if (!logic.userInfoMap.value.containsKey(senderPk)) {
        await logic.loadAllConversations();
        if (shouldShow) {
          logic.initMessagesForConversation(convPk);
        }
      }

      // 중복 메시지 무시
      if (logic.isDuplicateMessage(convPk, msgId)) {
        print('중복 메시지(id: $msgId) 무시');
        return;
      }

      // 화면에 메시지 추가
      if (shouldShow) {
        logic.addMessageToUI(
          ChatMessage(
            id: msgId,
            text: msgText,
            isMe: isMe,
            timestamp: timestamp,
          ),
        );
      }

      // 전체 대화 목록에 메시지 추가
      logic.appendMessageToConversation(
        pk: convPk,
        msgId: msgId,
        userPk: senderPk,
        text: msgText,
        isFromAdmin: isFromAdmin,
        timestamp: timestamp,
      );
    } catch (e) {
      print("수신 메시지 파싱 오류: $e");
    }
  }

  // 서버로 메시지 전송
  void sendSocketMessage(String jsonMessage) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonMessage);
    } else {
      print('WebSocket 미연결 상태에서 메시지 전송 시도');
    }
  }

  // WebSocket 연결 종료 및 상태 초기화
  void dispose() {
    _channel?.sink.close(status.goingAway);
    _updateConnectionStatus(false);
  }
}
