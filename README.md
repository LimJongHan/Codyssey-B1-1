# B1-1 시스템 관제 자동화 스크립트

> Codyssey AI/SW 기초 — Linux와 OS 미션

Ubuntu 서버 환경에서 보안 설정, 계정 권한 체계, 시스템 관제 자동화 스크립트를 직접 구축합니다.

---

## 미션 개요

| 항목 | 내용 |
|------|------|
| 분야 | AI/SW 기초 |
| 구분 | Linux와 OS |
| 학습시간 | 40시간 |
| 환경 | Ubuntu 24.04 LTS (Docker, linux/amd64) |

---

## 파일 구조

```
B1-1/
├── README.md         # 이 파일 — 저장소 안내
├── Mission.md        # 미션 요구사항 원문
├── 수행내역서.md      # 요구사항 수행 기록 및 증거 자료
├── Study.md          # 미션 관련 개념 학습 가이드 (비전공자용)
├── Tutorial.md       # 미션 직접 수행을 위한 단계별 튜토리얼
├── monitor.sh        # 시스템 관제 자동화 스크립트 (핵심 과제)
├── report.sh         # 로그 통계 분석 스크립트 (보너스 1)
└── archive.sh        # 로그 보존 정책 스크립트 (보너스 2)
```

---

## 핵심 구현 내용

### 보안 설정
- SSH 포트 변경 (`22` → `20022`), Root 원격 접속 차단
- UFW 방화벽: TCP `20022`, TCP `15034` 만 허용

### 계정/권한 체계
- 역할별 계정: `agent-admin` / `agent-dev` / `agent-test`
- 그룹: `agent-common` (전체), `agent-core` (admin+dev)
- 디렉토리 ACL로 공용/보안 영역 분리

### monitor.sh 주요 기능
- **Health Check**: 프로세스 및 포트 15034 감시 → 실패 시 `exit 1`
- **자원 수집**: CPU / 메모리 / 디스크 사용률
- **임계값 경고**: CPU > 20%, MEM > 10%, DISK > 80% 시 `[WARNING]`
- **로그 기록**: `/var/log/agent-app/monitor.log` 누적, 최대 10MB×10개 유지
- **cron 자동 실행**: `agent-admin` 계정으로 매분 실행

---

## 문서 안내

| 문서 | 대상 | 내용 |
|------|------|------|
| [Mission.md](./Mission.md) | 전체 | 미션 요구사항 원문 |
| [수행내역서.md](./수행내역서.md) | 검토자 | 설정 기록, 명령어, 실행 결과 증거 |
| [Study.md](./Study.md) | 입문자 | SSH·방화벽·권한·cron 등 배경 개념 설명 |
| [Tutorial.md](./Tutorial.md) | 실습자 | 처음부터 직접 따라하는 단계별 가이드 |

---

## 스크립트 사용법

### monitor.sh — 시스템 상태 수집 및 로깅

```bash
# 수동 실행
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_LOG_DIR=/var/log/agent-app
bash $AGENT_HOME/bin/monitor.sh

# crontab 자동 실행 (매분)
* * * * * AGENT_HOME=... AGENT_PORT=15034 AGENT_LOG_DIR=... bash /path/monitor.sh
```

### report.sh — 로그 통계 분석 (보너스 1)

```bash
# 전체 로그 분석
bash report.sh

# 시간 구간 지정
bash report.sh -s '2026-05-14 06:30:00' -e '2026-05-14 06:40:00'
```

### archive.sh — 로그 보존 정책 (보너스 2)

```bash
# 7일 경과 로그 압축 → 아카이브, 30일 경과 아카이브 삭제
bash archive.sh
```

---

## 로그 포맷

```
[2026-05-14 06:30:01] PID:4863 CPU:1% MEM:12.0% DISK_USED:2%
```
