import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart'; // kIsWeb 필요 시 사용
import 'package:provider/provider.dart'; // Provider 사용 시 필요 (없으면 주석 처리)
import './auth_controller.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

enum MessageType { none, error, success }

class SigninScreen extends StatefulWidget {
  final bool isLoginMode;

  const SigninScreen({Key? key, this.isLoginMode = true}) : super(key: key);

  @override
  _SigninScreenState createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final signInLogic = SignInLogic();
  final signUpLogic = SignUpLogic();

  bool isLoginMode = true;
  bool isPasswordVisible = false;
  bool isAutoLogin = false;

  @override
  void initState() {
    super.initState();
    isLoginMode = widget.isLoginMode;
    _checkAlreadyLoggedIn();
  }

  void _checkAlreadyLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/main');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 현재 테마 모드 감지
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- 테마별 색상 정의 ---
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFF8463F6); // 배경색
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white; // 카드 배경색
    final textColor = isDark ? Colors.white : Colors.black87; // 기본 텍스트 색상
    final subTextColor = isDark ? Colors.grey[400] : Colors.black54; // 보조 텍스트 색상
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.white; // 입력창 배경색
    final primaryColor = const Color(0xFF8463F6); // 메인 브랜드 컬러 (보라색)

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor, // ✅ 동적 카드 색상 적용
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 로고 및 타이틀
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.balance, color: primaryColor, size: 28),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/main');
                      },
                      child: Text(
                        'LegalCheck AI',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '법적 문제 검사 AI 서비스',
                    style: TextStyle(fontSize: 14, color: subTextColor),
                  ),
                ),
                const SizedBox(height: 24),

                // 탭 버튼 (로그인 / 회원가입)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isLoginMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isLoginMode 
                                ? primaryColor 
                                : (isDark ? Colors.grey[800] : Colors.grey[200]), // 비활성 버튼 색상
                          ),
                          child: Center(
                            child: Text(
                              '로그인',
                              style: TextStyle(
                                color: isLoginMode 
                                    ? Colors.white 
                                    : (isDark ? Colors.grey[400] : Colors.black87),
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
                            color: !isLoginMode 
                                ? primaryColor 
                                : (isDark ? Colors.grey[800] : Colors.grey[200]),
                          ),
                          child: Center(
                            child: Text(
                              '회원가입',
                              style: TextStyle(
                                color: !isLoginMode 
                                    ? Colors.white 
                                    : (isDark ? Colors.grey[400] : Colors.black87),
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

                // 입력 폼 분기
                isLoginMode 
                    ? _buildLoginForm(textColor, inputFillColor, isDark, primaryColor) 
                    : _buildSignUpForm(textColor, inputFillColor, isDark, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // [로그인 폼]
  Widget _buildLoginForm(Color textColor, Color? inputFillColor, bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('이메일', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        TextField(
          controller: signInLogic.emailController,
          style: TextStyle(color: textColor), // 입력 텍스트 색상
          onChanged: (value) =>
              signInLogic.validateEmail(value, () => setState(() {})),
          decoration: _inputDecoration('이메일을 입력해 주세요', inputFillColor, isDark, primaryColor).copyWith(
            errorText: (!signInLogic.isEmailValid && signInLogic.emailMsg.isNotEmpty)
                ? signInLogic.emailMsg
                : null,
            helperText: (signInLogic.isEmailValid && signInLogic.emailMsg.isNotEmpty)
                ? signInLogic.emailMsg
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text('비밀번호', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        TextField(
          obscureText: !isPasswordVisible,
          controller: signInLogic.passwordController,
          style: TextStyle(color: textColor),
          onChanged: (value) =>
              signInLogic.validatePassword(value, () => setState(() {})),
          decoration: _inputDecoration('비밀번호를 입력하세요', inputFillColor, isDark, primaryColor).copyWith(
            errorText: signInLogic.pwMsg.isNotEmpty ? signInLogic.pwMsg : null,
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() => isPasswordVisible = !isPasswordVisible);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: isAutoLogin,
              activeColor: primaryColor,
              side: BorderSide(color: isDark ? Colors.grey : Colors.black54), // 체크박스 테두리
              onChanged: (value) {
                setState(() {
                  isAutoLogin = value ?? false;
                });
              },
            ),
            Text('로그인 상태 유지', style: TextStyle(color: textColor)),
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
              backgroundColor: primaryColor,
            ),
            child: const Text(
              '로그인',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '비밀번호를 잊으셨나요?',
            style: TextStyle(color: primaryColor, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // [회원가입 폼]
  Widget _buildSignUpForm(Color textColor, Color? inputFillColor, bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('이름', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        TextField(
          controller: signUpLogic.nameController,
          style: TextStyle(color: textColor),
          onChanged: (value) =>
              signUpLogic.validateName(value, () => setState(() {})),
          decoration: _inputDecoration('이름을 입력해 주세요', inputFillColor, isDark, primaryColor).copyWith(
            errorText: signUpLogic.nameMsgType == MessageType.error ? signUpLogic.nameMsg : null,
            helperText: signUpLogic.nameMsgType == MessageType.success ? signUpLogic.nameMsg : null,
            helperStyle: const TextStyle(color: Colors.green),
          ),
        ),
        const SizedBox(height: 16),
        Text('이메일', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        TextField(
          controller: signUpLogic.emailController,
          style: TextStyle(color: textColor),
          onChanged: (value) {
            signUpLogic.validateEmail(value, () => setState(() {}));
          },
          decoration: _inputDecoration('이메일을 입력해 주세요', inputFillColor, isDark, primaryColor).copyWith(
            errorText: signUpLogic.emailMsgType == MessageType.error ? signUpLogic.emailMsg : null,
            helperText: signUpLogic.emailMsgType == MessageType.success ? signUpLogic.emailMsg : null,
            helperStyle: const TextStyle(color: Colors.green),
          ),
        ),
        const SizedBox(height: 16),
        Text('비밀번호', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        TextField(
          obscureText: !isPasswordVisible,
          controller: signUpLogic.passwordController,
          style: TextStyle(color: textColor),
          onChanged: (value) {
            signUpLogic.validatePassword(value, () => setState(() {}));
            signUpLogic.validatePasswordConfirm(signUpLogic.pwConfirmController.text, () => setState(() {}));
          },
          decoration: _inputDecoration('비밀번호를 입력하세요', inputFillColor, isDark, primaryColor).copyWith(
            errorText: signUpLogic.pwMsgType == MessageType.error ? signUpLogic.pwMsg : null,
            helperText: signUpLogic.pwMsgType == MessageType.success ? signUpLogic.pwMsg : null,
            helperStyle: const TextStyle(color: Colors.green),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() => isPasswordVisible = !isPasswordVisible);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('비밀번호 확인', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          controller: signUpLogic.pwConfirmController,
          style: TextStyle(color: textColor),
          onChanged: (value) =>
              signUpLogic.validatePasswordConfirm(value, () => setState(() {})),
          decoration: _inputDecoration('비밀번호를 다시 입력해 주세요', inputFillColor, isDark, primaryColor).copyWith(
            errorText: signUpLogic.pwConfirmMsgType == MessageType.error ? signUpLogic.pwConfirmMsg : null,
            helperText: signUpLogic.pwConfirmMsgType == MessageType.success ? signUpLogic.pwConfirmMsg : null,
            helperStyle: const TextStyle(color: Colors.green),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (signUpLogic.isAllValid)
                ? () async {
                    final success = await signUpLogic.performjoin(context: context);
                    if (success) {
                      Navigator.pushNamed(context, '/main');
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: primaryColor,
              disabledBackgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
            ),
            child: const Text(
              '회원가입',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ 공통 Input Decoration 스타일 헬퍼
  InputDecoration _inputDecoration(String hint, Color? fillColor, bool isDark, Color primaryColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.all(16),
      // 기본 테두리
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      // 비활성 테두리 (평상시)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      // 포커스 테두리 (입력 중)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    );
  }
}