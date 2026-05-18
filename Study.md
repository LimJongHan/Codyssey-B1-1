# B1-1 미션 학습 가이드

> 이 문서는 이번 미션에서 다룬 모든 개념을 **비전공자도 이해할 수 있도록** 배경지식부터 실제 적용까지 설명합니다.

---

## 목차

1. [Linux와 서버란 무엇인가](#1-linux와-서버란-무엇인가)
2. [터미널과 쉘](#2-터미널과-쉘)
3. [SSH — 원격 접속의 원리](#3-ssh--원격-접속의-원리)
4. [포트(Port) — 건물의 출입구](#4-포트port--건물의-출입구)
5. [TCP — 인터넷 통신의 기본 규약](#5-tcp--인터넷-통신의-기본-규약)
6. [방화벽(UFW) — 보안 경비원](#6-방화벽ufw--보안-경비원)
7. [계정과 그룹 — 회사의 사원증과 부서](#7-계정과-그룹--회사의-사원증과-부서)
8. [파일 권한과 ACL — 자물쇠와 마스터키](#8-파일-권한과-acl--자물쇠와-마스터키)
9. [환경 변수 — 프로그램의 설정값](#9-환경-변수--프로그램의-설정값)
10. [프로세스 — 실행 중인 프로그램](#10-프로세스--실행-중인-프로그램)
11. [Bash 스크립트 — 자동화의 기본](#11-bash-스크립트--자동화의-기본)
12. [로그(Log) — 서버의 블랙박스](#12-로그log--서버의-블랙박스)
13. [crontab — 알람처럼 반복 실행](#13-crontab--알람처럼-반복-실행)
14. [monitor.sh 해부 — 코드 한 줄씩 이해하기](#14-monitorsh-해부--코드-한-줄씩-이해하기)
15. [Docker — 가상 컴퓨터 속 컴퓨터](#15-docker--가상-컴퓨터-속-컴퓨터)
16. [전체 흐름 정리](#16-전체-흐름-정리)

---

## 1. Linux와 서버란 무엇인가

### 운영체제(OS)란?

컴퓨터는 하드웨어(CPU, 메모리, 디스크)만으로는 아무것도 할 수 없습니다. 하드웨어를 사람이 쓸 수 있게 연결해주는 **중간 관리자**가 운영체제(Operating System)입니다.

```
[사람] → [앱/프로그램] → [운영체제(OS)] → [하드웨어]
```

Windows, macOS, Linux 모두 운영체제입니다.

### 왜 서버에는 Linux를 쓸까?

| 특징 | Windows | Linux |
|------|---------|-------|
| 라이선스 비용 | 유료 | 무료 |
| 안정성 | 보통 | 매우 높음 (수년 무중단 운영 가능) |
| 원격 관리 | GUI 중심 | 텍스트 명령어로 가능 |
| 서버 점유율 | ~20% | ~80% |

서버는 24시간 365일 켜져 있어야 합니다. Linux는 가볍고 안정적이며, 화면 없이 텍스트 명령어만으로 운영할 수 있어서 서버 환경의 표준이 되었습니다.

### Ubuntu 22.04 LTS란?

- **Ubuntu**: Linux 계열 중 가장 대중적인 배포판. 데스크탑과 서버 모두 사용 가능.
- **22.04**: 2022년 4월에 출시된 버전을 의미.
- **LTS(Long Term Support)**: 5년간 공식 보안 업데이트를 제공하는 장기 지원 버전. 서버에서는 안정성이 중요하기 때문에 LTS 버전을 사용합니다.

---

## 2. 터미널과 쉘

### 터미널이란?

터미널은 **텍스트로 컴퓨터에 명령을 내리는 창**입니다. 마우스로 클릭하는 GUI(그래픽 인터페이스) 대신, 키보드로 명령어를 입력합니다.

```
$ ls -la        ← 현재 디렉토리 파일 목록을 자세히 보기
$ pwd           ← 현재 내 위치(경로) 출력
$ cd /var/log   ← /var/log 디렉토리로 이동
```

### 쉘(Shell)이란?

터미널 안에서 명령어를 **해석하고 실행해주는 프로그램**입니다. Linux에서 가장 많이 쓰는 쉘은 **Bash(Bourne Again Shell)** 입니다.

```
[사람이 명령어 입력] → [Shell이 해석] → [OS가 실행] → [결과 출력]
```

쉘은 단순히 명령어를 실행하는 것을 넘어, 프로그래밍(반복, 조건문, 변수)도 가능합니다. 이것이 **쉘 스크립트**입니다.

### 자주 쓰는 기본 명령어

```bash
ls -la          # 파일 목록 (권한 포함)
pwd             # 현재 경로 확인
cd /path        # 디렉토리 이동
mkdir dirname   # 디렉토리 생성
cat file.txt    # 파일 내용 출력
grep "단어" file # 파일에서 특정 단어 검색
ps aux          # 실행 중인 프로세스 목록
```

---

## 3. SSH — 원격 접속의 원리

### SSH란?

SSH(Secure Shell)는 **인터넷을 통해 다른 컴퓨터에 안전하게 접속하는 프로토콜**입니다.

예를 들어, 서울에 있는 내 노트북에서 미국 데이터센터에 있는 서버에 접속해 명령어를 실행할 수 있습니다.

```
[내 노트북] ──(인터넷)──→ [서버]
   SSH 클라이언트          SSH 서버(sshd)
```

### 왜 "Secure"인가?

초기에는 Telnet이라는 원격 접속 도구가 있었는데, 데이터가 **평문(암호화 없이)** 전송되었습니다. 중간에서 누군가 엿보면 비밀번호까지 다 보였습니다.

SSH는 **공개키/비밀키 암호화**를 사용해 전송 데이터를 암호화합니다.

```
평문 Telnet: "password: mypassword123" → 그대로 전송 (위험)
SSH:         "X9#kL2mP..." → 암호화된 데이터 전송 (안전)
```

### SSH 기본 포트가 22인 이유와 변경하는 이유

SSH의 기본 포트는 **22번**입니다. 전 세계 모든 해커와 자동화 봇이 이것을 알고 있기 때문에, 인터넷에 연결된 서버의 22번 포트에는 **1초에 수백 번씩 자동 침입 시도**가 들어옵니다.

포트를 **20022**처럼 잘 알려지지 않은 번호로 바꾸면:
- 자동화 봇의 공격 대부분을 차단할 수 있습니다 (보트는 주로 22번만 시도)
- 근본적인 해결책은 아니지만, 공격 시도 횟수를 크게 줄입니다

```
# /etc/ssh/sshd_config 설정
Port 20022               ← 기본 22에서 변경
PermitRootLogin no       ← root 계정으로 직접 로그인 금지
```

### Root 원격 접속을 막는 이유

`root`는 Linux에서 **모든 권한을 가진 최고 관리자 계정**입니다. root로 접속에 성공하면 서버의 모든 것을 삭제하거나 변경할 수 있습니다. 따라서:

1. root 직접 로그인 차단 (`PermitRootLogin no`)
2. 일반 계정으로 로그인 후 필요할 때만 `sudo`로 관리자 권한 사용

---

## 4. 포트(Port) — 건물의 출입구

### 포트란?

IP 주소가 **건물의 주소**라면, 포트 번호는 **건물 안의 특정 방(출입구) 번호**입니다.

```
IP: 192.168.1.10 (건물 주소)
포트 22   → SSH 서비스가 기다리는 방
포트 80   → 웹 서버(HTTP)가 기다리는 방
포트 443  → 보안 웹 서버(HTTPS)가 기다리는 방
포트 15034 → agent-app이 기다리는 방
```

포트 번호는 0~65535까지 있으며:
- **0~1023**: 잘 알려진 서비스 (HTTP=80, HTTPS=443, SSH=22)
- **1024~49151**: 등록된 서비스
- **49152~65535**: 동적/사설 포트 (자유롭게 사용)

### LISTEN 상태란?

어떤 프로그램이 특정 포트에서 **연결 요청을 기다리는 상태**를 LISTEN이라고 합니다.

```bash
ss -tlnp   # 현재 LISTEN 중인 포트 목록 확인
```

```
tcp  LISTEN  0.0.0.0:20022  → sshd가 20022번 포트에서 대기 중
tcp  LISTEN  0.0.0.0:15034  → agent-app이 15034번 포트에서 대기 중
```

`0.0.0.0`은 "모든 네트워크 인터페이스에서 접속 허용"을 의미합니다.

---

## 5. TCP — 인터넷 통신의 기본 규약

### TCP란?

**TCP(Transmission Control Protocol)**는 인터넷에서 데이터를 주고받을 때 사용하는 통신 규약(프로토콜)입니다. 쉽게 말하면 **"데이터를 어떤 방식으로 안전하게 전달할지" 정한 약속**입니다.

우리가 방화벽 규칙에서 `ufw allow 20022/tcp` 처럼 `/tcp`를 붙이는 이유가 바로 이겁니다.

---

### TCP vs UDP

네트워크 프로토콜의 양대 산맥입니다.

| | TCP | UDP |
|--|-----|-----|
| 전달 보장 | ✅ 순서대로, 빠짐없이 | ❌ 보장 없음 |
| 속도 | 상대적으로 느림 | 빠름 |
| 연결 방식 | 연결 후 통신 | 그냥 전송 |
| 사용 예 | SSH, HTTP, 파일전송 | 영상스트리밍, 게임, DNS |

**SSH와 agent-app은 TCP를 씁니다.** 명령어나 데이터가 중간에 유실되면 안 되기 때문입니다.

---

### 3-way Handshake — 연결 맺는 과정

TCP는 실제 데이터를 보내기 전에 **먼저 연결을 확인**합니다. 이 과정을 3-way Handshake라고 합니다.

```
클라이언트 (내 Mac)          서버 (컨테이너)

  1. SYN  ──────────────────→   "연결해도 돼?"
  2. SYN-ACK  ←──────────────   "응, 연결해"
  3. ACK  ──────────────────→   "알겠어, 시작하자"

  ↓ 이후 실제 데이터 전송 시작
```

| 단계 | 이름 | 의미 |
|------|------|------|
| 1 | SYN | Synchronize. 연결 요청 |
| 2 | SYN-ACK | 요청 수락 |
| 3 | ACK | Acknowledge. 확인 완료 |

SSH로 서버에 접속할 때, 브라우저가 웹페이지를 열 때 모두 이 과정을 거칩니다.

---

### 소켓 상태 — LISTEN vs ESTABLISHED

`ss -tlnp` 결과에서 볼 수 있는 상태값입니다.

| 상태 | 의미 |
|------|------|
| `LISTEN` | 연결 요청을 기다리는 중. 아직 아무도 접속 안 함 |
| `ESTABLISHED` | 연결이 맺어져 현재 통신 중 |
| `TIME_WAIT` | 연결 종료 후 잠시 대기 중 |

```bash
ss -tlnp          # LISTEN 상태만 확인
ss -tnp           # ESTABLISHED 포함 모든 상태 확인
```

```
# agent-app 실행 후 아무도 접속 안 한 상태
tcp  LISTEN       0.0.0.0:15034   → 대기 중

# 누군가 접속한 상태
tcp  ESTABLISHED  0.0.0.0:15034   → 통신 중
```

---

### 왜 `/tcp`를 붙이나?

```bash
ufw allow 20022/tcp   # TCP만 허용
ufw allow 20022       # TCP + UDP 모두 허용
```

SSH는 TCP만 사용하므로 `/tcp`를 명시하는 것이 더 정확하고 안전합니다. UDP까지 열 이유가 없기 때문입니다.

---

## 6. 방화벽(UFW) — 보안 경비원

### 방화벽이란?

방화벽은 서버로 들어오고 나가는 **네트워크 트래픽을 규칙에 따라 허용하거나 차단**하는 시스템입니다.

```
[인터넷] → [방화벽] → [서버]
              ↑
         규칙 검사
         "20022번 포트? → 허용"
         "3306번 포트? → 차단"
```

### UFW(Uncomplicated Firewall)

Linux의 방화벽 설정은 원래 `iptables`라는 복잡한 도구로 했습니다. UFW는 이것을 **단순하게 감싼 도구**입니다.

```bash
ufw default deny incoming    # 기본: 모든 인바운드 차단
ufw default allow outgoing   # 기본: 모든 아웃바운드 허용
ufw allow 20022/tcp          # SSH 포트만 허용
ufw allow 15034/tcp          # 앱 포트만 허용
ufw enable                   # 방화벽 활성화
```

### 인바운드 vs 아웃바운드

```
인바운드(Inbound):  외부 → 서버로 들어오는 트래픽 (엄격하게 관리)
아웃바운드(Outbound): 서버 → 외부로 나가는 트래픽 (보통 허용)
```

"필요한 포트만 열기" 원칙은 보안의 기본입니다. 열려있는 포트가 많을수록 공격자가 침입할 수 있는 경로가 많아집니다.

---

## 7. 계정과 그룹 — 회사의 사원증과 부서

### Linux의 다중 사용자 환경

Linux는 **여러 사람이 동시에 사용할 수 있도록** 설계된 운영체제입니다. 각 사용자는 자신만의 계정을 가지며, 다른 사용자의 파일에 함부로 접근할 수 없습니다.

### UID와 GID

모든 사용자(User)와 그룹(Group)은 숫자 ID를 가집니다.

```
UID(User ID): 사용자 식별 번호
GID(Group ID): 그룹 식별 번호

root: UID=0 (최고 관리자)
일반 사용자: UID=1000 이상
```

```bash
id agent-admin
# uid=1001(agent-admin) gid=1003(agent-admin) groups=1003(agent-admin),1001(agent-common),1002(agent-core)
```

### 역할 기반 계정 설계

이번 미션에서는 역할에 따라 계정을 분리했습니다:

```
agent-admin  → 서버 운영/관리, 앱 실행, cron 실행
agent-dev    → 개발/운영, 스크립트 작성
agent-test   → 테스트/QA
```

**왜 하나의 계정을 쓰지 않을까?**

만약 모든 사람이 `root` 하나만 쓴다면:
- 누가 어떤 작업을 했는지 추적 불가
- 실수로 중요한 파일 삭제 시 복구 어려움
- 보안 침해 시 피해 범위가 전체

계정을 분리하면 각자의 역할에 맞는 **최소한의 권한만** 부여할 수 있습니다. 이것을 **최소 권한 원칙(Principle of Least Privilege)** 이라고 합니다.

### 그룹의 역할

그룹은 **공통 권한을 묶는 단위**입니다. 파일에 "이 그룹만 접근 가능"이라고 설정하면, 그 그룹에 속한 모든 계정이 접근할 수 있습니다.

```
agent-common 그룹: admin, dev, test 모두 포함 → 공용 디렉토리 접근
agent-core 그룹:   admin, dev만 포함          → 보안 디렉토리 접근
```

```
공용 파일(upload_files)   → agent-common 그룹 접근 가능
보안 파일(api_keys, 로그) → agent-core 그룹만 접근 가능
```

---

## 8. 파일 권한과 ACL — 자물쇠와 마스터키

### 기본 파일 권한 (rwx)

Linux의 모든 파일과 디렉토리에는 **3가지 권한**이 있습니다:

```
r (read)    = 읽기 권한  (숫자: 4)
w (write)   = 쓰기 권한  (숫자: 2)
x (execute) = 실행 권한  (숫자: 1)
```

그리고 이 권한이 **3가지 대상**에 각각 적용됩니다:

```
소유자(owner) | 그룹(group) | 기타(others)
```

`ls -la` 결과 해석:

```
-rwxr-x---  agent-dev  agent-core  monitor.sh
 ↑↑↑↑↑↑↑↑↑
 │rwx         → 소유자(agent-dev): 읽기+쓰기+실행 (7)
 │   r-x      → 그룹(agent-core): 읽기+실행 (5)
 │      ---   → 기타: 권한 없음 (0)
 │
 └ 파일 종류 (-: 파일, d: 디렉토리)
```

**숫자 표기:** `rwxr-x--- = 750`
- 소유자: r(4)+w(2)+x(1) = **7**
- 그룹:   r(4)+w(0)+x(1) = **5**
- 기타:   r(0)+w(0)+x(0) = **0**

### chmod로 권한 변경

```bash
chmod 750 monitor.sh   # rwxr-x--- 설정
chmod 640 secret.key   # rw-r----- 설정
chmod 770 upload_files # rwxrwx--- 설정
```

### chown으로 소유자 변경

```bash
chown agent-dev:agent-core monitor.sh
# 소유자: agent-dev
# 그룹:   agent-core
```

### ACL — 더 세밀한 권한 제어

기본 권한은 **소유자 1명, 그룹 1개**만 지정할 수 있습니다. 더 복잡한 경우(예: "특정 그룹에 추가로 접근 허용")에는 **ACL(Access Control List)** 을 사용합니다.

```bash
setfacl -m g:agent-common:rwx /path/upload_files
# "agent-common 그룹에게 rwx 권한 추가 부여"

getfacl /path/upload_files   # ACL 확인
```

ACL이 설정된 파일은 `ls -la`에서 권한 뒤에 `+` 표시가 붙습니다:

```
drwxrwx---+   ← + 가 붙으면 ACL 설정 있음
```

---

## 9. 환경 변수 — 프로그램의 설정값

### 환경 변수란?

프로그램이 실행될 때 참조할 수 있는 **이름=값 형태의 전역 설정값**입니다. 코드 안에 경로나 설정을 하드코딩하지 않고, 환경 변수로 분리해두면 유연하게 운영할 수 있습니다.

```bash
# 하드코딩 (나쁜 예)
cat /home/agent-admin/agent-app/api_keys/t_secret.key

# 환경 변수 사용 (좋은 예)
cat $AGENT_KEY_PATH
```

### 설정 방법

```bash
# 현재 세션에서만 유효
export AGENT_HOME=/home/agent-admin/agent-app

# 영구 적용 (로그인 시마다 자동 실행)
echo 'export AGENT_HOME=/home/agent-admin/agent-app' >> ~/.bashrc
```

### .bashrc란?

`~/.bashrc`는 **Bash 쉘이 시작될 때 자동으로 실행되는 설정 파일**입니다. 환경 변수, 별칭(alias), 함수 등을 여기에 정의합니다.

```
~/ = 홈 디렉토리 (agent-admin의 경우 /home/agent-admin/)
```

### 이번 미션의 환경 변수

```bash
AGENT_HOME=/home/agent-admin/agent-app   # 앱 기본 경로
AGENT_PORT=15034                          # 앱 사용 포트
AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files # 업로드 경로
AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key  # 키 파일 경로
AGENT_LOG_DIR=/var/log/agent-app          # 로그 경로
```

앱이 실행될 때 이 변수들을 읽어서 어디에 파일을 저장할지, 어느 포트를 사용할지 결정합니다.

---

## 10. 프로세스 — 실행 중인 프로그램

### 프로세스란?

프로그램은 디스크에 저장된 **코드 파일**입니다. 그 프로그램을 실행하면 메모리에 올라가 CPU를 사용하는 **프로세스**가 됩니다.

```
파일(디스크): agent-app         ← 정적인 코드
프로세스(메모리): agent-app 실행 중 ← 동적으로 실행 중
```

### PID (Process ID)

각 프로세스는 고유한 **PID(프로세스 식별 번호)** 를 가집니다.

```bash
ps aux | grep agent-app   # agent-app 프로세스 찾기
pgrep -f agent-app        # agent-app 프로세스의 PID만 출력
```

```
PID  4863  agent-admin  → agent-admin 계정으로 실행 중인 agent-app
```

### 프로세스 상태 확인이 중요한 이유

서버 운영 중에 다음 상황이 발생할 수 있습니다:
- 앱이 **갑자기 죽음** (메모리 부족, 버그 등)
- 앱이 **좀비 상태** (실행 중처럼 보이지만 응답 없음)

monitor.sh의 Health Check는 이런 상황을 감지하기 위해 존재합니다:

```bash
PID=$(pgrep -f "agent-app")
if [ -z "$PID" ]; then
    echo "[FAIL] 프로세스 없음"
    exit 1
fi
```

---

## 11. Bash 스크립트 — 자동화의 기본

### 쉘 스크립트란?

여러 명령어를 **파일에 저장해 순서대로 실행**하는 프로그램입니다. 반복적인 작업을 자동화할 수 있습니다.

### 기본 문법

```bash
#!/bin/bash              # 이 파일은 bash로 실행하라는 선언 (shebang)

# 변수
NAME="agent-app"
PORT=15034

# 조건문
if [ -z "$NAME" ]; then  # NAME이 비어있으면
    echo "이름이 없습니다"
else
    echo "이름: $NAME"
fi

# 반복문
for i in 1 2 3; do
    echo "숫자: $i"
done

# 함수
check_port() {
    ss -tlnp | grep -q ":$1 "
}

if check_port $PORT; then
    echo "포트 $PORT 열려있음"
fi
```

### 자주 쓰는 패턴

```bash
# 명령어 결과를 변수에 저장
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')

# 파일 존재 여부 확인
[ -f "/path/file" ] && echo "파일 있음"

# 숫자 비교
[ "$CPU" -gt 80 ] && echo "CPU 높음"

# 문자열 비교
[ "$STATUS" = "active" ] && echo "활성"

# 명령어 성공 여부 확인
if grep -q "pattern" file.txt; then
    echo "패턴 발견"
fi
```

### exit 코드

모든 명령어와 스크립트는 종료 시 **종료 코드(exit code)** 를 반환합니다:
- `0`: 성공
- `1` 이상: 실패 (숫자로 오류 종류 구분)

```bash
exit 0   # 정상 종료
exit 1   # 오류로 종료
```

monitor.sh에서 Health Check 실패 시 `exit 1`을 하는 이유가 여기 있습니다. cron이나 다른 스크립트가 이 종료 코드를 보고 "실패했구나"를 인식합니다.

### awk — 텍스트 처리 도구

`awk`는 텍스트의 특정 열(column)을 추출하는 강력한 도구입니다.

```bash
# free 명령어 출력:
# Mem:  8192000  3145728  5046272

free | grep Mem | awk '{print $2}'   # 8192000 (전체 메모리)
free | grep Mem | awk '{print $3}'   # 3145728 (사용 중)
```

---

## 12. 로그(Log) — 서버의 블랙박스

### 왜 로그를 남겨야 하는가?

비행기에 블랙박스가 있듯, 서버에도 **무슨 일이 언제 일어났는지 기록**이 있어야 합니다.

서버 장애가 발생했을 때:
- 로그가 없으면 → "감"으로 원인 추측, 같은 장애 반복
- 로그가 있으면 → 정확한 시각, 원인, 패턴 파악 가능

### /var/log 디렉토리

Linux에서 로그 파일들은 주로 `/var/log/`에 저장됩니다:

```
/var/log/syslog          → 시스템 전체 로그
/var/log/auth.log        → 인증(로그인) 관련 로그
/var/log/agent-app/      → agent-app 전용 로그 (이번 미션)
```

### monitor.log 포맷

```
[2026-05-14 06:30:01] PID:4863 CPU:1% MEM:12.0% DISK_USED:2%
```

- **타임스탬프**: 언제 수집했는지
- **PID**: 어떤 프로세스를 모니터링했는지
- **CPU/MEM/DISK**: 그 시점의 자원 사용률

이 포맷을 통일하면 나중에 `awk`나 `grep`으로 쉽게 분석할 수 있습니다.

### 로그 용량 관리의 필요성

로그를 무한정 쌓으면 디스크가 꽉 찹니다. 디스크가 꽉 차면:
- 새 로그를 쓰지 못함
- 앱이 파일 저장 실패로 다운될 수 있음

이 문제를 해결하는 방법:

**방법 1 — 스크립트 로직 (monitor.sh에서 사용)**
```bash
# 파일 크기가 10MB 초과 시 rotate
MAX_SIZE=$((10 * 1024 * 1024))  # 10MB
size=$(stat -c%s "$LOG_FILE")
if [ "$size" -ge "$MAX_SIZE" ]; then
    mv monitor.log monitor.log.1  # 이름 변경
fi
```

**방법 2 — logrotate (Linux 내장 도구)**
```
/var/log/agent-app/monitor.log {
    size 10M      # 10MB 초과 시 rotate
    rotate 10     # 최대 10개 보관
    compress      # 압축
}
```

---

## 13. crontab — 알람처럼 반복 실행

### cron이란?

cron은 **지정한 시간마다 자동으로 명령어/스크립트를 실행**하는 Linux 내장 스케줄러입니다. 스마트폰의 알람처럼 "매일 오전 9시", "매분", "매주 월요일" 등으로 설정할 수 있습니다.

### crontab 문법

```
*  *  *  *  *  실행할_명령어
│  │  │  │  │
│  │  │  │  └── 요일 (0=일, 1=월 ... 6=토)
│  │  │  └───── 월 (1~12)
│  │  └──────── 일 (1~31)
│  └─────────── 시 (0~23)
└────────────── 분 (0~59)

* 는 "모든"을 의미
```

**예시:**
```
* * * * *     → 매분 실행
0 * * * *     → 매 시간 0분에 실행 (매시 정각)
0 9 * * *     → 매일 오전 9시에 실행
0 9 * * 1     → 매주 월요일 오전 9시에 실행
*/5 * * * *   → 5분마다 실행
```

### 이번 미션 설정

```bash
* * * * * AGENT_HOME=... bash /path/monitor.sh >> /var/log/agent-app/cron.log 2>&1
```

- `* * * * *` → 매분 실행
- `AGENT_HOME=...` → 환경 변수 직접 지정 (cron은 .bashrc를 읽지 않음)
- `>> cron.log` → 출력을 cron.log에 추가 저장
- `2>&1` → 에러 메시지도 같은 파일에 저장

### cron이 .bashrc를 읽지 않는 이유

cron은 **로그인 쉘이 아닌 최소한의 환경**에서 실행됩니다. 사용자가 터미널로 로그인할 때 자동 실행되는 `.bashrc`가 cron에서는 실행되지 않습니다. 그래서 crontab에 환경 변수를 직접 명시해야 합니다.

```bash
# crontab에서 환경 변수 직접 지정
* * * * * AGENT_HOME=/home/agent-admin/agent-app bash monitor.sh
```

---

## 14. monitor.sh 해부 — 코드 한 줄씩 이해하기

전체 monitor.sh를 단계별로 설명합니다.

### 1단계: 변수 선언

```bash
AGENT_HOME=${AGENT_HOME:-/home/agent-admin/agent-app}
```

`${변수명:-기본값}` 문법:
- `AGENT_HOME`이 설정되어 있으면 그 값 사용
- 설정되어 있지 않으면 `/home/agent-admin/agent-app` 사용

### 2단계: 로그 용량 관리 (rotate_log 함수)

```bash
size=$(stat -c%s "$LOG_FILE")   # 파일 크기(바이트) 가져오기
if [ "$size" -ge "$MAX_LOG_SIZE" ]; then
    mv "$LOG_FILE" "${LOG_FILE}.1"   # 현재 로그를 .1로 이름 변경
fi
```

`stat -c%s 파일명` → 파일 크기를 바이트 단위로 출력

### 3단계: Health Check

```bash
PID=$(pgrep -f "$APP_PROCESS" | head -1)
if [ -z "$PID" ]; then
    echo "[FAIL]"
    exit 1   ← 여기서 종료. 이후 코드는 실행 안 됨
fi
```

`pgrep -f "이름"` → 프로세스 이름으로 PID를 검색

```bash
if ! ss -tlnp | grep -q ":${AGENT_PORT} "; then
    exit 1
fi
```

`grep -q` → 결과를 출력하지 않고 찾으면 종료코드 0(성공), 없으면 1(실패)
`!` → 결과를 반전 (없으면 if 조건 참)

### 4단계: CPU/메모리/디스크 수집

```bash
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)
```

- `top -bn1` → 1회만 실행 (-b: 배치모드, -n1: 1번)
- `grep "Cpu(s)"` → CPU 라인만 추출
- `awk '{print $2}'` → 두 번째 열 추출
- `cut -d. -f1` → 소수점 앞부분만 (25.3% → 25)

```bash
MEM_TOTAL=$(free | grep Mem | awk '{print $2}')
MEM_USED=$(free | grep Mem | awk '{print $3}')
MEM=$(echo "$MEM_USED $MEM_TOTAL" | awk '{printf "%.1f", $1/$2*100}')
```

- `free` → 메모리 사용 현황 출력
- `$1/$2*100` → (사용량 / 전체) × 100 = 사용률(%)

```bash
DISK=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
```

- `df /` → 루트(/) 파티션의 디스크 사용 현황
- `tail -1` → 마지막 줄 (헤더 제외)
- `tr -d '%'` → % 문자 제거 (숫자만 남김)

### 5단계: 로그 기록

```bash
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] PID:$PID CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK}%" >> "$LOG_FILE"
```

`>>` → 파일에 **추가** (덮어쓰기가 아님)
`>` → 파일을 새로 씀 (기존 내용 삭제)

---

## 15. Docker — 가상 컴퓨터 속 컴퓨터

### Docker란?

Docker는 **컨테이너(Container)** 라는 격리된 실행 환경을 만드는 도구입니다.

```
[Mac 또는 Windows]
    └── [Docker Engine]
            ├── [Ubuntu 컨테이너 A] ← agent-app 실행
            ├── [Ubuntu 컨테이너 B] ← 데이터베이스
            └── [Ubuntu 컨테이너 C] ← 웹 서버
```

### VM(가상머신)과의 차이

```
VM: 하드웨어까지 가상화 → 무겁고 느림 (수GB, 수분 부팅)
컨테이너: OS 커널은 공유, 프로세스만 격리 → 가볍고 빠름 (수MB, 수초 시작)
```

### 이번 미션에서 사용한 이유

- 로컬 Mac에서 Ubuntu Linux 환경을 바로 실행 가능
- 실습 후 컨테이너 삭제로 깔끔하게 정리 가능
- `--platform linux/amd64` 옵션으로 x86 바이너리도 실행 가능

### 주요 Docker 명령어

```bash
docker run -d --name 이름 ubuntu:24.04   # 컨테이너 생성 및 실행
docker exec 컨테이너명 bash -c "명령어"   # 컨테이너 안에서 명령 실행
docker ps                                 # 실행 중인 컨테이너 목록
docker stop 컨테이너명                    # 컨테이너 중지
docker rm 컨테이너명                      # 컨테이너 삭제
docker cp 파일 컨테이너명:/경로           # 파일 복사
```

### 포트 포워딩

컨테이너는 기본적으로 외부와 격리되어 있습니다. `-p` 옵션으로 **호스트 포트 → 컨테이너 포트**를 연결합니다.

```bash
docker run -p 20022:20022 -p 15034:15034 ubuntu:24.04
# 호스트의 20022 → 컨테이너의 20022
# 호스트의 15034 → 컨테이너의 15034
```

---

## 16. 전체 흐름 정리

이번 미션에서 구축한 시스템의 전체 그림입니다.

```
[Mac 노트북]
    │
    └── [Docker 컨테이너: Ubuntu 24.04]
            │
            ├── 보안 설정
            │   ├── SSH: 포트 20022, root 차단
            │   └── UFW: 20022, 15034만 허용
            │
            ├── 계정 체계
            │   ├── agent-admin (운영)
            │   ├── agent-dev   (개발)
            │   └── agent-test  (테스트)
            │
            ├── 디렉토리 구조
            │   ├── $AGENT_HOME/upload_files  (agent-common 접근)
            │   ├── $AGENT_HOME/api_keys      (agent-core 접근)
            │   ├── $AGENT_HOME/bin/          (스크립트)
            │   └── /var/log/agent-app/       (로그, agent-core 접근)
            │
            ├── 실행 중인 서비스
            │   └── agent-app (PID: 4863, 포트 15034 LISTEN)
            │
            └── 자동화
                ├── crontab (매분) → monitor.sh 실행
                │                      ├── Health Check (프로세스/포트)
                │                      ├── 자원 수집 (CPU/MEM/DISK)
                │                      ├── 경고 출력
                │                      └── monitor.log 기록
                ├── report.sh  → monitor.log 통계 분석
                └── archive.sh → 오래된 로그 압축/삭제
```

### 핵심 개념 요약

| 개념 | 한 줄 요약 |
|------|-----------|
| SSH | 인터넷으로 서버에 안전하게 원격 접속하는 방법 |
| 포트 | 서버의 여러 서비스가 기다리는 각각의 문 번호 |
| 방화벽 | 허용된 문(포트)만 열고 나머지는 잠그는 경비원 |
| 계정/그룹 | 역할별로 사람을 나누고 권한을 제한하는 체계 |
| 파일 권한 | 파일마다 누가 읽고 쓰고 실행할 수 있는지 지정 |
| 환경 변수 | 프로그램이 실행 시 참조하는 외부 설정값 |
| 프로세스 | 현재 실행 중인 프로그램과 그 ID |
| 쉘 스크립트 | 명령어를 파일에 모아서 자동으로 실행하는 프로그램 |
| 로그 | 서버에서 무슨 일이 일어났는지 기록하는 파일 |
| crontab | 지정한 시간마다 자동으로 작업을 실행하는 스케줄러 |
| Docker | 격리된 Linux 환경을 컨테이너로 실행하는 도구 |

---

> **한 줄 결론:**
> 이번 미션은 "서버가 살아있는지 자동으로 감시하고, 이상이 있으면 기록으로 남기는" 시스템을 처음부터 직접 만드는 과정이었습니다. 보안 설정 → 계정 관리 → 앱 실행 → 자동 모니터링의 흐름이 실제 현업 서버 운영과 동일합니다.
