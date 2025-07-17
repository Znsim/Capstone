import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ← 이 줄 추가
import '../pages/signin_web.dart';
import '../pages/signin_mobile.dart';
import '../main.dart'; // main 화면 위젯

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const HomeScreen(),
  '/signin': (context) => kIsWeb ? SignInWeb() : SignInMobile(),
  '/main': (context) => HomeScreen(),
};
