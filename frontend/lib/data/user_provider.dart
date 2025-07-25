// lib/provider/user_provider.dart
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  int? userPk;
  String? username;

  void setUser(int pk, String name) {
    userPk = pk;
    username = name;
    notifyListeners();
  }

  void clear() {
    userPk = null;
    username = null;
    notifyListeners();
  }
}
