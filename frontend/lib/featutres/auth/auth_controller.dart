// [기존 파일 위치: lib/pages/signLogic.dart]
// [새로운 파일 위치: lib/features/auth/auth_controller.dart]

//경로 설정
import 'package:flutter/material.dart';
import "../../services/user_api.dart";
import 'package:provider/provider.dart';
import '../../state/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// [기존 파일 위치: lib/pages/signLogic.dart]
enum MessageType { none, error, success }

// [기존 파일 위치: lib/pages/signLogic.dart]
abstract class AuthLogicBase {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String emailMsg = '';
  String pwMsg = '';
  MessageType emailMsgType = MessageType.none;
  MessageType pwMsgType = MessageType.none;

  bool isEmailValid = false;
  bool isPwValid = false;

  // 로그인 폼에선 성공 메시지 안 뜨게 수정!
  void validateEmail(String value, VoidCallback update) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (value.trim().isEmpty) {
      emailMsg = '이메일을 입력해 주세요.';
      emailMsgType = MessageType.error;
      isEmailValid = false;
    } else if (!regex.hasMatch(value.trim())) {
      emailMsg = '유효한 이메일 형식이 아닙니다.';
      emailMsgType = MessageType.error;
      isEmailValid = false;
    } else {
      emailMsg = '';
      emailMsgType = MessageType.none;
      isEmailValid = true;
    }
    update();
  }

  void validatePassword(String value, VoidCallback update) {
    if (value.trim().isEmpty) {
      pwMsg = '비밀번호를 입력해 주세요.';
      pwMsgType = MessageType.error;
      isPwValid = false;
    } else {
      pwMsg = '';
      pwMsgType = MessageType.none;
      isPwValid = true;
    }
    update();
  }

  bool get isEmailAndPwValid => isEmailValid && isPwValid;
}

// [기존 파일 위치: lib/pages/signLogic.dart]
class SignInLogic extends AuthLogicBase {
  Future<void> performLogin({
    required BuildContext context,
    required VoidCallback onSuccess,
    required bool isAutoLogin,
  }) async {
    final email = emailController.text.trim();
    final pw = passwordController.text.trim();

    validateEmail(email, () {});
    validatePassword(pw, () {});

    if (!isEmailAndPwValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('입력값을 다시 확인해 주세요.')));
      return;
    }

    try {
      // [주의] ApiService 클래스가 lib/services/user_api.dart 파일에 있어야 합니다.
      final result = await ApiService.login(email, pw);

      print('로그인 응답: $result');

      // 서버 응답에서 user 정보 꺼내기 (토큰 key - value 구조)
      final userMap = result!.values.first;
      final userPk = userMap['id'];
      final username = userMap['username'];
      final isAdmin = userMap['is_admin'] ?? false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userPk', userPk);
      await prefs.setString('username', username);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isAdmin', isAdmin);

      // Provider에 저장
      // [주의] UserProvider 클래스가 lib/state/user_provider.dart 파일에 있어야 합니다.
      context.read<UserProvider>().setUser(userPk, username); 
      onSuccess();
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('로그인 실패'),
          content: Text(
            e is Exception
                ? e.toString().replaceAll('Exception: ', '')
                : e.toString(),
          ),
        ),
      );
    }
  }

  bool get isAllValid => isEmailAndPwValid;
}

// [기존 파일 위치: lib/pages/signLogic.dart]
// 회원가입 로직
class SignUpLogic extends AuthLogicBase {
  final nameController = TextEditingController();
  final pwConfirmController = TextEditingController();

  String nameMsg = '';
  String pwConfirmMsg = '';
  MessageType nameMsgType = MessageType.none;
  MessageType pwConfirmMsgType = MessageType.none;

  bool isNameValid = false;
  bool isPwConfirmValid = false;

  void validateName(String value, VoidCallback update) {
    if (value.contains(' ')) {
      nameMsg = '공백 없이 입력해 주세요.';
      nameMsgType = MessageType.error;
      isNameValid = false;
    } else if (value.trim().length >= 2) {
      // [주의] 유효성 검사 성공 시에도 '올바른 이름입니다.' 메시지가 뜨지 않게 수정하는 것을 고려해 보세요.
      nameMsg = '올바른 이름입니다.'; 
      nameMsgType = MessageType.success;
      isNameValid = true;
    } else {
      nameMsg = '이름은 2자 이상이어야 합니다.';
      nameMsgType = MessageType.error;
      isNameValid = false;
    }
    update();
  }

  void validatePasswordConfirm(String value, VoidCallback update) {
    if (value == passwordController.text) {
      // [주의] 유효성 검사 성공 시에도 '비밀번호가 일치합니다.' 메시지가 뜨지 않게 수정하는 것을 고려해 보세요.
      pwConfirmMsg = '비밀번호가 일치합니다.'; 
      pwConfirmMsgType = MessageType.success;
      isPwConfirmValid = true;
    } else {
      pwConfirmMsg = '비밀번호가 일치하지 않습니다.';
      pwConfirmMsgType = MessageType.error;
      isPwConfirmValid = false;
    }
    update();
  }

  bool get isAllValid => isNameValid && isEmailAndPwValid && isPwConfirmValid;

  // 회원가입 API 호출 함수
  Future<bool> performjoin({required BuildContext context}) async {
    final email = emailController.text.trim();
    final pw = passwordController.text.trim();
    final name = nameController.text.trim();

    if (!isAllValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('입력값을 다시 확인해 주세요.')));
      return false;
    }

    try {
      // [주의] ApiService 클래스가 lib/services/user_api.dart 파일에 있어야 합니다.
      await ApiService.join(username: name, email: email, password: pw); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 메일이 전송되었습니다. 메일함을 확인하세요.')),
      );

      return true;
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('회원가입 실패'),
          content: Text(
            e is Exception
                ? e.toString().replaceAll('Exception: ', '')
                : e.toString(),
          ),
        ),
      );
      return false;
    }
  }
}