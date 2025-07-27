//모바일 전용 로그인 화면
import "package:flutter/material.dart";
import "./signLogic.dart";
import 'package:shared_preferences/shared_preferences.dart';

class SignInMobile extends StatefulWidget {
  final bool isLoginMode;

  const SignInMobile({Key? key, this.isLoginMode = true}) : super(key: key);

  @override
  _SignInMobileState createState() => _SignInMobileState();
}

class _SignInMobileState extends State<SignInMobile> {
  final signInLogic = SignInLogic();
  final signUpLogic = SignUpLogic();

  bool isLoginMode = true;
  bool isEmailVerified = false;
  bool isPasswordVisible = false;
  bool isAutoLogin = false;

  //이메일 인증
  Future<bool> sendVerificationEmailToServer(String email) async {
    // 실제 구현 전 테스트용
    await Future.delayed(const Duration(seconds: 1));
    //실제 이메일 인증 API 요청으로 바꾸기
    return true; // 항상 성공 처리
  }

  void initState() {
    super.initState();
    isLoginMode = widget.isLoginMode;
    _checkAlreadyLoggedIn();
  }

  void _checkAlreadyLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      // 이미 로그인된 상태면 메인으로 강제 이동 (웹/모바일 상관없이 작동)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/main');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8463F6),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.balance, color: Color(0xFF8463F6)),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/main');
                      },
                      child: Text(
                        'LegalCheck AI',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8463F6),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    '법적 문제 검사 AI 서비스',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 24),

                // 👇 로그인 / 회원가입 선택 탭
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isLoginMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: isLoginMode
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF8463F6),
                                      Color(0xFFB393F6),
                                    ],
                                  )
                                : null,
                            color: isLoginMode ? null : Colors.grey.shade200,
                          ),
                          child: Center(
                            child: Text(
                              '로그인',
                              style: TextStyle(
                                color: isLoginMode
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isLoginMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: !isLoginMode
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF8463F6),
                                      Color(0xFFB393F6),
                                    ],
                                  )
                                : null,
                            color: !isLoginMode ? null : Colors.grey.shade200,
                          ),
                          child: Center(
                            child: Text(
                              '회원가입',
                              style: TextStyle(
                                color: !isLoginMode
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 👇 아래는 선택된 입력 화면
                // 👇 아래는 선택된 입력 화면
                isLoginMode ? _buildLoginForm() : _buildSignUpForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //로그인 폼
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('이메일', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: signInLogic.emailController,
          onChanged: (value) =>
              signInLogic.validateEmail(value, () => setState(() {})),
          decoration: InputDecoration(
            hintText: '이메일을 입력해 주세요',
            errorText:
                (!signInLogic.isEmailValid && signInLogic.emailMsg.isNotEmpty)
                ? signInLogic.emailMsg
                : null,
            helperText:
                (signInLogic.isEmailValid && signInLogic.emailMsg.isNotEmpty)
                ? signInLogic.emailMsg
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        const Text('비밀번호', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          obscureText: !isPasswordVisible,
          controller: signInLogic.passwordController,
          onChanged: (value) =>
              signInLogic.validatePassword(value, () => setState(() {})),
          decoration: InputDecoration(
            hintText: '비밀번호를 입력하세요',
            errorText: signInLogic.pwMsg.isNotEmpty ? signInLogic.pwMsg : null,
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() => isPasswordVisible = !isPasswordVisible);
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: isAutoLogin,
              onChanged: (value) {
                setState(() {
                  isAutoLogin = value ?? false;
                });
              },
            ),
            const Text('로그인 상태 유지'),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              signInLogic.performLogin(
                context: context,
                onSuccess: () {
                  Navigator.pushNamed(context, '/main');
                },
                isAutoLogin: isAutoLogin,
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xFF8463F6),
            ),
            child: const Text(
              '로그인',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            '비밀번호를 잊으셨나요?',
            style: TextStyle(color: Color(0xFF8463F6), fontSize: 13),
          ),
        ),
      ],
    );
  }

  //회원가입 폼
  Widget _buildSignUpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이름 입력
        const Text('이름', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: signUpLogic.nameController,
          onChanged: (value) =>
              signUpLogic.validateName(value, () => setState(() {})),
          decoration: InputDecoration(
            hintText: '이름을 입력해 주세요',
            errorText: signUpLogic.nameMsgType == MessageType.error
                ? signUpLogic.nameMsg
                : null,
            helperText: signUpLogic.nameMsgType == MessageType.success
                ? signUpLogic.nameMsg
                : null,
            helperStyle: const TextStyle(color: Colors.green),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // 이메일 입력 + 인증
        const Text('이메일', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: signUpLogic.emailController,
                onChanged: (value) {
                  signUpLogic.validateEmail(value, () => setState(() {}));
                  // 이메일 인증 상태는 입력값이 바뀌면 다시 false 처리
                  setState(() => isEmailVerified = false);
                },
                decoration: InputDecoration(
                  hintText: '이메일을 입력해 주세요',
                  errorText: signUpLogic.emailMsgType == MessageType.error
                      ? signUpLogic.emailMsg
                      : null,
                  helperText: signUpLogic.emailMsgType == MessageType.success
                      ? signUpLogic.emailMsg
                      : null,
                  helperStyle: const TextStyle(color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              // onPressed: (!signUpLogic.isEmailValid || isEmailVerified)
              //     ? null
              //     : () async {
              //         final email = signUpLogic.emailController.text.trim();
              //         // 서버에 이메일 인증 요청 API 호출
              //         final result = await sendVerificationEmailToServer(email);
              //         if (result) {
              //           ScaffoldMessenger.of(context).showSnackBar(
              //             const SnackBar(
              //               content: Text('인증 링크가 이메일로 발송되었습니다. 메일함을 확인하세요.'),
              //             ),
              //           );
              //           // 인증 메일 발송 상태 안내 (아직 인증 완료 X)
              //         } else {
              //           ScaffoldMessenger.of(context).showSnackBar(
              //             const SnackBar(content: Text('이메일 인증 요청에 실패했습니다.')),
              //           );
              //         }
              //       },
              //임시
              onPressed: (!signUpLogic.isEmailValid || isEmailVerified)
                  ? null
                  : () async {
                      // 여기에 선언!
                      final email = signUpLogic.emailController.text.trim();

                      final result = await sendVerificationEmailToServer(email);
                      if (result) {
                        setState(() {
                          isEmailVerified = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('이메일 인증이 완료되었습니다!')),
                        );
                      }
                    },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8463F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              child: const Text('인증'),
            ),
          ],
        ),

        // 인증 안내문구 (메일을 보냈음을 명확히)
        if (!isEmailVerified && signUpLogic.isEmailValid)
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: Text(
              '입력하신 이메일로 인증 링크가 발송됩니다.',
              style: TextStyle(color: Colors.deepPurple, fontSize: 13),
            ),
          ),
        if (isEmailVerified)
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: Text(
              '이메일 인증이 완료되었습니다.',
              style: TextStyle(color: Colors.green, fontSize: 13),
            ),
          ),
        const SizedBox(height: 16),

        // 비밀번호 입력
        const Text('비밀번호', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          obscureText: !isPasswordVisible,
          controller: signUpLogic.passwordController,
          onChanged: (value) =>
              signUpLogic.validatePassword(value, () => setState(() {})),
          decoration: InputDecoration(
            hintText: '비밀번호를 입력하세요',
            errorText: signUpLogic.pwMsgType == MessageType.error
                ? signUpLogic.pwMsg
                : null,
            helperText: signUpLogic.pwMsgType == MessageType.success
                ? signUpLogic.pwMsg
                : null,
            helperStyle: const TextStyle(color: Colors.green),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() => isPasswordVisible = !isPasswordVisible);
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // 비밀번호 확인 입력
        const Text('비밀번호 확인', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          controller: signUpLogic.pwConfirmController,
          onChanged: (value) =>
              signUpLogic.validatePasswordConfirm(value, () => setState(() {})),
          decoration: InputDecoration(
            hintText: '비밀번호를 다시 입력해 주세요',
            errorText: signUpLogic.pwConfirmMsgType == MessageType.error
                ? signUpLogic.pwConfirmMsg
                : null,
            helperText: signUpLogic.pwConfirmMsgType == MessageType.success
                ? signUpLogic.pwConfirmMsg
                : null,
            helperStyle: const TextStyle(color: Colors.green),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),

        // 회원가입 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (isEmailVerified && signUpLogic.isAllValid)
                ? () {
                    // 회원가입 완료 처리 (ex: 서버로 회원정보 전송)
                    Navigator.pushNamed(context, '/main');
                  }
                : null, // 비활성화
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xFF8463F6),
            ),
            child: const Text(
              '회원가입',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
