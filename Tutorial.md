# B1-1 미션 직접 해보기 — 단계별 튜토리얼

> 이 튜토리얼은 명령어를 **복사·붙여넣기 하지 않고**, 직접 이해하며 따라하는 것을 목표로 합니다.
> 각 단계마다 **왜 하는지**를 읽고, 명령어를 직접 입력하세요.

---

## 준비물 체크

- [ ] Mac 또는 Linux 환경
- [ ] Docker Desktop 설치 ([docker.com](https://www.docker.com/products/docker-desktop/) 에서 다운로드)
- [ ] 터미널 앱 (Mac 기본 터미널 또는 iTerm2)
- [ ] `agent-app` 바이너리 파일

---

## STEP 0 — Docker 컨테이너 만들기

> **왜?** 내 Mac을 건드리지 않고 실제 Linux 서버처럼 실습할 수 있는 격리 환경이 필요합니다.

### 0-1. Docker Desktop 실행 확인

터미널을 열고 Docker가 정상 동작하는지 확인합니다.

```bash
docker --version
docker ps
```

✅ 버전 번호와 빈 컨테이너 목록이 나오면 정상입니다.

### 0-2. Ubuntu 24.04 컨테이너 생성

```bash
docker run -d \
  --name codyssey-b1 \
  --hostname agent-server \
  --platform linux/amd64 \
  -p 20022:20022 \
  -p 15034:15034 \
  --privileged \
  ubuntu:24.04 \
  /bin/bash -c "tail -f /dev/null"
```

> **옵션 설명:**
> - `-d` : 백그라운드로 실행
> - `--name` : 컨테이너 이름 지정
> - `--platform linux/amd64` : agent-app이 x86 바이너리라 필요
> - `-p 20022:20022` : 내 Mac의 20022 포트 → 컨테이너의 20022 포트로 연결
> - `--privileged` : UFW 방화벽 사용에 필요

### 0-3. 컨테이너 안으로 들어가기

```bash
docker exec -it codyssey-b1 bash
```

> 이제부터 명령어는 컨테이너 안(Ubuntu)에서 실행됩니다.

```bash
# 내가 어디 있는지, 어떤 OS인지 확인
whoami
cat /etc/os-release | grep VERSION
```

✅ `root`와 `Ubuntu 24.04` 가 나오면 정상입니다.

### 0-4. 필수 패키지 설치

```bash
apt-get update
apt-get install -y openssh-server sudo acl ufw python3 iproute2 procps cron bc
```

> 잠깐 기다리면 설치가 완료됩니다.

---

## STEP 1 — SSH 보안 설정

> **왜?** 기본 22번 포트는 전 세계 해커 봇이 1초에 수백 번 공격합니다.
> 포트를 변경하고 root 직접 로그인을 막는 것이 기본 보안입니다.

### 1-1. SSH 설정 파일 열기

```bash
# nano 편집기로 설정 파일 열기
nano /etc/ssh/sshd_config
```

> 편집기에서 아래 두 줄을 찾아 변경합니다. (`Ctrl+W` 로 검색)

**변경 전:**
```
#Port 22
#PermitRootLogin prohibit-password
```

**변경 후:**
```
Port 20022
PermitRootLogin no
```

> `Ctrl+O` → 저장, `Ctrl+X` → 종료

### 1-2. SSH 서비스 시작

```bash
mkdir -p /run/sshd
service ssh start
```

### 1-3. 확인

```bash
# 설정 파일에서 변경된 값 확인
grep -E "^Port|^PermitRootLogin" /etc/ssh/sshd_config

# 실제로 20022번 포트에서 기다리는지 확인
ss -tlnp | grep sshd
```

**예상 출력:**
```
Port 20022
PermitRootLogin no
```
```
tcp  LISTEN  0.0.0.0:20022  ...  sshd
```

✅ 두 결과 모두 확인되면 완료입니다.

---

## STEP 2 — 방화벽(UFW) 설정

> **왜?** 포트를 바꿔도 방화벽이 없으면 다른 포트가 열려 있을 수 있습니다.
> "필요한 포트만 열기" 원칙으로 최소한의 문만 열어둡니다.

### 2-1. 기본 정책 설정

```bash
# 들어오는 모든 트래픽 차단
ufw default deny incoming

# 나가는 모든 트래픽 허용
ufw default allow outgoing
```

### 2-2. 필요한 포트만 열기

```bash
# SSH 포트 허용
ufw allow 20022/tcp

# 앱 포트 허용
ufw allow 15034/tcp
```

### 2-3. 방화벽 활성화

```bash
ufw --force enable
```

### 2-4. 확인

```bash
ufw status verbose
```

**예상 출력:**
```
Status: active

To                         Action      From
20022/tcp                  ALLOW IN    Anywhere
15034/tcp                  ALLOW IN    Anywhere
```

✅ 두 포트만 허용된 것을 확인합니다.

---

## STEP 3 — 계정과 그룹 만들기

> **왜?** 역할에 따라 계정을 분리하면 실수나 침해 시 피해 범위를 줄일 수 있습니다.

### 3-1. 그룹 먼저 생성

```bash
groupadd agent-common
groupadd agent-core
```

### 3-2. 계정 생성 (그룹 포함)

```bash
# admin: common, core 둘 다
useradd -m -s /bin/bash -G agent-common,agent-core agent-admin

# dev: common, core 둘 다
useradd -m -s /bin/bash -G agent-common,agent-core agent-dev

# test: common만
useradd -m -s /bin/bash -G agent-common agent-test
```

> `-m` : 홈 디렉토리 생성
> `-s /bin/bash` : 기본 쉘을 bash로 설정
> `-G` : 추가 그룹 지정

### 3-3. agent-admin에게 sudo 권한 부여

```bash
echo 'agent-admin ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/agent-admin
chmod 440 /etc/sudoers.d/agent-admin
```

### 3-4. 확인

```bash
id agent-admin
id agent-dev
id agent-test
```

**예상 출력:**
```
uid=1001(agent-admin) ... groups=...,agent-common,agent-core
uid=1002(agent-dev)   ... groups=...,agent-common,agent-core
uid=1003(agent-test)  ... groups=...,agent-common
```

✅ 각 계정의 그룹 구성이 맞는지 확인합니다.

---

## STEP 4 — 디렉토리 구조와 권한 설정

> **왜?** 공용 디렉토리와 보안 디렉토리를 분리해야 중요한 파일(키, 로그)을
> 일부 인원만 접근할 수 있도록 보호할 수 있습니다.

### 4-1. 디렉토리 생성

```bash
AGENT_HOME=/home/agent-admin/agent-app

mkdir -p $AGENT_HOME/upload_files
mkdir -p $AGENT_HOME/api_keys
mkdir -p $AGENT_HOME/bin
mkdir -p /var/log/agent-app
```

### 4-2. 소유자 및 권한 설정

```bash
# upload_files: agent-common 그룹이 읽고 쓸 수 있게
chown agent-admin:agent-common $AGENT_HOME/upload_files
chmod 770 $AGENT_HOME/upload_files

# api_keys: agent-core 그룹만 읽고 쓸 수 있게
chown agent-admin:agent-core $AGENT_HOME/api_keys
chmod 770 $AGENT_HOME/api_keys

# 로그 디렉토리: agent-core 그룹만 읽고 쓸 수 있게
chown agent-admin:agent-core /var/log/agent-app
chmod 770 /var/log/agent-app
```

### 4-3. ACL 설정 (추가 접근 제어)

```bash
setfacl -m g:agent-common:rwx $AGENT_HOME/upload_files
setfacl -m g:agent-core:rwx $AGENT_HOME/api_keys
setfacl -m g:agent-core:rwx /var/log/agent-app
```

### 4-4. 확인

```bash
ls -la $AGENT_HOME/
getfacl $AGENT_HOME/upload_files
getfacl $AGENT_HOME/api_keys
```

> `drwxrwx---+` 처럼 끝에 `+` 가 붙으면 ACL이 적용된 것입니다.

**스스로 점검:**
- `upload_files` 의 그룹이 `agent-common` 인가?
- `api_keys` 의 그룹이 `agent-core` 인가?
- 둘 다 `rwx` 권한(770)인가?

---

## STEP 5 — 환경 변수와 키 파일 설정

> **왜?** 앱이 어디서 파일을 읽고, 어느 포트를 쓸지를 코드 밖에서 설정합니다.
> 환경 변수로 분리하면 경로가 바뀌어도 코드를 수정할 필요가 없습니다.

### 5-1. 환경 변수를 .bashrc에 추가

```bash
cat >> /home/agent-admin/.bashrc << 'EOF'
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
export AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key
export AGENT_LOG_DIR=/var/log/agent-app
EOF
```

### 5-2. 키 파일 생성

```bash
# 내용이 "agent_api_key_test" 인 파일 생성
echo 'agent_api_key_test' > /home/agent-admin/agent-app/api_keys/t_secret.key

# 소유자와 권한 설정
chown agent-admin:agent-core /home/agent-admin/agent-app/api_keys/t_secret.key
chmod 640 /home/agent-admin/agent-app/api_keys/t_secret.key
```

### 5-3. 확인

```bash
cat /home/agent-admin/agent-app/api_keys/t_secret.key
ls -la /home/agent-admin/agent-app/api_keys/
```

**예상 출력:**
```
agent_api_key_test
-rw-r----- agent-admin agent-core  t_secret.key
```

---

## STEP 6 — agent-app 실행하기

> **왜?** 앱이 5가지 Boot Check를 모두 통과해야 monitor.sh가 감시할 대상이 생깁니다.

### 6-1. 바이너리 파일을 컨테이너에 복사 (Mac 터미널에서)

> 새 터미널 탭을 열어서 Mac에서 실행합니다.

```bash
docker cp /Users/jonghan/Codyssey/B1-1/agent-app codyssey-b1:/home/agent-admin/agent-app/agent-app
```

### 6-2. 권한 설정 (컨테이너 터미널에서)

```bash
chown agent-admin:agent-core /home/agent-admin/agent-app/agent-app
chmod 750 /home/agent-admin/agent-app/agent-app
```

### 6-3. agent-admin 계정으로 실행

```bash
su - agent-admin -c '
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
export AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key
export AGENT_LOG_DIR=/var/log/agent-app
$AGENT_HOME/agent-app
'
```

**예상 출력:**
```
>>> Starting Agent Boot Sequence...
[1/5] Checking User Account               [OK]
[2/5] Verifying Environment Variables     [OK]
[3/5] Checking Required Files             [OK]
[4/5] Checking Port Availability          [OK]
[5/5] Verifying Log Permission            [OK]
------------------------------------------------------------
All Boot Checks Passed!
Agent READY
```

> `Ctrl+C` 로 종료합니다.

### 6-4. 백그라운드로 실행

```bash
su - agent-admin -c '
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
export AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key
export AGENT_LOG_DIR=/var/log/agent-app
nohup $AGENT_HOME/agent-app > /dev/null 2>&1 &
echo "PID: $!"
'
```

> `nohup ... &` : 터미널을 닫아도 계속 실행되게 백그라운드로 실행

### 6-5. 포트 리슨 확인

```bash
ss -tlnp | grep 15034
```

**예상 출력:**
```
LISTEN  0.0.0.0:15034  ...  agent-app
```

✅ LISTEN 상태면 앱이 정상 실행 중입니다.

---

## STEP 7 — monitor.sh 직접 작성하기

> **왜?** 이것이 이번 미션의 핵심입니다. 직접 타이핑하면서 각 줄의 역할을 이해합니다.

### 7-1. 파일 생성

```bash
nano /home/agent-admin/agent-app/bin/monitor.sh
```

### 7-2. 아래 내용을 직접 타이핑하며 입력

> 복사·붙여넣기 대신 직접 타이핑하면서 각 줄이 무엇을 하는지 생각해보세요.

```bash
#!/bin/bash

# ── 설정값 ──────────────────────────────────────
AGENT_HOME=${AGENT_HOME:-/home/agent-admin/agent-app}
AGENT_PORT=${AGENT_PORT:-15034}
AGENT_LOG_DIR=${AGENT_LOG_DIR:-/var/log/agent-app}
LOG_FILE="$AGENT_LOG_DIR/monitor.log"
APP_PROCESS="agent-app"
MAX_LOG_SIZE=$((10 * 1024 * 1024))
MAX_LOG_COUNT=10

CPU_THRESHOLD=20
MEM_THRESHOLD=10
DISK_THRESHOLD=80

echo "====== SYSTEM MONITOR RESULT ======"
echo ""

# ── 로그 용량 관리 ───────────────────────────────
rotate_log() {
    [ ! -f "$LOG_FILE" ] && return
    local size
    size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
    if [ "$size" -ge "$MAX_LOG_SIZE" ]; then
        for i in $(seq $((MAX_LOG_COUNT - 1)) -1 1); do
            [ -f "${LOG_FILE}.$i" ] && mv "${LOG_FILE}.$i" "${LOG_FILE}.$((i+1))"
        done
        mv "$LOG_FILE" "${LOG_FILE}.1"
    fi
}

rotate_log

# ── Health Check ─────────────────────────────────
echo "[HEALTH CHECK]"

PID=$(pgrep -f "$APP_PROCESS" | head -1)
if [ -z "$PID" ]; then
    echo "Checking process '$APP_PROCESS'... [FAIL]"
    exit 1
fi
echo "Checking process '$APP_PROCESS'... [OK] (PID: $PID)"

if ! ss -tlnp 2>/dev/null | grep -q ":${AGENT_PORT} "; then
    echo "Checking port $AGENT_PORT... [FAIL]"
    exit 1
fi
echo "Checking port $AGENT_PORT... [OK]"
echo ""

# ── 방화벽 상태 점검 ─────────────────────────────
if command -v ufw &>/dev/null; then
    UFW_STATUS=$(ufw status 2>/dev/null | head -1)
    if echo "$UFW_STATUS" | grep -q "inactive"; then
        echo "[WARNING] Firewall (ufw) is inactive"
    fi
fi

# ── 자원 수집 ────────────────────────────────────
echo "[RESOURCE MONITORING]"

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)
[ -z "$CPU" ] && CPU=$(top -bn1 | grep "%Cpu" | awk '{print $2}' | cut -d. -f1)

MEM_INFO=$(free | grep Mem)
MEM_TOTAL=$(echo "$MEM_INFO" | awk '{print $2}')
MEM_USED=$(echo "$MEM_INFO" | awk '{print $3}')
MEM=$(echo "$MEM_USED $MEM_TOTAL" | awk '{printf "%.1f", $1/$2*100}')
MEM_INT=$(echo "$MEM" | cut -d. -f1)

DISK=$(df / | tail -1 | awk '{print $5}' | tr -d '%')

echo "CPU Usage : ${CPU}%"
echo "MEM Usage : ${MEM}%"
echo "DISK Used  : ${DISK}%"
echo ""

# ── 임계값 경고 ──────────────────────────────────
[ "$CPU" -gt "$CPU_THRESHOLD" ] 2>/dev/null && \
    echo "[WARNING] CPU threshold exceeded (${CPU}% > ${CPU_THRESHOLD}%)"

[ "$MEM_INT" -gt "$MEM_THRESHOLD" ] 2>/dev/null && \
    echo "[WARNING] MEM threshold exceeded (${MEM}% > ${MEM_THRESHOLD}%)"

[ "$DISK" -gt "$DISK_THRESHOLD" ] 2>/dev/null && \
    echo "[WARNING] DISK threshold exceeded (${DISK}% > ${DISK_THRESHOLD}%)"

# ── 로그 기록 ────────────────────────────────────
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] PID:$PID CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK}%" >> "$LOG_FILE"
echo ""
echo "[INFO] Log appended: $LOG_FILE"
echo "======================================"
```

> `Ctrl+O` → 저장, `Ctrl+X` → 종료

### 7-3. 권한 설정

```bash
# 소유자: agent-dev, 그룹: agent-core, 권한: 750
chown agent-dev:agent-core /home/agent-admin/agent-app/bin/monitor.sh
chmod 750 /home/agent-admin/agent-app/bin/monitor.sh

# 확인
ls -la /home/agent-admin/agent-app/bin/monitor.sh
```

**예상 출력:**
```
-rwxr-x---  agent-dev  agent-core  monitor.sh
```

### 7-4. 직접 실행해보기

```bash
su - agent-admin -c '
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_LOG_DIR=/var/log/agent-app
bash /home/agent-admin/agent-app/bin/monitor.sh
'
```

✅ Health Check [OK], 자원 수치, 로그 기록 메시지가 나오면 성공입니다.

### 7-5. 로그 파일 확인

```bash
cat /var/log/agent-app/monitor.log
```

---

## STEP 8 — crontab 등록

> **왜?** 사람이 직접 monitor.sh를 실행하는 건 현실적이지 않습니다.
> cron으로 자동화하면 1분마다 자동으로 상태가 기록됩니다.

### 8-1. cron 서비스 시작

```bash
service cron start
```

### 8-2. agent-admin의 crontab 편집

```bash
su - agent-admin -c 'crontab -e'
```

> 편집기가 열리면 맨 아래에 다음 줄을 추가합니다:

```
* * * * * AGENT_HOME=/home/agent-admin/agent-app AGENT_PORT=15034 AGENT_LOG_DIR=/var/log/agent-app bash /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/cron.log 2>&1
```

> `* * * * *` = 매분 실행
> 저장 후 종료합니다.

### 8-3. 등록 확인

```bash
su - agent-admin -c 'crontab -l'
```

### 8-4. 1~2분 기다린 후 로그 자동 누적 확인

```bash
# 현재 라인 수 확인
wc -l /var/log/agent-app/monitor.log

# 1분 후 다시 확인 → 숫자가 늘어야 함
wc -l /var/log/agent-app/monitor.log

# 최근 로그 보기
tail -5 /var/log/agent-app/monitor.log
```

✅ 1분마다 새 줄이 추가되면 완료입니다!

---

## STEP 9 — 보너스: report.sh 작성

> monitor.log를 분석해 통계를 뽑는 스크립트입니다.

```bash
nano /home/agent-admin/agent-app/bin/report.sh
```

```bash
#!/bin/bash

AGENT_LOG_DIR=${AGENT_LOG_DIR:-/var/log/agent-app}
LOG_FILE="$AGENT_LOG_DIR/monitor.log"

START_TIME=""
END_TIME=""

while getopts "s:e:" opt; do
    case $opt in
        s) START_TIME="$OPTARG" ;;
        e) END_TIME="$OPTARG" ;;
    esac
done

if [ ! -f "$LOG_FILE" ]; then
    echo "[ERROR] 로그 파일 없음: $LOG_FILE"
    exit 1
fi

FILTERED=$(awk -v start="$START_TIME" -v end="$END_TIME" '
/^\[/ {
    ts = substr($0, 2, 19)
    if (start != "" && ts < start) next
    if (end   != "" && ts > end)   next
    print
}
' "$LOG_FILE")

if [ -z "$FILTERED" ]; then
    echo "[WARNING] 해당 구간에 데이터 없음"
    exit 0
fi

calc_stats() {
    local field="$1"
    echo "$FILTERED" | awk -v field="$field" '
    {
        for (i=1; i<=NF; i++) {
            if ($i ~ field":") {
                val = $i
                sub(field":", "", val)
                gsub("%", "", val)
                ts = substr($0, 2, 19)
                sum += val+0
                count++
                if (count==1 || val+0 > max_val) { max_val=val+0; max_ts=ts }
                if (count==1 || val+0 < min_val) { min_val=val+0; min_ts=ts }
            }
        }
    }
    END {
        if (count==0) exit
        printf "    Average : %.1f%%\n", sum/count
        printf "    Maximum : %.1f%% at %s\n", max_val, max_ts
        printf "    Minimum : %.1f%% at %s\n", min_val, min_ts
    }
    '
}

echo "====== STATISTICS REPORT ======"
[ -n "$START_TIME" ] && echo "  From : $START_TIME"
[ -n "$END_TIME"   ] && echo "  To   : $END_TIME"
echo ""
echo "  [CPU]"
calc_stats "CPU"
echo "  [Memory]"
calc_stats "MEM"
echo "  [Disk]"
calc_stats "DISK_USED"
SAMPLE_COUNT=$(echo "$FILTERED" | grep -c "^\[")
echo "  [Samples]"
echo "    Data Points: $SAMPLE_COUNT samples"
echo ""
echo "=============================="
```

```bash
chown agent-dev:agent-core /home/agent-admin/agent-app/bin/report.sh
chmod 750 /home/agent-admin/agent-app/bin/report.sh
```

**실행 테스트:**
```bash
su - agent-admin -c '
export AGENT_LOG_DIR=/var/log/agent-app
bash /home/agent-admin/agent-app/bin/report.sh
'
```

**구간 필터 테스트:**
```bash
bash report.sh -s '2026-05-14 06:30:00' -e '2026-05-14 06:35:00'
```

---

## STEP 10 — 보너스: archive.sh 작성

> 오래된 로그를 자동으로 압축·이동·삭제하는 스크립트입니다.

```bash
nano /home/agent-admin/agent-app/bin/archive.sh
```

```bash
#!/bin/bash

AGENT_LOG_DIR=${AGENT_LOG_DIR:-/var/log/agent-app}
ARCHIVE_DIR="/var/log/monitor/agent-app/archive"
COMPRESS_DAYS=7
DELETE_DAYS=30

log_info()  { echo "[INFO]    $*"; }
log_warn()  { echo "[WARNING] $*"; }
log_error() { echo "[ERROR]   $*"; }

# 아카이브 디렉토리 확인
if [ ! -d "$ARCHIVE_DIR" ]; then
    mkdir -p "$ARCHIVE_DIR" 2>/dev/null || {
        log_error "디렉토리 생성 실패: $ARCHIVE_DIR"
        exit 1
    }
    log_info "디렉토리 생성: $ARCHIVE_DIR"
fi

[ ! -w "$ARCHIVE_DIR" ] && { log_error "쓰기 권한 없음: $ARCHIVE_DIR"; exit 1; }
[ ! -d "$AGENT_LOG_DIR" ] && { log_error "로그 디렉토리 없음: $AGENT_LOG_DIR"; exit 1; }

echo "====== LOG ARCHIVE PROCESS ======"
echo ""

# Step 1: 7일 경과 로그 압축
log_info "Step 1: ${COMPRESS_DAYS}일 경과 로그 압축 및 아카이브 이동"
COUNT=0

while IFS= read -r -d '' filepath; do
    filename=$(basename "$filepath")
    gz_path="$ARCHIVE_DIR/${filename}.gz"

    [ -f "$gz_path" ] && { log_warn "이미 존재, 건너뜀: ${filename}.gz"; continue; }
    [ ! -r "$filepath" ] && { log_warn "읽기 권한 없음: $filepath"; continue; }

    if gzip -c "$filepath" > "$gz_path" 2>/dev/null; then
        rm -f "$filepath"
        log_info "압축 완료: $filename → $gz_path"
        COUNT=$((COUNT + 1))
    else
        rm -f "$gz_path"
        log_warn "압축 실패: $filepath"
    fi
done < <(find "$AGENT_LOG_DIR" -maxdepth 1 -name "*.log" -mtime +${COMPRESS_DAYS} -print0 2>/dev/null)

[ "$COUNT" -eq 0 ] && log_info "${COMPRESS_DAYS}일 경과 파일 없음" || log_info "완료: ${COUNT}개"
echo ""

# Step 2: 30일 경과 아카이브 삭제
log_info "Step 2: ${DELETE_DAYS}일 경과 아카이브 삭제"
COUNT=0

while IFS= read -r -d '' filepath; do
    if rm -f "$filepath" 2>/dev/null; then
        log_info "삭제: $(basename "$filepath")"
        COUNT=$((COUNT + 1))
    else
        log_warn "삭제 실패: $filepath"
    fi
done < <(find "$ARCHIVE_DIR" -maxdepth 1 -name "*.gz" -mtime +${DELETE_DAYS} -print0 2>/dev/null)

[ "$COUNT" -eq 0 ] && log_info "${DELETE_DAYS}일 경과 파일 없음" || log_info "완료: ${COUNT}개"
echo ""
log_info "아카이브 처리 완료"
echo "=================================="
```

```bash
chown agent-dev:agent-core /home/agent-admin/agent-app/bin/archive.sh
chmod 750 /home/agent-admin/agent-app/bin/archive.sh
```

**동작 테스트 (오래된 파일 시뮬레이션):**

```bash
# 10일 전 파일 생성
echo "test" > /var/log/agent-app/old.log
touch -d '2026-05-04 10:00:00' /var/log/agent-app/old.log

# archive.sh 실행
su - agent-admin -c '
export AGENT_LOG_DIR=/var/log/agent-app
bash /home/agent-admin/agent-app/bin/archive.sh
'

# 결과 확인
ls /var/log/monitor/agent-app/archive/
```

---

## 최종 점검 체크리스트

모든 STEP을 마쳤다면 아래를 직접 확인해보세요.

```bash
# 1. SSH 포트와 root 차단
grep -E "^Port|^PermitRootLogin" /etc/ssh/sshd_config

# 2. 방화벽 상태
ufw status

# 3. 계정 그룹 확인
id agent-admin && id agent-dev && id agent-test

# 4. 디렉토리 권한
ls -la /home/agent-admin/agent-app/
getfacl /home/agent-admin/agent-app/api_keys

# 5. 앱 실행 중 확인
pgrep -f agent-app && ss -tlnp | grep 15034

# 6. monitor.sh 권한
ls -la /home/agent-admin/agent-app/bin/monitor.sh

# 7. crontab 등록 확인
su - agent-admin -c 'crontab -l'

# 8. 로그 자동 누적 확인
tail -5 /var/log/agent-app/monitor.log
```

---

## 자주 만나는 오류와 해결법

| 오류 메시지 | 원인 | 해결 |
|------------|------|------|
| `Permission denied` | 권한 부족 | `ls -la` 로 권한 확인, `chmod`/`chown` 수정 |
| `pgrep: command not found` | procps 미설치 | `apt install procps` |
| `GLIBC_2.38 not found` | Ubuntu 버전 낮음 | Ubuntu 24.04 사용 |
| cron 실행 안 됨 | 환경 변수 없음 | crontab에 환경 변수 직접 명시 |
| `ss: command not found` | iproute2 미설치 | `apt install iproute2` |
| UFW 작동 안 됨 | `--privileged` 없음 | 컨테이너 재생성 시 `--privileged` 추가 |

---

> **마무리:**
> 튜토리얼을 따라하면서 막히는 부분이 있으면 Study.md의 관련 챕터를 다시 읽어보세요.
> 오류 메시지를 무시하지 말고, 메시지를 읽고 원인을 파악하는 습관이 중요합니다.
