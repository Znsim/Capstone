# engine/rule_engine.py
# 규칙 기반 검색 엔진 (키워드/패턴 기반)

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Tuple, Set, List, Pattern


BASE_DIR = Path(__file__).resolve().parents[1]   # backend/app
DATA_DIR = BASE_DIR / "data"
LEXEME_FILE = DATA_DIR / "risk_lexemes.jsonl"
PATTERN_FILE = DATA_DIR / "risk_patterns.jsonl"


def _load_rule_lists() -> Tuple[Set[str], List[Pattern[str]]]:
    """
    risk_lexemes.jsonl / risk_patterns.jsonl 로부터
    - 욕설/위험 단어 셋
    - 정규식 패턴 리스트
    를 미리 로드.
    """
    print(f"'{LEXEME_FILE}' 및 '{PATTERN_FILE}' 규칙 파일 로드 중...")
    rule_terms_set: Set[str] = set()
    rule_patterns_list: List[Pattern[str]] = []

    try:
        # lexeme
        with LEXEME_FILE.open("r", encoding="utf-8") as f:
            for line in f:
                if not line.strip():
                    continue
                term = json.loads(line).get("term")
                if term:
                    rule_terms_set.add(term)
        print(f"  -> {len(rule_terms_set)}개의 욕설/위험 단어 로드 완료.")

        # pattern
        with PATTERN_FILE.open("r", encoding="utf-8") as f:
            for line in f:
                if not line.strip():
                    continue
                pattern_str = json.loads(line).get("pattern")
                if pattern_str:
                    rule_patterns_list.append(re.compile(pattern_str, re.IGNORECASE))
        print(f"  -> {len(rule_patterns_list)}개의 욕설/위험 패턴 로드 완료.")

        return rule_terms_set, rule_patterns_list

    except FileNotFoundError:
        sys.exit(f"[오류] 규칙 파일('{LEXEME_FILE}' 또는 '{PATTERN_FILE}')을 찾을 수 없습니다.")
    except Exception as e:
        sys.exit(f"규칙 파일 로드 중 오류: {e}")


# 프로세스 시작 시 한 번만 로드
RULE_TERMS, RULE_PATTERNS = _load_rule_lists()


def calculate_rule_score(user_query: str) -> float:
    """
    사용자 쿼리를 받아 '규칙 점수'(0.0 또는 1.0)를 반환.
    단어/패턴 중 하나라도 매칭되면 1.0, 아니면 0.0
    """
    for term in RULE_TERMS:
        if term and term in user_query:
            print(f"  -> 규칙 감지 (단어): '{term}'")
            return 1.0

    for pattern in RULE_PATTERNS:
        if pattern.search(user_query):
            print(f"  -> 규칙 감지 (패턴): {pattern.pattern}")
            return 1.0

    return 0.0
