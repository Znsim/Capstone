// header_mobile.dart
import 'package:flutter/material.dart';

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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF8463F6)),
            child: Text(
              '메뉴',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          _DrawerNavItem(text: '서비스 소개', onTap: () => Navigator.pop(context)),
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
          _DrawerNavItem(text: '판례 검색', onTap: () => Navigator.pop(context)),
          _DrawerNavItem(text: '안내사항', onTap: () => Navigator.pop(context)),
          _DrawerNavItem(text: '고객센터', onTap: () => Navigator.pop(context)),
          const Divider(),
          _DrawerNavItem(text: '마이페이지', onTap: () => Navigator.pop(context)),
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
