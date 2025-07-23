import 'package:flutter/material.dart';

PreferredSizeWidget buildWebHeaderBar(
  BuildContext context, {
  Function(String)? onMenuTap,
}) {
  return AppBar(
    backgroundColor: const Color(0xFF6C4EFF),
    title: const Text('Capstone', style: TextStyle(color: Colors.white)),
    actions: [
      _HeaderNavItem(text: '서비스 소개', onTap: () {}),
      _HeaderNavItem(text: '텍스트 분석', onTap: () => onMenuTap?.call('텍스트 분석')),
      _HeaderNavItem(text: '이미지 분석', onTap: () => onMenuTap?.call('이미지 분석')),
      _HeaderNavItem(text: '판례 검색', onTap: () {}),
      _HeaderNavItem(text: '안내사항', onTap: () {}),
      _HeaderNavItem(text: '고객센터', onTap: () {}),
      _HeaderNavItem(text: '마이페이지', onTap: () {}),
      _HeaderNavItem(
        text: '로그인',
        onTap: () => Navigator.pushNamed(context, '/signin', arguments: true),
      ),
      _HeaderNavItem(
        text: '회원가입',
        onTap: () => Navigator.pushNamed(context, '/signin', arguments: false),
      ),
      const SizedBox(width: 16),
    ],
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
