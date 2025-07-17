// lib/screens/signin_logic.dart
import 'package:flutter/material.dart';

enum MessageType { none, error, success }

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

class SignInLogic extends AuthLogicBase {
  void performLogin({
    required BuildContext context,
    required VoidCallback onSuccess,
    required Map<String, String> dummyUser,
  }) {
    final email = emailController.text.trim();
    final pw = passwordController.text.trim();

    validateEmail(email, () {}); // 유효성 미리 반영
    validatePassword(pw, () {});

    if (!isEmailAndPwValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('입력값을 다시 확인해 주세요.')));
      return;
    }

    if (email == dummyUser['email'] && pw == dummyUser['password']) {
      onSuccess();
    } else {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('로그인 실패'),
          content: Text('이메일 또는 비밀번호가 일치하지 않습니다.'),
        ),
      );
    }
  }

  bool get isAllValid => isEmailAndPwValid;
}

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
}
