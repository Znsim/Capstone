//결과 기록용 Page

import 'package:flutter/material.dart';

// 결과 기록(이력) 페이지 바디
class HistoryPageWeb extends StatelessWidget {
  const HistoryPageWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFE8FF), // 전체 배경
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 950),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.06),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFF4A46C3), width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 탭 영역
              const SizedBox(height: 26),
              // 테이블 헤더
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    SizedBox(width: 36), // 체크박스 자리
                    SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(
                          "T/I",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "입력 내용",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "AI 답변 내용",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: Text(
                        "일자",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 이력 리스트
              _HistoryRow(
                type: "T",
                input: "사용자가 입력한 내용",
                result: "AI 답변 내용",
                date: "2024.06.11",
              ),
              _HistoryRow(
                type: "I",
                input: "사용자가 입력한 내용",
                result: "AI 답변 내용",
                date: "2024.06.11",
              ),
              // ...필요시 더 추가
            ],
          ),
        ),
      ),
    );
  }
}

// 탭(네비게이션) 버튼
class _HistoryTabItem extends StatelessWidget {
  final String label;
  final bool selected;
  const _HistoryTabItem(this.label, {this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 28),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 17,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? const Color(0xFF4A46C3) : Colors.black87,
          decoration: selected ? TextDecoration.underline : null,
          decorationColor: const Color(0xFF4A46C3),
          decorationThickness: 2,
        ),
      ),
    );
  }
}

// 이력 row
class _HistoryRow extends StatelessWidget {
  final String type;
  final String input;
  final String result;
  final String date;

  const _HistoryRow({
    required this.type,
    required this.input,
    required this.result,
    required this.date,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDED8FA), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(value: false, onChanged: (v) {}),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              type,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 3, child: Text(input)),
          Expanded(flex: 3, child: Text(result)),
          SizedBox(
            width: 110,
            child: Text(
              date,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
