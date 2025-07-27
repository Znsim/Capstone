import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../pages/signin_web.dart';
import '../pages/signin_mobile.dart';
import '../main.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const HomeScreen(),
  '/signin': (context) => kIsWeb ? SignInWeb() : SignInMobile(),
  '/main': (context) => const HomeScreen(),
};
