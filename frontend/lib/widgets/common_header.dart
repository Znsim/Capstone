import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // kIsWeb

// --- 1. 공통 유틸리티 함수 ---
Future<bool> _isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}

// --- 2. 통합 Header 위젯 ---
class CommonHeader extends StatelessWidget implements PreferredSizeWidget {
  final Function(String)? onMenuTap;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const CommonHeader({super.key, this.onMenuTap, this.scaffoldKey});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- 색상 정의 ---
    final headerBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final logoColor = const Color(0xFF8463F6); // 브랜드 컬러 (보라)
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.data ?? false;

        return AppBar(
          backgroundColor: headerBgColor,
          elevation: 0,
          
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: borderColor,
              height: 1,
            ),
          ),

          // [모바일] 햄버거 메뉴
          leading: !isWeb
              ? Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu, color: textColor),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                )
              : null,
          automaticallyImplyLeading: false,

          // [로고]
          title: InkWell(
            onTap: () => Navigator.pushNamed(context, '/main'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isWeb) ...[
                  Icon(Icons.balance, color: logoColor, size: 28),
                  const SizedBox(width: 10),
                ],
                Text(
                  'LegalCheck AI',
                  style: TextStyle(
                    color: logoColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          centerTitle: !isWeb,

          // [웹 메뉴]
          actions: isWeb
              ? _buildWebActions(context, isLoggedIn, textColor, logoColor)
              : [
                  const SizedBox(width: 48), 
                ],
        );
      },
    );
  }

  // --- 웹 전용 메뉴 구성 ---
  List<Widget> _buildWebActions(BuildContext context, bool isLoggedIn, Color textColor, Color pointColor) {
    return [
      _HeaderNavItem(text: '서비스 소개', textColor: textColor, onTap: () {}),
      if (isLoggedIn) ...[
        _HeaderNavItem(
          text: '고객센터',
          textColor: textColor,
          onTap: () => Navigator.pushNamed(context, '/chatInquiry'),
        ),
        _HeaderNavItem(text: '마이페이지', textColor: textColor, onTap: () {}),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: OutlinedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: pointColor),
              foregroundColor: pointColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('로그아웃'),
          ),
        ),
      ] else ...[
        _HeaderNavItem(
          text: '로그인',
          textColor: textColor,
          onTap: () => Navigator.pushNamed(context, '/signin', arguments: true),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/signin', arguments: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: pointColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text('회원가입'),
          ),
        ),
      ],
      const SizedBox(width: 24),
    ];
  }
}

// --- 3. 웹 네비게이션 아이템 ---
class _HeaderNavItem extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color textColor;

  const _HeaderNavItem({
    required this.text,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: textColor,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}

// --- 4. 모바일 Drawer 위젯 ---
class AppDrawer extends StatelessWidget {
  final Function(String)? onMenuTap;
  const AppDrawer({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drawerBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Drawer(
      backgroundColor: drawerBg,
      child: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          final isLoggedIn = snapshot.data ?? false;
          return Column(
            children: [
              // 드로어 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF8463F6), // 브랜드 컬러
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.balance, color: Colors.white, size: 40),
                    SizedBox(height: 12),
                    Text(
                      'LegalCheck AI',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '법적 문제 검사 서비스',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              
              // 메뉴 리스트
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 10),
                    _DrawerNavItem(
                      icon: Icons.home_outlined, 
                      text: '홈', 
                      textColor: textColor, 
                      iconColor: iconColor, 
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/main');
                      }
                    ),
                    _DrawerNavItem(
                      icon: Icons.info_outline, 
                      text: '서비스 소개', 
                      textColor: textColor, 
                      iconColor: iconColor, 
                      onTap: () => Navigator.pop(context)
                    ),
                    
                    // ✅ [삭제됨] 텍스트 분석, 이미지 분석 버튼

                    const Divider(),
                    
                    if (isLoggedIn) ...[
                      _DrawerNavItem(
                        icon: Icons.support_agent, 
                        text: '고객센터', 
                        textColor: textColor, 
                        iconColor: iconColor, 
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/chatInquiry');
                        }
                      ),
                      _DrawerNavItem(
                        icon: Icons.person_outline, 
                        text: '마이페이지', 
                        textColor: textColor, 
                        iconColor: iconColor, 
                        onTap: () => Navigator.pop(context)
                      ),
                      _DrawerNavItem(
                        icon: Icons.logout, 
                        text: '로그아웃', 
                        textColor: Colors.red, 
                        iconColor: Colors.red, 
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          Navigator.pop(context);
                          Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
                        }
                      ),
                    ] else ...[
                      _DrawerNavItem(
                        icon: Icons.login, 
                        text: '로그인', 
                        textColor: textColor, 
                        iconColor: iconColor, 
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/signin', arguments: true);
                        }
                      ),
                      _DrawerNavItem(
                        icon: Icons.person_add_outlined, 
                        text: '회원가입', 
                        textColor: textColor, 
                        iconColor: iconColor, 
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/signin', arguments: false);
                        }
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _DrawerNavItem({
    required this.icon, 
    required this.text, 
    this.textColor, 
    this.iconColor, 
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}