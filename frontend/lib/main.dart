import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'pages/signin_mobile.dart';
import 'pages/signin_web.dart';
// import "./pages/header_mobile.dart";
// import "./pages/header_web.dart";
import './pages/main_mobile.dart';
import "./pages/main_web.dart";
import "../data/user_provider.dart";
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
        if (settings.name == '/signin') {
          final isLogin = settings.arguments as bool? ?? true;
          return MaterialPageRoute(
            builder: (_) => kIsWeb
                ? SignInWeb(isLoginMode: isLogin)
                : SignInMobile(isLoginMode: isLogin),
          );
        }
        if (settings.name == '/main') {
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
        return null;
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? const MainPageWeb()
        : const MainPageMobile(); // ← 모바일이면 바로 모바일 메인 페이지 보여줌
  }
}
