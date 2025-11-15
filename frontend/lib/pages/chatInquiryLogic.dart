import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../backApi/user_api.dart';
import '../pages/chatInquirySocket.dart';
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

  final ValueNotifier<List<ChatMessage>> messages = ValueNotifier([]);
  final ValueNotifier<Map<int, dynamic>> allConversations = ValueNotifier({});
  final ValueNotifier<int?> selectedUserPk = ValueNotifier(null);
  final ValueNotifier<Map<int, Map<String, dynamic>>> userInfoMap =
      ValueNotifier({});

  late bool isAdmin;
  late int userPk;
  late final ChatInquirySocket socket;
  ChatInquiryLogic();

  void dispose() {
    controller.dispose();
    focusNode.dispose();
    scrollController.dispose();
    socket.dispose();
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
      selectedUserPk.value = userPk;
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
      !isAdmin || selectedUserPk.value == senderPk || isFromAdmin;

  // 메시지 중복 검사
  bool isDuplicateMessage(int convPk, int msgId) {
    final convList = allConversations.value[convPk]?["messages"] ?? [];
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
    final conv = allConversations.value[convPk];
    if (conv == null) return;

    final loadedMsgs =
        (conv["messages"] as List<dynamic>)
            .map((msg) => _createChatMessage(msg, isAdmin))
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id)); // id 정렬

    messages.value = loadedMsgs;
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
        userPkOverride ?? (isFromAdmin ? selectedUserPk.value : userPk);
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
    final currentMessages = allConversations.value[targetPk]?["messages"] ?? [];
    final maxId = currentMessages.isEmpty
        ? 0
        : currentMessages
              .map((m) => m["id"] as int)
              .reduce((a, b) => a > b ? a : b);
    final tempId = maxId + 1;

    // UI에 즉시 메시지 추가
    if (targetPk == selectedUserPk.value) {
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
    messages.value = [...messages.value, msg];
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
    final updated = Map<int, dynamic>.from(allConversations.value);
    updated[pk] ??= {"messages": <Map<String, dynamic>>[]};

    (updated[pk]["messages"] as List).add({
      "id": msgId,
      "user_pk": userPk,
      "message": text,
      "is_from_admin": isFromAdmin,
      "created_at": timestamp.toIso8601String(),
    });

    allConversations.value = updated;
  }

  // 유저 메시지 로딩 ---------------------------------
  Future<void> loadUserMessages() async {
    if (userPk == 0) return;
    try {
      final serverMessages = await ApiService.fetchUserMessages(userPk);
      messages.value = _convertToMessages(serverMessages, isAdminView: false);
      allConversations.value = {
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

      userInfoMap.value = _mapUsers(usersList);
      allConversations.value = convMap;
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
    selectedUserPk.value = userPk;
    final messagesJson = allConversations.value[userPk]?["messages"] ?? [];
    messages.value = _convertToMessages(messagesJson, isAdminView: isAdmin);
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
    final userData = allConversations.value[userPk];
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
    final prev = messages.value[index - 1].timestamp;
    final curr = messages.value[index].timestamp;
    return prev.year != curr.year ||
        prev.month != curr.month ||
        prev.day != curr.day;
  }
}
