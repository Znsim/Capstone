import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import './signin_web.dart';
import "./signin_mobile.dart";

// ────────────── 웹/앱 헤더 함수 분리 ──────────────

// 웹 헤더 함수
Widget buildWebHeaderBar(BuildContext context, {Function(Widget)? onMenuTap}) {
  return _WebTopNavBar(onMenuTap: onMenuTap);
}

// 앱 헤더 함수
Widget buildAppHeaderBar(BuildContext context, {Function(Widget)? onMenuTap}) {
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

// ────────────── 헤더 네비게이션 바 ──────────────

class HeaderNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  final Function(Widget)? onMenuTap;
  const HeaderNavigationBar({super.key, this.onMenuTap});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? buildWebHeaderBar(context, onMenuTap: onMenuTap)
        : buildAppHeaderBar(context, onMenuTap: onMenuTap);
  }
}

// ────────────── 웹 상단 메뉴 ──────────────

class _WebTopNavBar extends StatelessWidget {
  final Function(Widget)? onMenuTap;
  const _WebTopNavBar({this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          constraints: const BoxConstraints(minWidth: 1000),
          width: MediaQuery.of(context).size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 좌측 메뉴 그룹
              Row(
                children: [
                  // 로고
                  InkWell(
                    child: Container(
                      width: 65,
                      height: 30,
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: const Text(
                        'Capstone',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const _NavItem(text: '서비스 소개'),
                  const _NavItem(text: '텍스트 분석'),
                  const _NavItem(text: '이미지 분석'),
                  const _NavItem(text: '판례 검색'),
                  const _NavItem(text: '안내사항'),
                  const _NavItem(text: '고객센터'),
                ],
              ),

              // 우측 메뉴 그룹
              Row(
                children: [
                  const _NavItem(text: '마이페이지'),
                  const Text('｜'),
                  _NavItem(
                    text: '로그인',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/signin',
                      arguments: true,
                    ), // true = 로그인탭
                  ),
                  const Text('｜'),
                  _NavItem(
                    text: '회원가입',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/signin',
                      arguments: false,
                    ), // false = 회원가입탭
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────── 앱 서랍 메뉴 ──────────────

class AppDrawer extends StatelessWidget {
  final Function(Widget)? onMenuTap;
  const AppDrawer({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              '메뉴',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          _DrawerNavItem(text: '서비스 소개', onTap: () => Navigator.pop(context)),
          _DrawerNavItem(text: '텍스트 분석', onTap: () => Navigator.pop(context)),
          _DrawerNavItem(text: '이미지 분석', onTap: () => Navigator.pop(context)),
          _DrawerNavItem(text: '판례 검색', onTap: () => Navigator.pop(context)),
          _DrawerNavItem(text: '안내사항', onTap: () => Navigator.pop(context)),
          _DrawerNavItem(text: '고객센터', onTap: () => Navigator.pop(context)),
          const Divider(),
          _DrawerNavItem(text: '마이페이지', onTap: () => Navigator.pop(context)),
          // 헤더바에서
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

// ────────────── 웹 메뉴 아이템 ──────────────

class _NavItem extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _NavItem({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }
}

// ────────────── 앱 메뉴 아이템 ──────────────

class _DrawerNavItem extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _DrawerNavItem({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(text), onTap: onTap);
  }
}
