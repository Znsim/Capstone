import 'package:flutter/material.dart';

class AnalyzeResult {
  final String risk;
  final double score;
  final double llmScore;
  final double ruleScore;
  final List<dynamic> ruleHits;
  final List<dynamic> reasons;
  final List<dynamic> rewrites;
  final List<dynamic> contexts;

  AnalyzeResult({
    required this.risk,
    required this.score,
    required this.llmScore,
    required this.ruleScore,
    required this.ruleHits,
    required this.reasons,
    required this.rewrites,
    required this.contexts,
  });

  factory AnalyzeResult.fromJson(Map<String, dynamic> json) {
    return AnalyzeResult(
      risk: json["risk"] ?? "Unknown", // 위험도 등급
      score: (json["score"] ?? 0).toDouble(), // 최종 앙상블 점수
      llmScore: (json["llm_score"] ?? 0).toDouble(), // llm 점수
      ruleScore: (json["rule_score"] ?? 0).toDouble(), // 규칙 점수
      ruleHits: (json["rule_hits"] ?? []) as List, // 감지된 규칙 항목
      reasons: (json["reasons"] ?? []) as List, // llm 분석
      rewrites: (json["rewrites"] ?? []) as List, // 대체 표현
      contexts: (json["contexts"] ?? []) as List, // rag 근거
    );
  }

  // 영어 위험도 라벨을 한국어로 변환
  String get riskKr {
    switch (risk) {
      case "High Risk":
        return "심각";
      case "Threat":
        return "위험";
      case "Caution":
        return "주의";
      case "Safe":
        return "안전";
      default:
        return "-";
    }
  }

  // 위험도 색상
  Color get riskColor {
  switch (risk) {
    case "High Risk":
      return Colors.red;
    case "Threat":
      return Colors.orange;
    case "Caution":
      return Colors.yellow;
    case "Safe":
      return Colors.green;
    default:
      return Colors.grey;
  }
}

  // 타입 변환 후 관련 법률 필터링
  List<String> get lawReasons {
    return reasons
        .map((e) => e.toString())
        .where((e) => e.startsWith("[관련 법률]"))
        .map((e) => e.replaceFirst("[관련 법률] ", ""))
        .toList();
  }

  // 타입 변환 후 분석 텍스트 필터링
  List<String> get analysisReasons {
    return reasons
        .map((e) => e.toString())
        .where((e) => !e.startsWith("[관련 법률]"))
        .toList();
  }

  // 관련 법률 문자열 버전
  String get lawReasonsText {
    final list = lawReasons;
    if (list.isEmpty) return "-";
    return list.join(", ");
  }

  // 분석 텍스트 문자열 버전
  String get analysisReasonsText {
    final list = analysisReasons;
    if (list.isEmpty) return "-";
    return list.join("\n");
  }
}
