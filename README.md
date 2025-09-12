# Capstone
인제대학교 컴퓨터 공학과 캡스톤 디자인 I

주제 : 법률 위반 경고 AI 서비스

인터넷에 게시되는 텍스트가 형사법 위반 소지가 있는지 자동 분석하고 안전한 표현을 제안하는 AI 서비스

[ 배경 및 필요성]

- 온라인에서 법적 문제가 될 수 있는 글(명예훼손, 협박, 모욕 등) 증가

- 일반 사용자가 법률 지식을 몰라 위험한 글을 게시할 가능성 존재

- 본 프로젝트는 형사법 데이터 기반 LLM + RAG 모델로 위험 여부를 탐지

[ 주요 기능 ]

텍스트 분석: 사용자가 입력한 문장이 형사법 위반 가능성이 있는지 판단

법적 근거 제시: 관련 형사법 조항을 DB에서 검색하여 제시

대체 표현 추천: 위험한 표현을 더 안전한 표현으로 제안

사용자 로그 관리: 검사 이력 저장 및 조회 가능

웹/앱 제공: Flutter 기반 프론트엔드, Node.js/Express 백엔드

[ 사용 예시 (Example) ]

입력: "너 죽여버린다"

출력: 위험도: 높음 ⚠️

관련 법률: 형법 제283조 (협박죄)

대체 표현: "너무 화가 나"

## 3. 시스템 아키텍처 (System Architecture)

시스템은 **프론트엔드(Flutter)**, **백엔드(Node.js/Express)**, **데이터베이스(PostgreSQL)**,  
그리고 **AI 모델(OpenAI GPT API + RAG 구조)** 로 구성되어 있습니다.  

```mermaid
flowchart TD
    User([사용자]) -->|텍스트 입력| Frontend[Frontend<br/>Flutter (Web/Mobile)]
    Frontend -->|요청 전송| Backend[Backend<br/>Node.js + Express]
    Backend -->|쿼리 및 이력 저장| DB[(PostgreSQL<br/>Neon Cloud)]
    Backend -->|LLM 요청| AI[AI 모델<br/>OpenAI GPT API<br/>+ RAG 구조]
    AI -->|관련 법령/판례 검색| Dataset[(형사법 데이터셋<br/>AI Hub 활용)]
    AI -->|분석 결과 반환| Backend
    Backend -->|결과 전달| Frontend
    Frontend -->|법적 위험도/대체 표현 제공| User
