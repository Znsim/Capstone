// [새로운 파일 위치: lib/features/chat/chat_screen.dart]
// [주의: ChatController.messages의 반환 타입이 ValueListenable<List<ChatMessage>>이어야 합니다.]

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// 로직 파일 (ChatController)
import 'chat_controller.dart'; 
// 헤더 위젯 import
import '../../widgets/common_header.dart'; 

// ----------------------------------------------------


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 로직 클래스 (ChatInquiryLogic는 chat_controller.dart에 정의되어 있어야 합니다.)
  final ChatInquiryLogic logic = ChatInquiryLogic();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdminFlag = prefs.getBool('isAdmin') ?? false;
    final userPk = prefs.getInt('userPk') ?? 0;

    await logic.initialize(isAdmin: isAdminFlag, userPk: userPk);

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  Future<bool> _handleWillPop() async {
    if (logic.isAdmin && logic.selectedUserPk.value != null) {
      logic.clearSelectedUser();
      return false; 
    }
    return true; 
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb;
    const bgColor = Color(0xFF8463F6);
    const maxWidth = 800.0;

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const CommonHeader(), 
        drawer: isWeb ? null : const AppDrawer(), // AppDrawer는 CommonHeader 파일에 통합 가정
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final Widget mainContent = isWeb 
        ? _buildWebLayout(bgColor, maxWidth) 
        : _buildMobileLayout();

    if (!isWeb) {
      return WillPopScope(
        onWillPop: _handleWillPop,
        child: mainContent,
      );
    }
    
    return mainContent;
  }
  
  // --- 웹 레이아웃 ---
  Widget _buildWebLayout(Color bgColor, double maxWidth) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: const CommonHeader(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              if (logic.isAdmin)
                Flexible(
                  flex: 3,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    height: MediaQuery.of(context).size.height,
                    color: Colors.white,
                    child: buildUserList(),
                  ),
                ),
              Flexible(
                flex: 10,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Container(
                        // ✨ 오류 수정: const 제거 (maxWidth 변수는 const가 아님)
                        constraints: BoxConstraints(maxWidth: maxWidth), 
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height * 0.8,
                          ),
                          child: buildChatArea(), 
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 모바일 레이아웃 ---
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonHeader(),
      drawer: const AppDrawer(), // AppDrawer는 CommonHeader 파일에 통합 가정
      body: ValueListenableBuilder<int?>(
        valueListenable: logic.selectedUserPk,
        builder: (context, selectedUserPk, _) {
          if (logic.isAdmin && selectedUserPk == null) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              child: buildUserList(),
            );
          }
          return Column(children: [Expanded(child: buildChatArea())]);
        },
      ),
    );
  }

  // --- 유저 목록 (웹/모바일 공통) ---
  Widget buildUserList() {
    return ValueListenableBuilder<Map<int, dynamic>>(
      valueListenable: logic.allConversations,
      builder: (context, conversations, _) {
        final entries = conversations.entries.toList();
        return ValueListenableBuilder<int?>(
          valueListenable: logic.selectedUserPk,
          builder: (context, selectedUserPk, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "사용자 목록 (${entries.length})",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final isSelected = selectedUserPk == entry.key;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.deepPurple.shade50 : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(
                            '${logic.userInfoMap.value[entry.key]?["username"] ?? "알 수 없음"} '
                            '(${logic.userInfoMap.value[entry.key]?["email"] ?? ""})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            logic.getLastMessagePreview(entry.key),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onTap: () => logic.selectUser(entry.key, isAdmin: true),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 채팅 영역 (웹/모바일 공통) ---
  Widget buildChatArea() {
    final bool isWeb = kIsWeb; 
    
    // 이 부분에서 ValueListenable 타입 문제가 해결되어야 합니다. (ChatController 수정이 필요)
    return ValueListenableBuilder<List<ChatMessage>>( 
      valueListenable: logic.messages, // ✨ ChatController 수정 후 오류 해결 가정
      builder: (context, messages, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListView.builder(
                controller: logic.scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (logic.shouldShowDateDivider(index))
                        DateDivider(date: msg.timestamp), 
                      ChatBubble(message: msg), 
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: isWeb ? EdgeInsets.zero : const EdgeInsets.all(10),
              child: InputArea(
                controller: logic.controller,
                focusNode: logic.focusNode,
                onSend: () async {
                  await logic.sendMessage(
                    onAfterSend: logic.scrollToBottom,
                    isFromAdmin: logic.isAdmin,
                    userPkOverride: logic.selectedUserPk.value,
                  );
                },
                onEnterPressed: () async {
                  await logic.handleEnterKey(
                    isFromAdmin: logic.isAdmin,
                    userPkOverride: logic.selectedUserPk.value,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// 💡 의존성 위젯 정의 (이 파일 내에 포함)
// ---------------------------------------------------------------------

// 1. 날짜 구분선 (DateDivider)
class DateDivider extends StatelessWidget {
  final DateTime date;
  const DateDivider({super.key, required this.date});
  @override
  Widget build(BuildContext context) {
    final formattedDate =
        "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("- - -   ", style: TextStyle(color: Colors.grey)),
          Text(
            formattedDate,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const Text("   - - -", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// 2. 채팅 말풍선 (ChatBubble)
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  static const _borderColor = Color(0xFF8463F6);
  static const _borderRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final timeString =
        "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: message.isMe ? _buildMyMessage(timeString) : _buildOtherMessage(timeString),
      ),
    );
  }

  List<Widget> _buildMyMessage(String timeString) => [
    _buildTime(timeString),
    const SizedBox(width: 6),
    _buildBubble(),
  ];

  List<Widget> _buildOtherMessage(String timeString) => [
    _buildBubble(),
    const SizedBox(width: 6),
    _buildTime(timeString),
  ];

  Widget _buildBubble() {
    return Flexible(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _borderColor, width: 2.0),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(_borderRadius),
              topRight: const Radius.circular(_borderRadius),
              bottomLeft: message.isMe ? const Radius.circular(_borderRadius) : Radius.zero,
              bottomRight: message.isMe ? Radius.zero : const Radius.circular(_borderRadius),
            ),
          ),
          child: Text(
            message.text,
            style: const TextStyle(fontSize: 16, color: Colors.black),
            softWrap: true,
            overflow: TextOverflow.visible,
            maxLines: null,
          ),
        ),
      ),
    );
  }

  Widget _buildTime(String timeString) {
    return Text(
      timeString,
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }
}

// 3. 입력창 + 전송 버튼 (InputArea)
class InputArea extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onEnterPressed;

  const InputArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onEnterPressed,
  });

  @override
  State<InputArea> createState() => _InputAreaState();
}

class _InputAreaState extends State<InputArea> {
  late final FocusNode _focusNode;
  late final bool isAdmin;
  
  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode;

    // isAdmin 값을 ChatScreenState에서 가져와서 초기화
    final logicState = context.findAncestorStateOfType<_ChatScreenState>();
    isAdmin = logicState?.logic.isAdmin ?? false; 
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 메시지 입력창
        Expanded(
          child: Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<Intent>(
                  onInvoke: (intent) {
                    widget.onEnterPressed();
                    return null;
                  },
                ),
              },
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: isAdmin ? '사용자에게 답변하세요' : '관리자에게 문의하세요',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 전송 버튼
        IconButton(
          icon: const Icon(Icons.send),
          color: Colors.deepPurple,
          onPressed: widget.onSend,
        ),
      ],
    );
  }
}