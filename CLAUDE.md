# Codyssey B1-1 — 시스템 관제 자동화 스크립트

## 미션 개요
Linux 서버 운영 환경을 직접 구축하고, 시스템 상태를 자동으로 수집·기록하는 관제 스크립트를 개발한다.
핵심 산출물은 `monitor.sh` (Bash 스크립트)와 요구사항 수행 내역서다.

## 개발 환경
- OS: Ubuntu 22.04 LTS (컨테이너 또는 VM)
- Shell: Bash
- 자동화 스크립트는 **Bash 전용** — Python 등으로 대체 금지
- 제공 앱(`agent-app`)은 실행 대상일 뿐, 수정하지 않는다

## 핵심 상수

| 항목 | 값 |
|------|----|
| SSH 포트 | `20022` |
| 앱 포트 | `15034` |
| AGENT_HOME | `/home/agent-admin/agent-app` |
| 키 파일 경로 | `$AGENT_HOME/api_keys/t_secret.key` |
| 키 파일 내용 | `agent_api_key_test` |
| 로그 디렉토리 | `/var/log/agent-app` |
| monitor.sh 경로 | `$AGENT_HOME/bin/monitor.sh` |

## 계정/그룹 구조

| 계정 | 그룹 |
|------|------|
| `agent-admin` | agent-common, agent-core |
| `agent-dev` | agent-common, agent-core |
| `agent-test` | agent-common |

## 디렉토리 권한 정책

| 경로 | 접근 가능 그룹 | 권한 |
|------|--------------|------|
| `$AGENT_HOME/upload_files` | agent-common | R/W |
| `$AGENT_HOME/api_keys` | agent-core only | R/W |
| `/var/log/agent-app` | agent-core only | R/W |
| `$AGENT_HOME/bin/monitor.sh` | 소유: agent-dev / 그룹: agent-core | 750 |

## monitor.sh 스펙 요약
- **Health Check**: `agent-app` 프로세스 + TCP 15034 LISTEN → 실패 시 `exit 1`
- **경고 임계값**: CPU > 20%, MEM > 10%, DISK > 80% → `[WARNING]` 출력 (종료 안 함)
- **로그 포맷**: `[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%`
- **로그 용량**: 최대 10MB / 10개 파일 유지
- **cron**: `agent-admin` 계정으로 매분 실행

## 보안 설정 요약
- SSH 포트 20022, PermitRootLogin no
- 방화벽: TCP 20022, TCP 15034만 인바운드 허용 (UFW 또는 firewalld 택1)
- 앱은 반드시 일반 계정(`agent-admin`)으로 실행, root 실행 금지

## 제출물
1. 요구사항 수행 내역서 (문서)
2. `monitor.sh` 소스코드
