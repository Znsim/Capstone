import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // ValueListenable 사용을 위해 필요
import '../../services/user_api.dart';
import '../../services/websocket_service.dart';
import 'dart:convert';

// 메시지 데이터 모델
class ChatMessage {
  final int id; // id
  final String text; // 메시지
  final bool isMe; // 본인 여부
  final DateTime timestamp; // 전송 시간

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

// 채팅문의 기능 로직
class ChatInquiryLogic {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  // [수정됨] Private ValueNotifier로 변경 (내부 상태 변경용)
  final ValueNotifier<List<ChatMessage>> _messagesNotifier = ValueNotifier([]);
  final ValueNotifier<Map<int, dynamic>> _allConversationsNotifier = ValueNotifier({});
  final ValueNotifier<int?> _selectedUserPkNotifier = ValueNotifier(null);
  final ValueNotifier<Map<int, Map<String, dynamic>>> _userInfoMapNotifier = ValueNotifier({});

  // [수정됨] Public Getter 추가 (외부 노출용 - ValueListenable 타입 명시로 오류 해결)
  ValueListenable<List<ChatMessage>> get messages => _messagesNotifier;
  ValueListenable<Map<int, dynamic>> get allConversations => _allConversationsNotifier;
  ValueListenable<int?> get selectedUserPk => _selectedUserPkNotifier;
  ValueListenable<Map<int, Map<String, dynamic>>> get userInfoMap => _userInfoMapNotifier;


  late bool isAdmin;
  late int userPk;
  late final ChatInquirySocket socket;
  ChatInquiryLogic();

  void dispose() {
    controller.dispose();
    focusNode.dispose();
    scrollController.dispose();
    // Notifier들도 dispose 해주는 것이 좋습니다.
    _messagesNotifier.dispose();
    _allConversationsNotifier.dispose();
    _selectedUserPkNotifier.dispose();
    _userInfoMapNotifier.dispose();
    socket.dispose();
  }

  void clearSelectedUser() {
    _selectedUserPkNotifier.value = null;
  }

  // 초기화 -------------------------------------------

  Future<void> initialize({required bool isAdmin, required int userPk}) async {
    this.isAdmin = isAdmin;
    this.userPk = userPk;
    socket = ChatInquirySocket(this);

    print('초기화: isAdmin=$isAdmin, userPk=$userPk');

    // 관리자: 모든 대화 로드
    if (isAdmin) {
      await loadAllConversations();
    }
    // 유저: 본인 대화 로드
    else {
      await loadUserMessages();
      _selectedUserPkNotifier.value = userPk; // 수정됨
      initMessagesForConversation(userPk);
    }

    scrollToBottom(); // 자동 스크롤
    print('WebSocket 연결 시도');
    socket.connectWebSocket(); // 소켓 연결
  }

  // 메시지가 본인인가?
  bool isMessageFromMe(bool isFromAdmin) => isAdmin == isFromAdmin;

  // 선택한 대화창에 표시할 메시지인가?
  bool shouldShowInCurrentChat(int senderPk, bool isFromAdmin) =>
      !isAdmin || _selectedUserPkNotifier.value == senderPk || isFromAdmin; // 수정됨

  // 메시지 중복 검사
  bool isDuplicateMessage(int convPk, int msgId) {
    final convList = _allConversationsNotifier.value[convPk]?["messages"] ?? []; // 수정됨
    return convList.any((m) => m["id"] == msgId);
  }

  // 시간 객체 변환
  DateTime parseDateTime(String? ts) =>
      ts != null ? DateTime.parse(ts).toLocal() : DateTime.now();

  // 메시지 객체 변환
  ChatMessage _createChatMessage(Map<String, dynamic> json, bool isAdminView) {
    final isFromAdmin = json['is_from_admin'] ?? false;
    final timestamp = parseDateTime(json['created_at']);
    return ChatMessage(
      id: json['id'] ?? 0,
      text: json['message'] ?? '',
      isMe: isAdminView ? isFromAdmin : !isFromAdmin,
      timestamp: timestamp,
    );
  }

  // 특정 대화 목록 초기화
  void initMessagesForConversation(int convPk) {
    final conv = _allConversationsNotifier.value[convPk]; // 수정됨
    if (conv == null) return;

    final loadedMsgs =
        (conv["messages"] as List<dynamic>)
            .map((msg) => _createChatMessage(msg, isAdmin))
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id)); // id 정렬

    _messagesNotifier.value = loadedMsgs; // 수정됨
    scrollToBottom();
  }

  // 메시지 전송 ---------------------------------------
  Future<void> sendMessage({
    VoidCallback? onAfterSend,
    required bool isFromAdmin,
    int? userPkOverride,
  }) async {
    final rawText = controller.text;
    if (rawText.isEmpty) return; // 빈 메시지 전송 방지

    controller.clear(); // 입력창 초기화
    focusNode.requestFocus(); // 입력창에 포커스

    // 메시지 대상 PK 결정
    final targetPk =
        userPkOverride ?? (isFromAdmin ? _selectedUserPkNotifier.value : userPk); // 수정됨
    if (targetPk == null || targetPk == 0) return;

    // 서버에 전송할 JSON 메시지 생성
    final messageJson = {
      "user_pk": targetPk,
      "message": rawText,
      "is_from_admin": isFromAdmin,
    };

    // 웹소켓으로 메시지 전송
    socket.sendSocketMessage(jsonEncode(messageJson));

    final now = DateTime.now();

    // tempId 계산 (현재 채팅방의 최대 ID + 1)
    final currentMessages = _allConversationsNotifier.value[targetPk]?["messages"] ?? []; // 수정됨
    final maxId = currentMessages.isEmpty
        ? 0
        : currentMessages
              .map((m) => m["id"] as int)
              .reduce((a, b) => a > b ? a : b);
    final tempId = maxId + 1;

    // UI에 즉시 메시지 추가
    if (targetPk == _selectedUserPkNotifier.value) { // 수정됨
      addMessageToUI(
        ChatMessage(id: tempId, text: rawText, isMe: true, timestamp: now),
      );
    }

    // 대화 데이터에 메시지 추가
    appendMessageToConversation(
      pk: targetPk,
      msgId: tempId,
      userPk: targetPk,
      text: rawText,
      isFromAdmin: isFromAdmin,
      timestamp: now,
    );

    onAfterSend?.call(); // 전송 후 콜백 호출
  }

  // ui 새 메시지 추가
  void addMessageToUI(ChatMessage msg) {
    _messagesNotifier.value = [..._messagesNotifier.value, msg]; // 수정됨
    scrollToBottom();
  }

  // 대화 데이터에 메시지 추가
  void appendMessageToConversation({
    required int pk,
    required int msgId,
    required int userPk,
    required String text,
    required bool isFromAdmin,
    required DateTime timestamp,
  }) {
    final updated = Map<int, dynamic>.from(_allConversationsNotifier.value); // 수정됨
    updated[pk] ??= {"messages": <Map<String, dynamic>>[]};

    (updated[pk]["messages"] as List).add({
      "id": msgId,
      "user_pk": userPk,
      "message": text,
      "is_from_admin": isFromAdmin,
      "created_at": timestamp.toIso8601String(),
    });

    _allConversationsNotifier.value = updated; // 수정됨
  }

  // 유저 메시지 로딩 ---------------------------------
  Future<void> loadUserMessages() async {
    if (userPk == 0) return;
    try {
      final serverMessages = await ApiService.fetchUserMessages(userPk);
      _messagesNotifier.value = _convertToMessages(serverMessages, isAdminView: false); // 수정됨
      _allConversationsNotifier.value = { // 수정됨
        userPk: {"messages": serverMessages},
      };
    } catch (e) {
      print('유저 메시지 불러오기 실패: $e');
    }
  }

  // 전체 대화 로딩 (관리자)
  Future<void> loadAllConversations() async {
    try {
      final result = await ApiService.fetchAllConversations();
      final rawConvs = result['conversations'] as Map<String, dynamic>? ?? {};
      final usersList = result['users'] as List<dynamic>? ?? [];

      final convMap = <int, dynamic>{};
      rawConvs.forEach((key, value) {
        final intKey = int.tryParse(key);
        if (intKey != null) convMap[intKey] = value;
      });

      _userInfoMapNotifier.value = _mapUsers(usersList); // 수정됨
      _allConversationsNotifier.value = convMap; // 수정됨
    } catch (e) {
      print("관리자 전체 대화 불러오기 실패: $e");
    }
  }

  // 서버에서 받은 유저 리스트 변환
  Map<int, Map<String, dynamic>> _mapUsers(List<dynamic> users) {
    final map = <int, Map<String, dynamic>>{};
    for (final user in users) {
      final intKey = user['user_id'];
      if (intKey is int) {
        map[intKey] = {'username': user['username'], 'email': user['email']};
      }
    }
    return map;
  }

  // 유저 선택 (관리자)
  Future<void> selectUser(int userPk, {required bool isAdmin}) async {
    _selectedUserPkNotifier.value = userPk; // 수정됨
    final messagesJson = _allConversationsNotifier.value[userPk]?["messages"] ?? []; // 수정됨
    _messagesNotifier.value = _convertToMessages(messagesJson, isAdminView: isAdmin); // 수정됨
    scrollToBottom();
  }

  // 메시지 변환 헬퍼
  List<ChatMessage> _convertToMessages(
    List<dynamic> jsonList, {
    required bool isAdminView,
  }) {
    final messages = jsonList.map<ChatMessage>((json) {
      final isFromAdmin = json['is_from_admin'] ?? false;
      final timestamp = parseDateTime(json['created_at']);
      return ChatMessage(
        id: json['id'] ?? 0,
        text: json['message'] ?? '',
        isMe: isAdminView ? isFromAdmin : !isFromAdmin,
        timestamp: timestamp,
      );
    }).toList();

    messages.sort((a, b) => a.id.compareTo(b.id)); // id 정렬
    return messages;
  }

  // 미리보기 텍스트
  String getLastMessagePreview(int userPk) {
    final userData = _allConversationsNotifier.value[userPk]; // 수정됨
    if (userData == null) return '';
    final List messages = userData["messages"];
    if (messages.isEmpty) return '';
    return (messages.last["message"] ?? '').toString().trim();
  }

  // 채팅창 자동 스크롤 -------------------------------
  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  // 엔터 키 입력
  Future<void> handleEnterKey({
    bool isFromAdmin = false,
    int? userPkOverride,
  }) async {
    final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed.any(
      (key) =>
          key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight,
    );

    // 쉬프트+엔터: 줄바꿈
    if (isShiftPressed) {
      _insertNewline();
    } else {
      await sendMessage(
        onAfterSend: scrollToBottom,
        isFromAdmin: isFromAdmin,
        userPkOverride: userPkOverride,
      );
    }
  }

  // 입력창 줄바꿈
  void _insertNewline() {
    final text = controller.text;
    final newlineCount = '\n'.allMatches(text).length;
    if (newlineCount >= 5) return;
    final selection = controller.selection;
    final newText = text.replaceRange(selection.start, selection.end, '\n');
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: selection.start + 1);
  }

  // 날짜 구분선 표시 여부
  bool shouldShowDateDivider(int index) {
    if (index == 0) return true;
    final prev = _messagesNotifier.value[index - 1].timestamp; // 수정됨
    final curr = _messagesNotifier.value[index].timestamp; // 수정됨
    return prev.year != curr.year ||
        prev.month != curr.month ||
        prev.day != curr.day;
  }
}