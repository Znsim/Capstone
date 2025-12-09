import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --------------------- 통합된 파일 경로 ---------------------

// [새 경로] 로그인 및 회원가입 통합 스크린
import './featutres/auth/sigin_screen.dart';
// 주의: 원래 'featutres' 오타가 있었으나, 'features'로 수정하여 import하는 것을 가정합니다.

// [새 경로] 메인 페이지 통합 스크린
import './featutres/home/home_screen.dart';

// [새 경로] 상태 관리 (UserProvider)
import 'state/user_provider.dart';

// [새 경로] 채팅 문의 통합 스크린
import './featutres/chat/chat_screen.dart';

// 다크모드/ 라이트 모드 전환
import './state/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 비동기 데이터 로딩을 위해 필요
  
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme(); // 저장된 테마 불러오기

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => themeProvider), // ✅ ThemeProvider 등록
      ],
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider에서 현재 테마 모드 가져오기
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      
      // ✅ 테마 모드 설정 (System, Light, Dark)
      themeMode: themeProvider.themeMode,

      // ☀️ 라이트 모드 테마 정의
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5), // 밝은 회색 배경
        primaryColor: const Color(0xFF448AFF),
        cardColor: Colors.white, // 카드 배경색
        dividerColor: Colors.grey[300],
        // 텍스트 테마 등 추가 설정 가능
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.white,
          filled: true,
        ),
      ),

      // 🌙 다크 모드 테마 정의 (Gemini 스타일)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF131314), // 어두운 배경
        primaryColor: const Color(0xFF448AFF),
        cardColor: const Color(0xFF1E1E20), // 카드 배경색
        dividerColor: Colors.grey[800],
        inputDecorationTheme: InputDecorationTheme(
          fillColor: const Color(0xFF1E1E20),
          filled: true,
        ),
      ),

      onGenerateRoute: (settings) {
        if (settings.name == '/' || settings.name == '/main') {
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
        if (settings.name == '/chatInquiry') {
          return PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ChatScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          );
        }
        if (settings.name == '/signin') {
          final isLogin = settings.arguments as bool? ?? true;
          return MaterialPageRoute(
            builder: (_) => SigninScreen(isLoginMode: isLogin),
          );
        }
        return null;
      },
    );
  }
}