import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

PreferredSizeWidget buildWebHeaderBar(
  BuildContext context, {
  Function(String)? onMenuTap,
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.data ?? false;
        return AppBar(
          backgroundColor: const Color(0xFF6C4EFF),
          title: const Text('Capstone', style: TextStyle(color: Colors.white)),
          actions: [
            _HeaderNavItem(text: '서비스 소개', onTap: () {}),
            _HeaderNavItem(
              text: '텍스트 분석',
              onTap: () => onMenuTap?.call('텍스트 분석'),
            ),
            _HeaderNavItem(
              text: '이미지 분석',
              onTap: () => onMenuTap?.call('이미지 분석'),
            ),
            _HeaderNavItem(text: '판례 검색', onTap: () {}),
            _HeaderNavItem(text: '안내사항', onTap: () {}),
            _HeaderNavItem(text: '고객센터', onTap: () {}),
            _HeaderNavItem(text: '마이페이지', onTap: () {}),
            if (isLoggedIn)
              _HeaderNavItem(
                text: '로그아웃',
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/signin',
                    (route) => false,
                  );
                },
              )
            else ...[
              _HeaderNavItem(
                text: '로그인',
                onTap: () =>
                    Navigator.pushNamed(context, '/signin', arguments: true),
              ),
              _HeaderNavItem(
                text: '회원가입',
                onTap: () =>
                    Navigator.pushNamed(context, '/signin', arguments: false),
              ),
            ],
            const SizedBox(width: 16),
          ],
        );
      },
    ),
  );
}

class _HeaderNavItem extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _HeaderNavItem({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}

Future<bool> _isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}
