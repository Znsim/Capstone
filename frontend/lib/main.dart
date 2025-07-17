import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/router.dart'; // 🔹 라우터 import
import 'pages/signin_mobile.dart';
import 'pages/signin_web.dart';
import "./pages/header.dart";

void main() {
  runApp(const MyApp());
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
    return Scaffold(appBar: const HeaderNavigationBar(), drawer: AppDrawer());
  }
}
