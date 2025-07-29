// header_mobile.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

PreferredSizeWidget buildAppHeaderBar(
  BuildContext context, {
  Function(String)? onMenuTap,
}) {
  return AppBar(
    title: const Text('Capstone'),
    leading: Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    ),
  );
}

class AppDrawer extends StatelessWidget {
  final Function(String)? onMenuTap;
  const AppDrawer({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          final isLoggedIn = snapshot.data ?? false;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF8463F6)),
                child: Text(
                  '메뉴',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              _DrawerNavItem(
                text: '홈',
                onTap: () {
                  Navigator.pop(context); // 드로어 닫기
                  Navigator.pushNamed(context, '/main'); // 메인 페이지로 이동
                },
              ),
              _DrawerNavItem(
                text: '서비스 소개',
                onTap: () => Navigator.pop(context),
              ),
              _DrawerNavItem(
                text: '텍스트 분석',
                onTap: () {
                  Navigator.pop(context);
                  onMenuTap?.call('텍스트 분석');
                },
              ),
              _DrawerNavItem(
                text: '이미지 분석',
                onTap: () {
                  Navigator.pop(context);
                  onMenuTap?.call('이미지 분석');
                },
              ),

              // 👇 로그인 상태에 따라 다른 버튼 보여주기
              if (isLoggedIn) ...[
                _DrawerNavItem(
                  text: '고객센터',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/chatInquiry');
                  },
                ),
                const Divider(),
                _DrawerNavItem(
                  text: '마이페이지',
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerNavItem(
                  text: '로그아웃',
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/signin',
                      (route) => false,
                    );
                  },
                ),
              ] else ...[
                _DrawerNavItem(
                  text: '로그인',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/signin', arguments: true);
                  },
                ),
                _DrawerNavItem(
                  text: '회원가입',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/signin', arguments: false);
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _DrawerNavItem({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(text), onTap: onTap);
  }
}

Future<bool> _isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}
