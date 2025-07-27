import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../backApi/user_api.dart';

// 메시지 데이터 모델
class ChatMessage {
  final String text; // 메시지
  final bool isMe; // 본인 여부
  final DateTime timestamp; // 전송 간

  ChatMessage({
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

  // 유저 정보 변수
  int userPk = 0;
  bool isAdmin = false;

  // 리소스 정리
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    scrollController.dispose();
  }

  // 초기화
  Future<void> initialize({required bool isAdmin, required int userPk}) async {
    this.userPk = userPk;
    this.isAdmin = isAdmin;

    // 관리자: 전체 대화 불러오기
    if (isAdmin) {
      await loadAllConversations();
    }
    // 사용자: 자신의 대화만 불러오기
    else {
      await loadUserMessages();
    }

    scrollToBottom();
  }

  // 메시지 전송
  Future<void> sendMessage({
    VoidCallback? onAfterSend,
    required bool isFromAdmin,
    int? userPkOverride,
  }) async {
    // 문자열 확인
    final rawText = controller.text;
    if (rawText.trim().isEmpty) return;

    // 입력창 초기화 및 포커스
    controller.clear();
    focusNode.requestFocus();

    // 유저 식별: 관리자-선택한 유저, 사용자-자신
    final targetPk =
        userPkOverride ?? (isFromAdmin ? selectedUserPk.value : userPk);
    if (targetPk == null || targetPk == 0) return;

    final now = DateTime.now();

    // 저장 요청
    try {
      final success = await ApiService.sendChatMessage(
        userPk: targetPk,
        message: rawText,
        isFromAdmin: isFromAdmin,
      );

      if (!success) {
        print('서버 전송 실패');
        return;
      }

      // 저장 성공: 메시지 목록 갱신
      final newMsg = ChatMessage(text: rawText, isMe: true, timestamp: now);
      messages.value = [...messages.value, newMsg];

      final updated = {...allConversations.value};

      // targetPk가 null이면 초기화
      if (updated[targetPk] == null) {
        updated[targetPk] = {
          "messages": [],
        };
      }

      // 새 메시지 추가
      updated[targetPk]["messages"].add({
        "id": 0,
        "user_pk": targetPk,
        "message": rawText,
        "is_from_admin": isFromAdmin,
        "created_at": now.toIso8601String(),
      });
      allConversations.value = updated;

      // 후처리
      onAfterSend?.call();
    } catch (e) {
      print('메시지 전송 오류: $e');
    }
  }

  // 현재 유저 채팅 불러오기
  Future<void> loadUserMessages() async {
    if (userPk == 0) return;

    try {
      final serverMessages = await ApiService.fetchUserMessages(userPk);
      messages.value = convertToChatMessages(serverMessages, isAdmin: false);
    } catch (e) {
      print('메시지 불러오기 실패: $e');
    }
  }

  // 전체 유저 채팅 불러오기
  Future<void> loadAllConversations() async {
    try {
      final result = await ApiService.fetchAllConversations();
      final conversations = result['conversations'] ?? {};
      final converted = <int, dynamic>{};

      conversations.forEach((key, value) {
        final intKey = int.tryParse(key);
        if (intKey != null) converted[intKey] = value;
      });

      allConversations.value = converted;
    } catch (e) {
      print("관리자 대화 불러오기 실패: $e");
    }
  }

  // 관리자: 선택한 유저 메시지 로딩
  Future<void> selectUser(int userPk, {required bool isAdmin}) async {
    selectedUserPk.value = userPk;

    final messagesJson = allConversations.value[userPk]?["messages"] ?? [];
    messages.value = convertToChatMessages(messagesJson, isAdmin: isAdmin);

    scrollToBottom();
  }

  // 관리자: 미리보기용 마지막 메시지 추출
  String getLastMessagePreview(int userPk) {
    final userData = allConversations.value[userPk];
    if (userData == null) return '';

    final List messages = userData["messages"];
    if (messages.isEmpty) return '';

    final last = messages.last;
    final text = last["message"] ?? '';
    return text.toString().trim();
  }

  // JSON → ChatMessage 변환
  List<ChatMessage> convertToChatMessages(
    List<dynamic> jsonList, {
    bool isAdmin = false,
  }) {
    return jsonList.map((json) {
      final isFromAdmin = json['is_from_admin'] ?? false;

      return ChatMessage(
        text: json['message'] ?? '',
        isMe: isAdmin ? isFromAdmin : !isFromAdmin,
        timestamp: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String(),
        ).toLocal(),
      );
    }).toList();
  }

  // 채팅창 자동 스크롤-------------------------------
  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  // 키 입력
  Future<void> handleEnterKey({
    bool isFromAdmin = false,
    int? userPkOverride,
  }) async {
    final isShiftPressed =
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.shiftLeft,
        ) ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.shiftRight,
        );

    // 쉬프트+엔터: 줄바꿈
    if (isShiftPressed) {
      _insertNewline();
    }
    // 엔터: 전송
    else {
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
    if (newlineCount >= 5) return; // 최대 5줄

    final selection = controller.selection;
    final newText = text.replaceRange(selection.start, selection.end, '\n');

    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: selection.start + 1);
  }

  // 날짜 구분선 표시 여부 판단
  bool shouldShowDateDivider(int index) {
    if (index == 0) return true;

    final prev = messages.value[index - 1].timestamp;
    final curr = messages.value[index].timestamp;

    return prev.year != curr.year ||
        prev.month != curr.month ||
        prev.day != curr.day;
  }
}
