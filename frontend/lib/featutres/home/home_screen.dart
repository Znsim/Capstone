import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 사용을 위해 필요

// 통합된 헤더와 드로어 import
import '../../widgets/common_header.dart';
import '../../state/theme_provider.dart'; // ThemeProvider import
import 'package:provider/provider.dart';  // Provider import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  
  // 상태 변수
  bool _isAnalyzed = false;
  String _analyzedText = "";
  int _analyzedTextLength = 0;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _analyzedTextLength = _textController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void handleMenuTap(String selected) {
    _resetCheck();
  }

  void _startCheck() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _analyzedText = text;
      _isAnalyzed = true;
      FocusScope.of(context).unfocus();
    });
  }

  void _resetCheck() {
    setState(() {
      _textController.clear();
      _isAnalyzed = false;
      _analyzedText = "";
      _analyzedTextLength = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- 디자인 테마 색상 정의 (보라색 테마로 변경) ---
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    
    // ✅ [수정됨] 메인 컬러를 보라색 계열로 변경
    // 다크모드: 밝은 보라 (가시성 확보), 라이트모드: 진한 보라 (브랜드 컬러)
    final primaryColor = isDark ? const Color(0xFF8463F6) : const Color(0xFF6C4EFF);
    
    final accentColor = const Color(0xFFE74C3C); // 위험 색상 (빨강) 유지
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: CommonHeader(onMenuTap: handleMenuTap),
      drawer: isWeb ? null : AppDrawer(onMenuTap: handleMenuTap),
      
      // 테마 변경 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<ThemeProvider>().toggleTheme(!isDark);
        },
        backgroundColor: cardColor,
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          color: isDark ? Colors.yellow : Colors.black87,
        ),
      ),

      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isWeb ? 900 : double.infinity),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _isAnalyzed
              ? _buildResultUI(
                  textColor, subTextColor, cardColor, primaryColor, accentColor, borderColor, isDark)
              : _buildInputUI(
                  textColor, subTextColor, cardColor, primaryColor, borderColor),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 1. 입력 UI (문서 에디터 스타일)
  // --------------------------------------------------------------------------
  Widget _buildInputUI(Color textColor, Color? subTextColor, Color cardColor,
      Color primaryColor, Color borderColor) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.gavel_rounded, size: 64, color: primaryColor), // 보라색 아이콘
          const SizedBox(height: 24),
          Text(
            "Legal Risk Analyzer",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "분석할 법적 문장이나 계약 조항을 입력하세요.",
            textAlign: TextAlign.center,
            style: TextStyle(color: subTextColor, fontSize: 16),
          ),
          const SizedBox(height: 40),

          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_document, size: 18, color: subTextColor),
                      const SizedBox(width: 8),
                      Text(
                        "Input Text", 
                        style: TextStyle(fontWeight: FontWeight.bold, color: subTextColor)
                      ),
                      const Spacer(),
                      Text(
                        "$_analyzedTextLength 자", 
                        style: TextStyle(fontSize: 12, color: subTextColor)
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: _textController,
                  maxLines: 10,
                  minLines: 6,
                  style: TextStyle(fontSize: 16, height: 1.5, color: textColor),
                  decoration: InputDecoration(
                    hintText: "여기에 내용을 붙여넣거나 입력하세요...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _startCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, // 보라색 버튼 배경
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              child: const Text(
                "위험도 분석 시작",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 2. 결과 UI (렌더링 오류 수정됨)
  // --------------------------------------------------------------------------
  Widget _buildResultUI(Color textColor, Color? subTextColor, Color cardColor,
      Color primaryColor, Color accentColor, Color borderColor, bool isDark) {
    
    double riskScore = 9.0;
    double riskPercentage = riskScore / 10.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _resetCheck,
              icon: Icon(Icons.arrow_back, color: primaryColor), // 보라색 아이콘
              label: Text("새로운 분석", 
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)), // 보라색 텍스트
            ),
          ),
          const SizedBox(height: 20),

          // 📊 1. 종합 점수 카드
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 6,
                      color: accentColor,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("종합 위험도 등급", 
                                style: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text("CRITICAL", 
                                    style: TextStyle(color: accentColor, fontSize: 32, fontWeight: FontWeight.w900)),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text("심각", 
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Risk Score", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                Text("$riskScore / 10.0", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: riskPercentage,
                                minHeight: 12,
                                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "이 문장은 법적/윤리적으로 매우 높은 위험을 포함하고 있습니다.", 
                              style: TextStyle(color: subTextColor, fontSize: 14)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // 📝 2. 상세 분석 리포트 카드
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.analytics_outlined, color: primaryColor), // 보라색 아이콘
                      const SizedBox(width: 8),
                      Text("상세 분석 리포트", 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildDetailRow("입력 문장", '"$_analyzedText"', textColor, subTextColor, isHighlight: true),
                      const Divider(height: 24),
                      _buildDetailRow("유해성 분류", "욕설 및 비하 (Profanity)", textColor, subTextColor),
                      const Divider(height: 24),
                      _buildDetailRow("혐오 표현", "감지됨 (Detected)", textColor, subTextColor, isAlert: true, accentColor: accentColor),
                      const Divider(height: 24),
                      _buildDetailRow("감정 강도", "매우 강함 (Very High)", textColor, subTextColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, Color? subTextColor, 
      {bool isHighlight = false, bool isAlert = false, Color? accentColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label, 
            style: TextStyle(color: subTextColor, fontWeight: FontWeight.w600, fontSize: 14)
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isAlert ? (accentColor ?? Colors.red) : textColor,
              fontWeight: isAlert || isHighlight ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
              height: 1.4, 
            ),
          ),
        ),
      ],
    );
  }
}