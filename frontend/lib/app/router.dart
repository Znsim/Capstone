import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../pages/signin_web.dart';
import '../pages/signin_mobile.dart';
import '../pages/chatInquiry_web.dart';
import '../pages/chatInquiry_mobile.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const HomeScreen(),
  '/signin': (context) => kIsWeb ? SignInWeb() : SignInMobile(),
  '/main': (context) => const HomeScreen(),
  '/chatInquiry': (context) => kIsWeb ? ChatInquiryWeb() : ChatInquiryMobile(),
};
