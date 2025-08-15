import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/chatInquiryLogic.dart';
import '../pages/header_mobile.dart';

// 앱 채팅 문의
class ChatInquiryMobile extends StatefulWidget {
  const ChatInquiryMobile({super.key});

  @override
  State<ChatInquiryMobile> createState() => _ChatInquiryMobileState();
}

class _ChatInquiryMobileState extends State<ChatInquiryMobile> {
  final ChatInquiryLogic logic = ChatInquiryLogic();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 사용자 정보 로드 및 초기화
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdminFlag = prefs.getBool('isAdmin') ?? false;
    final userPk = prefs.getInt('userPk') ?? 0;

    await logic.initialize(isAdmin: isAdminFlag, userPk: userPk);

    setState(() {
      _isInitialized = true;
    });
  }

  // 리소스 정리
  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 화면
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: buildAppHeaderBar(context),
        drawer: const AppDrawer(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 채팅창->목록 뒤로가기
    return WillPopScope(
      onWillPop: () async {
        if (logic.isAdmin && logic.selectedUserPk.value != null) {
          logic.selectedUserPk.value = null;
          return false;
        }
        return true;
      },
      // 채팅
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: buildAppHeaderBar(context),
        drawer: const AppDrawer(),
        body: ValueListenableBuilder<int?>(
          valueListenable: logic.selectedUserPk,
          builder: (context, selectedUserPk, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                // 관리자: 유저 선택 전 목록
                if (logic.isAdmin && selectedUserPk == null) {
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.white,
                    child: buildUserList(),
                  );
                }
                // 공통: 채팅창
                return Column(children: [Expanded(child: buildChatArea())]);
              },
            );
          },
        ),
      ),
    );
  }

  // 관리자: 유저 목록
  Widget buildUserList() {
    return ValueListenableBuilder<Map<int, dynamic>>(
      valueListenable: logic.allConversations, // 전체 대화 상태
      builder: (context, conversations, _) {
        final entries = conversations.entries
            .toList(); // List로 변환해서 index 접근 개선

        return ValueListenableBuilder<int?>(
          valueListenable: logic.selectedUserPk, // 선택된 유저 상태
          builder: (context, selectedUserPk, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목+대화방 수
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "사용자 목록 (${entries.length})",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                // 사용자 목록 리스트뷰
                Expanded(
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final isSelected = selectedUserPk == entry.key;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          // 선택된 유저 색상
                          color: isSelected
                              ? Colors.deepPurple.shade50
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          // 유저 이름+이메일
                          title: Text(
                            '${logic.userInfoMap.value[entry.key]?["username"] ?? "알 수 없음"} '
                            '(${logic.userInfoMap.value[entry.key]?["email"] ?? ""})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // 미리보기 대화
                          subtitle: Text(
                            logic.getLastMessagePreview(entry.key),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          // 유저 선택: 대화 조회
                          onTap: () =>
                              logic.selectUser(entry.key, isAdmin: true),
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

  // 공통: 채팅창
  Widget buildChatArea() {
    return ValueListenableBuilder<List<ChatMessage>>(
      valueListenable: logic.messages, // 메시지 상태
      builder: (context, messages, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 채팅창
            Expanded(
              child: ListView.builder(
                controller: logic.scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 날짜 구분선
                      if (logic.shouldShowDateDivider(index))
                        DateDivider(date: msg.timestamp),
                      // 말풍선
                      ChatBubble(message: msg),
                    ],
                  );
                },
              ),
            ),
            // 입력창
            Padding(
              padding: const EdgeInsets.all(10),
              child: InputArea(
                controller: logic.controller,
                focusNode: logic.focusNode,
                // 전송 버튼
                onSend: () async {
                  await logic.sendMessage(
                    onAfterSend: logic.scrollToBottom,
                    isFromAdmin: logic.isAdmin,
                    userPkOverride: logic.selectedUserPk.value,
                  );
                },
                // 엔터 키
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

// 입력창 + 전송 버튼--------------------------------
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

    // 전역 logic 객체에서 관리자 여부 불러오기
    final logic = context
        .findAncestorStateOfType<_ChatInquiryMobileState>()
        ?.logic;
    isAdmin = logic?.isAdmin ?? false;
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
                    widget.onEnterPressed(); // 엔터
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
                  hintStyle: TextStyle(color: Colors.grey),
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

// 채팅 말풍선----------------------------------
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  static const _borderColor = Color(0xFF8463F6);
  static const _borderRadius = 16.0;

  // 전송 직후 ui에서 먼저 그림, 불러올 땐 db 시간
  @override
  Widget build(BuildContext context) {
    // 시:분 형태로 시간 포맷
    final timeString =
        "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        // 내가 보내면 오른쪽 말풍선
        mainAxisAlignment: message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        // 시간, 말풍선 정렬
        children: message.isMe
            ? _buildMyMessage(timeString)
            : _buildOtherMessage(timeString),
      ),
    );
  }

  // 내가 보낸 메시지
  List<Widget> _buildMyMessage(String timeString) => [
    _buildTime(timeString),
    const SizedBox(width: 6),
    _buildBubble(),
  ];

  // 상대방이 보낸 메시지
  List<Widget> _buildOtherMessage(String timeString) => [
    _buildBubble(),
    const SizedBox(width: 6),
    _buildTime(timeString),
  ];

  // 말풍선 UI
  Widget _buildBubble() {
    return Flexible(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400), // 최대 너비
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _borderColor, width: 2.0),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(_borderRadius),
              topRight: const Radius.circular(_borderRadius),
              // 말풍선 하단 둥글기
              bottomLeft: message.isMe
                  ? const Radius.circular(_borderRadius)
                  : Radius.zero,
              bottomRight: message.isMe
                  ? Radius.zero
                  : const Radius.circular(_borderRadius),
            ),
          ),
          // 메시지
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

  // 시간 텍스트
  Widget _buildTime(String timeString) {
    return Text(
      timeString,
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }
}

// 날짜 구분선-----------------------------------
class DateDivider extends StatelessWidget {
  final DateTime date;

  const DateDivider({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    // yyyy.MM.dd 형태로 날짜 포맷
    final formattedDate =
        "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("- - -   ", style: TextStyle(color: Colors.grey)),
          // 날짜 텍스트
          Text(
            formattedDate,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const Text("   - - -", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
