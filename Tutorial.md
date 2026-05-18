# B1-1 미션 직접 해보기 — 단계별 튜토리얼

> 이 튜토리얼은 명령어를 **복사·붙여넣기 하지 않고**, 직접 이해하며 따라하는 것을 목표로 합니다.
> 각 단계마다 **왜 하는지**를 읽고, 명령어를 직접 입력하세요.

> **출력 표기 규칙:**
> - ✅ **예상 출력** — 이렇게 나오면 정상
> - ⚠️ **주의** — 이렇게 나오면 확인 필요
> - ❌ **오류** — 이렇게 나오면 문제 있음
> - 📭 **출력 없음** — 아무것도 안 나오면 정상 (Linux는 성공 시 침묵)

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

```bash
docker --version
```

| 부분 | 설명 |
|------|------|
| `docker` | Docker CLI 명령어 |
| `--version` | 설치된 버전 출력. `--`로 시작하는 옵션은 긴 이름 형식 |

✅ **예상 출력:**
```
Docker version 28.x.x, build xxxxxxx
```

❌ **오류 시:**
```
command not found: docker   → Docker Desktop이 설치되지 않았거나 실행 중이지 않음
```
→ Docker Desktop 앱을 실행하고 상단 메뉴바에 고래 아이콘이 뜰 때까지 기다린 후 재시도

---

```bash
docker ps
```

| 부분 | 설명 |
|------|------|
| `ps` | Process Status. 현재 **실행 중인** 컨테이너 목록 출력 |

✅ **예상 출력:**
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```
(아직 컨테이너가 없으므로 헤더만 나옴)

❌ **오류 시:**
```
Cannot connect to the Docker daemon   → Docker Desktop이 실행되지 않은 상태
```

---

### 0-2. Ubuntu 24.04 컨테이너 생성

> `\` (백슬래시)는 **줄 이어쓰기** 기호입니다.
> `\` 뒤에 **스페이스가 없어야** 합니다. 스페이스가 있으면 `Usage: docker run...` 오류가 납니다.

```bash
docker run -d \
  --name codyssey-b1-1 \
  --hostname agent-server \
  --platform linux/amd64 \
  -p 20022:20022 \
  -p 15034:15034 \
  --privileged \
  ubuntu:24.04 \
  /bin/bash -c "tail -f /dev/null"
```

| 옵션 | 설명 |
|------|------|
| `run` | 새 컨테이너를 만들고 실행하는 서브명령어 |
| `-d` | Detach. 백그라운드로 실행. 없으면 터미널이 컨테이너에 붙잡혀 다른 명령을 못 입력함 |
| `--name codyssey-b1-1` | 컨테이너에 이름 지정. 없으면 Docker가 랜덤 이름 부여 (`vigorous_einstein` 같은 식) |
| `--hostname agent-server` | 컨테이너 내부에서 보이는 호스트명. 프롬프트에 `root@agent-server`로 표시됨 |
| `--platform linux/amd64` | x86_64 아키텍처로 실행. Apple Silicon(M1/M2) Mac은 ARM이라 x86 바이너리를 그냥 못 돌림 |
| `-p 20022:20022` | 포트 포워딩. `호스트포트:컨테이너포트`. 내 Mac의 20022 → 컨테이너의 20022 |
| `-p 15034:15034` | 동일하게 앱 포트도 포워딩 |
| `--privileged` | 컨테이너에 확장 권한 부여. UFW 방화벽이 커널 기능을 건드리기 때문에 필요 |
| `ubuntu:24.04` | 사용할 이미지. `이미지이름:태그` 형식. 로컬에 없으면 Docker Hub에서 자동 다운로드 |
| `/bin/bash -c "tail -f /dev/null"` | 컨테이너가 바로 꺼지지 않도록 아무것도 안 하면서 계속 실행되는 트릭 |

✅ **예상 출력 (이미지 다운로드 첫 실행 시):**
```
Unable to find image 'ubuntu:24.04' locally
24.04: Pulling from library/ubuntu
...
Status: Downloaded newer image for ubuntu:24.04
0542218e3931...   ← 컨테이너 ID (64자리 해시)
```

✅ **예상 출력 (이미지가 이미 있을 때):**
```
0542218e3931...   ← 컨테이너 ID만 출력
```

---

### 0-3. 컨테이너 안으로 들어가기

```bash
docker exec -it codyssey-b1-1 bash
```

| 부분 | 설명 |
|------|------|
| `exec` | 이미 실행 중인 컨테이너 안에서 명령어 실행 |
| `-i` | Interactive. 표준 입력(키보드)을 컨테이너로 전달 |
| `-t` | TTY. 터미널처럼 보이게 가상 터미널 할당. `-i`와 보통 함께 씀 (`-it`) |
| `codyssey-b1-1` | 대상 컨테이너 이름 |
| `bash` | 컨테이너 안에서 실행할 명령어. bash 쉘을 열겠다는 뜻 |

✅ **예상 출력:**
```
root@agent-server:/#
```
> 프롬프트가 `root@agent-server:/#` 로 바뀌면 컨테이너 안에 들어온 것입니다.
> 이제부터 명령어는 **컨테이너 안(Ubuntu)에서 실행**됩니다.

---

```bash
whoami
```

✅ **예상 출력:**
```
root
```

```bash
cat /etc/os-release | grep VERSION
```

| 부분 | 설명 |
|------|------|
| `cat` | 파일 내용을 출력 |
| `\|` | 파이프(Pipe). 왼쪽 출력을 오른쪽 명령어의 입력으로 전달 |
| `grep VERSION` | `VERSION`이 포함된 줄만 필터링 |

✅ **예상 출력:**
```
VERSION="24.04.2 LTS (Noble Numbat)"
VERSION_ID="24.04"
VERSION_CODENAME=noble
```

---

### 0-4. 필수 패키지 설치

```bash
apt-get update
```

| 부분 | 설명 |
|------|------|
| `apt-get` | Ubuntu/Debian 계열의 패키지 관리자 |
| `update` | 설치 가능한 패키지 목록을 최신으로 갱신. 실제 설치는 안 함 |

✅ **예상 출력 (마지막 부분):**
```
...
Reading package lists... Done
```

---

```bash
apt-get install -y nano openssh-server sudo acl ufw python3 iproute2 procps cron bc
```

| 패키지 | 설명 |
|--------|------|
| `-y` | 설치 중 확인 질문을 자동으로 yes 처리 |
| `nano` | 터미널 텍스트 편집기 |
| `openssh-server` | SSH 서버 데몬(sshd) |
| `sudo` | 일반 계정이 관리자 권한 명령 실행 시 사용 |
| `acl` | `setfacl`, `getfacl` 명령어 제공 |
| `ufw` | 방화벽 관리 도구 |
| `python3` | Python 3 인터프리터 |
| `iproute2` | `ss`, `ip` 등 네트워크 도구 |
| `procps` | `ps`, `pgrep` 등 프로세스 도구 |
| `cron` | 주기적 작업 스케줄러 |
| `bc` | 소수점 계산기 |

✅ **예상 출력 (마지막 부분):**
```
...
Processing triggers for ca-certificates ...
done.
```

---

## STEP 1 — SSH 보안 설정

> **왜?** 기본 22번 포트는 해커 봇이 1초에 수백 번 공격합니다.
> 포트를 변경하고 root 직접 로그인을 막는 것이 기본 보안입니다.

### 1-1. SSH 설정 파일 열기

```bash
nano /etc/ssh/sshd_config
```

| 부분 | 설명 |
|------|------|
| `nano` | 터미널 기반 텍스트 편집기 |
| `/etc/ssh/sshd_config` | SSH 서버 설정 파일. `/etc`는 설정 파일들이 모여있는 디렉토리 |

✅ **예상 화면:** nano 편집기가 열리며 설정 파일 내용이 표시됩니다.
```
GNU nano x.x        /etc/ssh/sshd_config

# This is the sshd server system-wide configuration file.
...
```
> 화면 하단에 `^G Help  ^X Exit  ^O Write Out` 등 단축키 안내가 표시됩니다.

**nano 주요 단축키:**
- `Ctrl+W` : 검색
- `Ctrl+O` → `Enter` : 저장
- `Ctrl+X` : 종료

**`#Port 22` 줄을 찾아서 아래처럼 변경합니다:**

```
변경 전: #Port 22
변경 후: Port 20022
```

```
변경 전: #PermitRootLogin prohibit-password
변경 후: PermitRootLogin no
```

> `#`은 주석 기호입니다. 제거하고 값을 바꿔야 적용됩니다.

저장(`Ctrl+O` → `Enter`) 후 종료(`Ctrl+X`)

> **대안: sed로 한 번에 처리하기**
> nano 대신 아래 명령어로 동일한 결과를 낼 수 있습니다.
> ```bash
> sed -i 's/#Port 22/Port 20022/' /etc/ssh/sshd_config
> sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
> ```
> `sed -i`는 파일을 직접 수정하는 자동화에 적합한 방식입니다. 자동화 스크립트나 반복 작업에 유용하지만, 처음에는 nano로 파일 구조를 직접 눈으로 확인하는 것을 권장합니다.

---

### 1-2. SSH 서비스 시작

```bash
mkdir -p /run/sshd
```

| 부분 | 설명 |
|------|------|
| `mkdir -p` | 디렉토리 생성. `-p`는 이미 있어도 오류 없이 무시 |
| `/run/sshd` | sshd 실행 시 필요한 디렉토리. 없으면 sshd 시작 실패 |

📭 **예상 출력:** 없음 (성공 시 침묵)

---

```bash
service ssh start
```

| 부분 | 설명 |
|------|------|
| `service` | Linux 서비스 관리 명령어 |
| `ssh` | 관리할 서비스 이름 |
| `start` | 시작. 다른 옵션: `stop`(중지), `restart`(재시작), `status`(상태확인) |

✅ **예상 출력:**
```
 * Starting OpenBSD Secure Shell server sshd
   ...done.
```

❌ **오류 시:**
```
Missing privilege separation directory: /run/sshd  → mkdir -p /run/sshd 를 먼저 실행
```

---

### 1-3. 확인

```bash
grep -E "^Port|^PermitRootLogin" /etc/ssh/sshd_config
```

| 부분 | 설명 |
|------|------|
| `grep` | 파일에서 특정 패턴을 찾아 출력 |
| `-E` | Extended regex. 정규표현식 확장 모드 |
| `^Port` | `^`는 줄의 시작. `Port`로 시작하는 줄만 매칭 (`#Port`는 제외됨) |
| `\|` | OR 조건 |

✅ **예상 출력:**
```
Port 20022
PermitRootLogin no
```

⚠️ **이렇게 나오면 안 됨:**
```
#Port 22              → # 을 지우지 않은 것. nano로 다시 열어서 수정
#PermitRootLogin ...  → 동일
```

---

```bash
ss -tlnp | grep sshd
```

| 부분 | 설명 |
|------|------|
| `ss` | Socket Statistics. 네트워크 소켓 상태 확인 |
| `-t` | TCP 소켓만 |
| `-l` | Listening(대기 중) 상태만 |
| `-n` | IP/포트를 숫자로 표시 |
| `-p` | 어떤 프로세스가 사용 중인지 표시 |
| `\| grep sshd` | sshd 관련 줄만 필터링 |

✅ **예상 출력:**
```
tcp  LISTEN  0  128  0.0.0.0:20022  0.0.0.0:*  users:(("sshd",pid=...,fd=3))
tcp  LISTEN  0  128     [::]:20022     [::]:*  users:(("sshd",pid=...,fd=4))
```

❌ **아무것도 안 나오면:** service ssh start 가 실패한 것. `service ssh status` 로 상태 확인

---

## STEP 2 — 방화벽(UFW) 설정

> **왜?** 필요한 포트(20022, 15034)만 열고 나머지는 모두 차단합니다.

### 2-1. 기본 정책 설정

```bash
ufw default deny incoming
```

| 부분 | 설명 |
|------|------|
| `ufw` | Uncomplicated Firewall |
| `default deny incoming` | 들어오는 모든 트래픽을 기본적으로 차단 |

✅ **예상 출력:**
```
Default incoming policy changed to 'deny'
(be sure to update your rules accordingly)
```

---

```bash
ufw default allow outgoing
```

✅ **예상 출력:**
```
Default outgoing policy changed to 'allow'
(be sure to update your rules accordingly)
```

---

### 2-2. 필요한 포트만 열기

```bash
ufw allow 20022/tcp
```

| 부분 | 설명 |
|------|------|
| `allow` | 해당 포트 허용 규칙 추가 |
| `20022` | 포트 번호 |
| `/tcp` | TCP 프로토콜만 허용 |

✅ **예상 출력:**
```
Rules updated
Rules updated (v6)
```

---

```bash
ufw allow 15034/tcp
```

✅ **예상 출력:**
```
Rules updated
Rules updated (v6)
```

---

### 2-3. 방화벽 활성화

```bash
ufw --force enable
```

| 부분 | 설명 |
|------|------|
| `--force` | "SSH가 끊길 수 있습니다" 확인을 자동 yes 처리 |
| `enable` | 방화벽 활성화 |

✅ **예상 출력:**
```
Firewall is active and enabled on system startup
```

---

### 2-4. 확인

```bash
ufw status verbose
```

✅ **예상 출력:**
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), deny (routed)

To                         Action      From
--                         ------      ----
20022/tcp                  ALLOW IN    Anywhere
15034/tcp                  ALLOW IN    Anywhere
20022/tcp (v6)             ALLOW IN    Anywhere (v6)
15034/tcp (v6)             ALLOW IN    Anywhere (v6)
```

⚠️ **`Status: inactive` 가 나오면:** `ufw --force enable` 을 다시 실행

---

## STEP 3 — 계정과 그룹 만들기

> **왜?** 역할에 따라 계정을 분리하면 실수나 침해 시 피해 범위를 줄일 수 있습니다.

### 3-1. 그룹 먼저 생성

> ⚠️ **반드시 그룹을 먼저 만들고 계정을 만들어야 합니다.**
> 그룹 없이 `useradd -G agent-common ...` 하면 `useradd: group 'agent-common' does not exist` 오류가 납니다.

```bash
groupadd agent-common
```

| 부분 | 설명 |
|------|------|
| `groupadd` | 새 그룹 생성 |
| `agent-common` | 그룹 이름. admin/dev/test 모두 포함될 공용 그룹 |

📭 **예상 출력:** 없음 (성공 시 침묵)

❌ **오류 시:**
```
groupadd: group 'agent-common' already exists  → 이미 있음. 무시하고 진행
```

---

```bash
groupadd agent-core
```

📭 **예상 출력:** 없음 (성공 시 침묵)

---

### 3-2. 계정 생성

```bash
useradd -m -s /bin/bash -G agent-common,agent-core agent-admin
```

| 옵션 | 설명 |
|------|------|
| `useradd` | 새 계정 생성 |
| `-m` | 홈 디렉토리(`/home/agent-admin`) 자동 생성 |
| `-s /bin/bash` | 기본 쉘을 bash로 지정 |
| `-G agent-common,agent-core` | 추가로 속할 그룹 (콤마로 구분, 스페이스 없이) |
| `agent-admin` | 생성할 계정 이름 (마지막 인자) |

📭 **예상 출력:** 없음 (성공 시 침묵)

❌ **오류 시:**
```
useradd: group 'agent-common' does not exist  → 3-1 단계 groupadd를 먼저 실행
useradd: group '' does not exist              → -G 뒤에 공백이 들어간 것. 명령어 다시 확인
```

---

```bash
useradd -m -s /bin/bash -G agent-common,agent-core agent-dev
useradd -m -s /bin/bash -G agent-common agent-test
```

📭 **예상 출력:** 없음 (두 명령 모두 성공 시 침묵)

---

### 3-3. sudo 권한 부여

```bash
echo 'agent-admin ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/agent-admin
```

| 부분 | 설명 |
|------|------|
| `echo '...'` | 텍스트 출력 |
| `>` | 출력을 파일에 저장 (없으면 생성, 있으면 덮어씀) |
| `/etc/sudoers.d/agent-admin` | sudo 설정 파일 경로 |

📭 **예상 출력:** 없음

---

```bash
chmod 440 /etc/sudoers.d/agent-admin
```

| 부분 | 설명 |
|------|------|
| `chmod 440` | `r--r-----`. 소유자/그룹 읽기만, 기타 접근 불가. sudo는 쓰기 권한 있는 파일을 무시함 |

📭 **예상 출력:** 없음

---

### 3-4. 확인

```bash
id agent-admin
```

| 부분 | 설명 |
|------|------|
| `id` | 계정의 UID, GID, 소속 그룹 정보 출력 |

✅ **예상 출력:**
```
uid=1001(agent-admin) gid=1003(agent-admin) groups=1003(agent-admin),1001(agent-common),1002(agent-core)
```

---

```bash
id agent-dev
```

✅ **예상 출력:**
```
uid=1002(agent-dev) gid=1004(agent-dev) groups=1004(agent-dev),1001(agent-common),1002(agent-core)
```

---

```bash
id agent-test
```

✅ **예상 출력:**
```
uid=1003(agent-test) gid=1005(agent-test) groups=1005(agent-test),1001(agent-common)
```
> agent-test는 `agent-common`만 있고 `agent-core`가 없는 것이 맞습니다.

---

## STEP 4 — 디렉토리 구조와 권한 설정

> **왜?** 공용 파일(upload_files)과 보안 파일(api_keys, 로그)의 접근 범위를 분리합니다.

### 4-1. 디렉토리 생성

```bash
AGENT_HOME=/home/agent-admin/agent-app
```

> 쉘 변수 선언. `=` 양쪽에 스페이스 없어야 합니다.

📭 **예상 출력:** 없음

```bash
mkdir -p $AGENT_HOME/upload_files
mkdir -p $AGENT_HOME/api_keys
mkdir -p $AGENT_HOME/bin
mkdir -p /var/log/agent-app
```

| 부분 | 설명 |
|------|------|
| `mkdir -p` | 중간 경로 포함 생성. 이미 있어도 오류 없음 |
| `$AGENT_HOME` | 앞서 선언한 변수값으로 치환됨 |

📭 **예상 출력:** 없음 (4줄 모두 성공 시 침묵)

---

### 4-2. 소유자 및 권한 설정

```bash
chown agent-admin:agent-core $AGENT_HOME
chown agent-admin:agent-core $AGENT_HOME/bin
chown agent-admin:agent-common $AGENT_HOME/upload_files
chmod 770 $AGENT_HOME/upload_files
```

| 부분 | 설명 |
|------|------|
| `chown 소유자:그룹` | 소유자와 그룹 동시 변경 |
| `chmod 770` | rwxrwx---. 소유자+그룹은 모두 허용, 기타는 차단 |

> `mkdir`은 root로 실행했기 때문에 `agent-app` 자체와 `bin`도 소유자가 `root`입니다. 명시적으로 변경해야 합니다.

📭 **예상 출력:** 없음 (4줄 모두 성공 시 침묵)

---

```bash
chown agent-admin:agent-core $AGENT_HOME/api_keys
chmod 770 $AGENT_HOME/api_keys
chown agent-admin:agent-core /var/log/agent-app
chmod 770 /var/log/agent-app
```

📭 **예상 출력:** 없음 (4줄 모두 성공 시 침묵)

---

### 4-3. ACL 설정

```bash
setfacl -m g:agent-common:rwx $AGENT_HOME/upload_files
setfacl -m g:agent-core:rwx $AGENT_HOME/api_keys
setfacl -m g:agent-core:rwx /var/log/agent-app
```

| 부분 | 설명 |
|------|------|
| `setfacl -m` | ACL 규칙 추가/수정 |
| `g:그룹명:권한` | 그룹(g)에게 권한 부여 |

📭 **예상 출력:** 없음 (3줄 모두 성공 시 침묵)

---

### 4-4. 확인

```bash
ls -la $AGENT_HOME/
```

| 부분 | 설명 |
|------|------|
| `ls -la` | 숨김 파일 포함 상세 목록 출력 |

✅ **예상 출력:**
```
total 20
drwxr-xr-x  5 agent-admin agent-core   4096 May 14 ...  .
drwxr-x---  3 agent-admin agent-admin  4096 May 14 ...  ..
drwxrwx---+ 2 agent-admin agent-core   4096 May 14 ...  api_keys
drwxr-xr-x  2 agent-admin agent-core   4096 May 14 ...  bin
drwxrwx---+ 2 agent-admin agent-common 4096 May 14 ...  upload_files
```

> 끝에 `+`가 붙은 항목은 ACL이 적용된 것입니다.
> `api_keys`의 그룹이 `agent-core`, `upload_files`의 그룹이 `agent-common`인지 확인하세요.

---

```bash
getfacl $AGENT_HOME/upload_files
```

✅ **예상 출력:**
```
# file: home/agent-admin/agent-app/upload_files
# owner: agent-admin
# group: agent-common
user::rwx
group::rwx
group:agent-common:rwx
mask::rwx
other::---
```

---

## STEP 5 — 환경 변수와 키 파일 설정

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

| 부분 | 설명 |
|------|------|
| `>>` | 파일 끝에 추가 (덮어쓰지 않음) |
| `<< 'EOF'` | 이후 `EOF`가 나올 때까지의 내용을 입력으로 사용 |
| `export` | 환경 변수로 등록. 자식 프로세스에서도 사용 가능 |

📭 **예상 출력:** 없음

**확인:**
```bash
tail -6 /home/agent-admin/.bashrc
```

✅ **예상 출력:**
```
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
export AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key
export AGENT_LOG_DIR=/var/log/agent-app
```

---

### 5-2. 키 파일 생성

```bash
echo 'agent_api_key_test' > /home/agent-admin/agent-app/api_keys/t_secret.key
```

📭 **예상 출력:** 없음

```bash
chown agent-admin:agent-core /home/agent-admin/agent-app/api_keys/t_secret.key
chmod 640 /home/agent-admin/agent-app/api_keys/t_secret.key
```

📭 **예상 출력:** 없음 (2줄 모두)

---

### 5-3. 확인

```bash
cat /home/agent-admin/agent-app/api_keys/t_secret.key
```

✅ **예상 출력:**
```
agent_api_key_test
```

---

```bash
ls -la /home/agent-admin/agent-app/api_keys/
```

✅ **예상 출력:**
```
total 12
drwxrwx---+ 2 agent-admin agent-core  4096 May 14 ...  .
drwxr-xr-x  5 agent-admin agent-core  4096 May 14 ...  ..
-rw-r-----  1 agent-admin agent-core    19 May 14 ...  t_secret.key
```

> `-rw-r-----` = 640. 소유자 읽기+쓰기, 그룹 읽기만, 기타 없음

---

## STEP 6 — agent-app 실행하기

### 6-1. 바이너리 파일을 컨테이너에 복사

> **새 터미널 탭을 열어서 Mac(로컬)에서 실행합니다.**
> 먼저 클론한 저장소 폴더로 이동한 뒤 실행하세요.

```bash
cd ~/Codyssey/B1-1   # 저장소 위치에 맞게 수정
docker cp $(pwd)/agent-app codyssey-b1-1:/home/agent-admin/agent-app/agent-app
```

| 부분 | 설명 |
|------|------|
| `docker cp` | 로컬 ↔ 컨테이너 간 파일 복사 |
| `$(pwd)` | 현재 디렉토리 경로로 자동 치환됨. 경로를 하드코딩하지 않아도 됨 |
| `codyssey-b1-1:/경로` | 컨테이너명:컨테이너내부경로 |

✅ **예상 출력:**
```
Successfully copied 7.93MB to codyssey-b1-1:/home/agent-admin/agent-app/agent-app
```

---

### 6-2. 권한 설정 (컨테이너 터미널로 돌아와서)

```bash
chown agent-admin:agent-core /home/agent-admin/agent-app/agent-app
chmod 750 /home/agent-admin/agent-app/agent-app
```

📭 **예상 출력:** 없음 (2줄 모두)

---

### 6-3. 테스트 실행 (Boot Sequence 확인)

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

| 부분 | 설명 |
|------|------|
| `su - 계정명` | 해당 계정으로 전환 |
| `-c '명령어'` | 그 계정으로 명령어만 실행 후 원래 계정으로 복귀 |

✅ **예상 출력:**
```
>>> Starting Agent Boot Sequence...
[1/5] Checking User Account               [OK]
 ... Running as service user 'agent-admin' (uid=1001)
[2/5] Verifying Environment Variables     [OK]
 ... All required Envs correct
[3/5] Checking Required Files             [OK]
 ... Verified 'secret.key' with correct key string.
[4/5] Checking Port Availability          [OK]
 ... Port 15034 is available.
[5/5] Verifying Log Permission            [OK]
 ... Log directory is writable: /var/log/agent-app
------------------------------------------------------------
All Boot Checks Passed!
Agent READY
```

이후 앱이 계속 실행되며 로그가 출력됩니다. `Ctrl+C`로 종료합니다.

❌ **`[FAIL]`이 나오는 경우:**
```
[1/5] ... [FAIL]  → root로 실행했거나 계정이 잘못됨
[2/5] ... [FAIL]  → 환경 변수 중 하나가 빠짐
[3/5] ... [FAIL]  → t_secret.key 파일이 없거나 내용이 틀림
[4/5] ... [FAIL]  → 15034 포트가 이미 사용 중
[5/5] ... [FAIL]  → /var/log/agent-app 에 쓰기 권한 없음
```

---

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

| 부분 | 설명 |
|------|------|
| `nohup` | 터미널이 닫혀도 프로세스 계속 실행 |
| `> /dev/null` | 출력을 버림 |
| `2>&1` | 에러 출력도 같은 곳으로 |
| `&` | 백그라운드 실행 |
| `$!` | 방금 실행된 프로세스의 PID |

✅ **예상 출력:**
```
PID: 4863
```
> 숫자는 실행할 때마다 달라집니다.

---

### 6-5. 포트 리슨 확인

```bash
ss -tlnp | grep 15034
```

✅ **예상 출력:**
```
tcp  LISTEN  0  1  0.0.0.0:15034  0.0.0.0:*  users:(("agent-app",pid=4863,fd=19))
```

❌ **아무것도 안 나오면:** 앱이 실행되지 않은 것. 6-4 단계 다시 실행

---

## STEP 7 — monitor.sh 직접 작성하기

### 7-1. 파일 생성

```bash
nano /home/agent-admin/agent-app/bin/monitor.sh
```

✅ **예상 화면:** 비어있는 nano 편집기가 열립니다.

아래 내용을 입력하고, 각 줄의 의미를 읽으면서 타이핑하세요.

---

```bash
#!/bin/bash
```
> Shebang. 이 파일을 bash로 실행하라는 선언. 반드시 첫 줄이어야 합니다.

```bash
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
```
> `${변수:-기본값}`: 변수가 없으면 기본값 사용. cron은 .bashrc를 읽지 않아서 필요
> `$(( ))`: 산술 연산. 10MB = 10×1024×1024 바이트

```bash
echo "====== SYSTEM MONITOR RESULT ======"
echo ""
```

```bash
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
```
> `[ ! -f 파일 ]`: 파일이 없으면 (! = NOT, -f = 파일존재)
> `stat -c%s`: 파일 크기(바이트)
> `-ge`: 크거나 같으면 (Greater or Equal)
> `seq 9 -1 1`: 9,8,7...1 순서로 출력

```bash
echo "[HEALTH CHECK]"

PID=$(pgrep -f "$APP_PROCESS" | head -1)
if [ -z "$PID" ]; then
    echo "Checking process '$APP_PROCESS'... [FAIL]"
    exit 1
fi
echo "Checking process '$APP_PROCESS'... [OK] (PID: $PID)"
```
> `pgrep -f`: 프로세스 이름으로 PID 검색
> `[ -z "$변수" ]`: 변수가 비어있으면 참

```bash
if ! ss -tlnp 2>/dev/null | grep -q ":${AGENT_PORT} "; then
    echo "Checking port $AGENT_PORT... [FAIL]"
    exit 1
fi
echo "Checking port $AGENT_PORT... [OK]"
echo ""
```
> `grep -q`: 조용히 검색 (출력 없이 성공/실패만 반환)
> `!`: 결과 반전 (포트 없으면 → 조건 참 → FAIL)

```bash
if command -v ufw &>/dev/null; then
    UFW_STATUS=$(ufw status 2>/dev/null | head -1)
    if echo "$UFW_STATUS" | grep -q "inactive"; then
        echo "[WARNING] Firewall (ufw) is inactive"
    fi
fi
```
> `command -v ufw`: ufw가 설치되어 있는지 확인

```bash
echo "[RESOURCE MONITORING]"

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)
[ -z "$CPU" ] && CPU=$(top -bn1 | grep "%Cpu" | awk '{print $2}' | cut -d. -f1)
```
> `top -bn1`: 배치모드(-b) 1회(-n1) 실행
> `awk '{print $2}'`: 두 번째 컬럼 추출
> `cut -d. -f1`: 점(.) 기준으로 나눠 첫 번째만 (25.3 → 25)

```bash
MEM_INFO=$(free | grep Mem)
MEM_TOTAL=$(echo "$MEM_INFO" | awk '{print $2}')
MEM_USED=$(echo "$MEM_INFO" | awk '{print $3}')
MEM=$(echo "$MEM_USED $MEM_TOTAL" | awk '{printf "%.1f", $1/$2*100}')
MEM_INT=$(echo "$MEM" | cut -d. -f1)
```
> `free | grep Mem`: 메모리 정보 줄 추출
> `printf "%.1f"`: 소수점 1자리로 출력

```bash
DISK=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
```
> `df /`: 루트 파티션 디스크 사용 현황
> `tail -1`: 마지막 줄 (헤더 제외)
> `tr -d '%'`: % 문자 제거

```bash
echo "CPU Usage : ${CPU}%"
echo "MEM Usage : ${MEM}%"
echo "DISK Used  : ${DISK}%"
echo ""

[ "$CPU" -gt "$CPU_THRESHOLD" ] 2>/dev/null && \
    echo "[WARNING] CPU threshold exceeded (${CPU}% > ${CPU_THRESHOLD}%)"
[ "$MEM_INT" -gt "$MEM_THRESHOLD" ] 2>/dev/null && \
    echo "[WARNING] MEM threshold exceeded (${MEM}% > ${MEM_THRESHOLD}%)"
[ "$DISK" -gt "$DISK_THRESHOLD" ] 2>/dev/null && \
    echo "[WARNING] DISK threshold exceeded (${DISK}% > ${DISK_THRESHOLD}%)"
```
> `-gt`: Greater Than. 숫자 비교
> `&&`: 앞이 참이면 뒤 실행

```bash
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] PID:$PID CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK}%" >> "$LOG_FILE"
echo ""
echo "[INFO] Log appended: $LOG_FILE"
echo "======================================"
```
> `>>`: 파일에 추가 (덮어쓰지 않음)
> `date '+%Y-%m-%d %H:%M:%S'`: 현재 시각을 지정된 형식으로

`Ctrl+O` → `Enter`로 저장, `Ctrl+X`로 종료

---

### 7-2. 권한 설정

```bash
chown agent-dev:agent-core /home/agent-admin/agent-app/bin/monitor.sh
chmod 750 /home/agent-admin/agent-app/bin/monitor.sh
```

📭 **예상 출력:** 없음

```bash
ls -la /home/agent-admin/agent-app/bin/monitor.sh
```

✅ **예상 출력:**
```
-rwxr-x--- 1 agent-dev agent-core 3961 May 14 ...  /home/.../monitor.sh
```
> `-rwxr-x---` = 750. 소유자 실행 가능, 그룹 실행 가능, 기타 접근 불가

---

### 7-3. 직접 실행

```bash
su - agent-admin -c '
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_LOG_DIR=/var/log/agent-app
bash /home/agent-admin/agent-app/bin/monitor.sh
'
```

✅ **예상 출력:**
```
====== SYSTEM MONITOR RESULT ======

[HEALTH CHECK]
Checking process 'agent-app'... [OK] (PID: 4863)
Checking port 15034... [OK]

[RESOURCE MONITORING]
CPU Usage : 1%
MEM Usage : 12.0%
DISK Used  : 2%

[WARNING] MEM threshold exceeded (12.0% > 10%)

[INFO] Log appended: /var/log/agent-app/monitor.log
======================================
```

> MEM [WARNING]은 Docker 컨테이너 특성상 정상입니다.

---

### 7-4. 로그 확인

```bash
cat /var/log/agent-app/monitor.log
```

✅ **예상 출력:**
```
[2026-05-14 06:18:56] PID:4863 CPU:1% MEM:12.0% DISK_USED:2%
```

---

## STEP 8 — crontab 등록

### 8-1. cron 서비스 시작

```bash
service cron start
```

✅ **예상 출력:**
```
 * Starting periodic command scheduler cron
   ...done.
```

---

### 8-2. crontab 편집

```bash
su - agent-admin -c 'crontab -e'
```

| 부분 | 설명 |
|------|------|
| `crontab -e` | 현재 계정의 crontab 편집기 열기 |

✅ **예상 화면:** 편집기가 열립니다. 처음 실행 시 편집기 선택 물음이 나올 수 있습니다.
```
no crontab for agent-admin - using an empty one

Select an editor. ...
  1. /bin/nano  <---- easiest
  2. /usr/bin/vim.basic
...
```
> `1`을 입력하고 엔터 (nano 선택)

맨 아래에 다음 줄을 추가합니다:
```
* * * * * AGENT_HOME=/home/agent-admin/agent-app AGENT_PORT=15034 AGENT_LOG_DIR=/var/log/agent-app bash /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/cron.log 2>&1
```

저장 후 종료합니다.

✅ **저장 시 출력:**
```
crontab: installing new crontab
```

---

### 8-3. 등록 확인

```bash
su - agent-admin -c 'crontab -l'
```

✅ **예상 출력:**
```
* * * * * AGENT_HOME=/home/agent-admin/agent-app AGENT_PORT=15034 AGENT_LOG_DIR=/var/log/agent-app bash /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/cron.log 2>&1
```

---

### 8-4. 자동 실행 확인 (1분 대기)

```bash
wc -l /var/log/agent-app/monitor.log
```

✅ **예상 출력:**
```
1 /var/log/agent-app/monitor.log
```

1분 기다린 후 다시 실행합니다.

✅ **1분 후 예상 출력:**
```
2 /var/log/agent-app/monitor.log   ← 숫자가 늘어야 함
```

```bash
tail -5 /var/log/agent-app/monitor.log
```

✅ **예상 출력:**
```
[2026-05-14 06:18:56] PID:4863 CPU:1% MEM:11.7% DISK_USED:2%
[2026-05-14 06:30:01] PID:4863 CPU:1% MEM:12.0% DISK_USED:2%
```

> 타임스탬프가 1분 간격으로 늘어나면 cron이 정상 동작 중입니다.

---

## 최종 점검 체크리스트

```bash
grep -E "^Port|^PermitRootLogin" /etc/ssh/sshd_config
```
✅ `Port 20022` / `PermitRootLogin no`

```bash
ufw status
```
✅ `Status: active` / 20022, 15034만 ALLOW

```bash
id agent-admin && id agent-dev && id agent-test
```
✅ 각 계정의 groups에 올바른 그룹이 포함되어 있는지 확인

```bash
ls -la /home/agent-admin/agent-app/
```
✅ `api_keys` → agent-core, `upload_files` → agent-common, 둘 다 `+` 붙어있는지 확인

```bash
pgrep -f agent-app && ss -tlnp | grep 15034
```
✅ PID 번호 출력 + LISTEN 상태 확인

```bash
ls -la /home/agent-admin/agent-app/bin/monitor.sh
```
✅ `-rwxr-x---` / `agent-dev` / `agent-core`

```bash
su - agent-admin -c 'crontab -l'
```
✅ 등록된 crontab 줄 출력

```bash
tail -5 /var/log/agent-app/monitor.log
```
✅ 1분 간격으로 로그가 누적 중인지 확인

---

## 자주 만나는 오류와 해결법

| 오류 메시지 | 원인 | 해결 |
|------------|------|------|
| `Usage: docker run [OPTION]...` | `\` 뒤에 스페이스 있음 | `\` 바로 뒤 엔터, 또는 한 줄로 입력 |
| `bash: nano: command not found` | nano 미설치 | `apt-get install -y nano` |
| `useradd: group '' does not exist` | groupadd를 먼저 안 함 | `groupadd agent-common && groupadd agent-core` 먼저 실행 |
| `Permission denied` | 권한 부족 | `ls -la`로 권한 확인, `chmod`/`chown` 수정 |
| `GLIBC_2.38 not found` | Ubuntu 버전 낮음 | Ubuntu 24.04 사용 |
| cron 실행 안 됨 | 환경 변수 없음 | crontab 줄에 환경 변수 직접 명시 |
| `ss: command not found` | iproute2 미설치 | `apt install iproute2` |
| UFW 작동 안 됨 | `--privileged` 없음 | 컨테이너 재생성 시 `--privileged` 추가 |
| Boot Sequence `[FAIL]` at 1/5 | root로 실행 | `su - agent-admin -c '...'` 형태로 실행 |
| Boot Sequence `[FAIL]` at 3/5 | 키 파일 내용 오류 | `cat t_secret.key` 로 `agent_api_key_test` 확인 |

---

> **마무리:**
> 오류 메시지를 무시하지 말고, 메시지를 읽고 원인을 파악하는 습관이 중요합니다.
> 막히는 부분이 있으면 Study.md의 관련 챕터를 다시 읽어보세요.
