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

```bash
docker --version
```

| 부분 | 설명 |
|------|------|
| `docker` | Docker CLI 명령어 |
| `--version` | 설치된 버전 출력. `--`로 시작하는 옵션은 긴 이름 형식 |

```bash
docker ps
```

| 부분 | 설명 |
|------|------|
| `docker` | Docker CLI |
| `ps` | Process Status. 현재 **실행 중인** 컨테이너 목록 출력 |

✅ 버전 번호와 빈 컨테이너 목록이 나오면 정상입니다.

---

### 0-2. Ubuntu 24.04 컨테이너 생성

> `\` (백슬래시)는 **줄 이어쓰기** 기호입니다. 긴 명령어를 여러 줄로 보기 좋게 나눌 때 사용합니다.
> `\` 뒤에 **스페이스가 없어야** 합니다. 스페이스가 있으면 오류가 납니다.

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

| 옵션 | 설명 |
|------|------|
| `run` | 새 컨테이너를 만들고 실행하는 서브명령어 |
| `-d` | Detach. 백그라운드로 실행. 없으면 터미널이 컨테이너에 붙잡혀 다른 명령을 못 입력함 |
| `--name codyssey-b1` | 컨테이너에 이름 지정. 없으면 Docker가 랜덤 이름 부여 (`vigorous_einstein` 같은 식) |
| `--hostname agent-server` | 컨테이너 내부에서 보이는 호스트명. `hostname` 명령어로 확인 가능 |
| `--platform linux/amd64` | x86_64 아키텍처로 실행. Apple Silicon(M1/M2) Mac은 ARM이라 x86 바이너리를 그냥 못 돌림 |
| `-p 20022:20022` | 포트 포워딩. `호스트포트:컨테이너포트`. 내 Mac의 20022 → 컨테이너의 20022 |
| `-p 15034:15034` | 동일하게 앱 포트도 포워딩 |
| `--privileged` | 컨테이너에 확장 권한 부여. UFW 방화벽이 커널 기능을 건드리기 때문에 필요 |
| `ubuntu:24.04` | 사용할 이미지. `이미지이름:태그` 형식. 로컬에 없으면 Docker Hub에서 자동 다운로드 |
| `/bin/bash -c "tail -f /dev/null"` | 컨테이너 시작 시 실행할 명령. `tail -f /dev/null`은 아무것도 안 하면서 계속 살아있는 트릭 |

> **`tail -f /dev/null` 이 왜 필요한가?**
> 컨테이너는 실행할 프로세스가 끝나면 자동 종료됩니다. 아무 명령 없이 두면 바로 꺼져버립니다.
> `/dev/null`은 아무것도 없는 빈 파일이고, `tail -f`는 파일을 계속 기다리는 명령이라
> 결과적으로 컨테이너가 꺼지지 않고 계속 살아있게 됩니다.

---

### 0-3. 컨테이너 안으로 들어가기

```bash
docker exec -it codyssey-b1 bash
```

| 부분 | 설명 |
|------|------|
| `exec` | 이미 실행 중인 컨테이너 안에서 명령어 실행 |
| `-i` | Interactive. 표준 입력(키보드)을 컨테이너로 전달 |
| `-t` | TTY. 터미널처럼 보이게 가상 터미널 할당. `-i`와 보통 함께 씀 (`-it`) |
| `codyssey-b1` | 대상 컨테이너 이름 |
| `bash` | 컨테이너 안에서 실행할 명령어. bash 쉘을 열겠다는 뜻 |

> 이제부터 나오는 명령어는 **컨테이너 안(Ubuntu)에서 실행**됩니다.

```bash
whoami
```

현재 로그인된 사용자 이름 출력. `root`가 나와야 합니다.

```bash
cat /etc/os-release | grep VERSION
```

| 부분 | 설명 |
|------|------|
| `cat` | Concatenate. 파일 내용을 출력 |
| `/etc/os-release` | OS 정보가 담긴 파일 |
| `\|` | 파이프(Pipe). 왼쪽 명령어의 출력을 오른쪽 명령어의 입력으로 전달 |
| `grep VERSION` | `VERSION`이 포함된 줄만 필터링해서 출력 |

✅ `Ubuntu 24.04`가 나오면 정상입니다.

---

### 0-4. 필수 패키지 설치

```bash
apt-get update
```

| 부분 | 설명 |
|------|------|
| `apt-get` | Ubuntu/Debian 계열의 패키지 관리자 |
| `update` | 설치 가능한 패키지 목록을 최신으로 갱신. 실제 설치는 안 함 |

> **왜 update를 먼저 하는가?**
> 패키지 목록이 오래됐으면 없는 버전을 찾으려다 오류가 납니다.
> 설치 전에 항상 목록을 먼저 갱신하는 것이 관례입니다.

```bash
apt-get install -y openssh-server sudo acl ufw python3 iproute2 procps cron bc
```

| 부분 | 설명 |
|------|------|
| `install` | 패키지 설치 서브명령어 |
| `-y` | Yes. 설치 중 "계속하시겠습니까?" 확인을 자동으로 yes 처리 |
| `openssh-server` | SSH 서버 데몬(sshd). 원격 접속을 받기 위해 필요 |
| `sudo` | 일반 계정이 관리자 권한으로 명령 실행할 때 사용하는 도구 |
| `acl` | Access Control List. `setfacl`, `getfacl` 명령어 제공 |
| `ufw` | Uncomplicated Firewall. 방화벽 관리 도구 |
| `python3` | Python 3 인터프리터. agent-app이 Python 기반 |
| `iproute2` | `ss`, `ip` 등 네트워크 도구 모음. `ss -tlnp`에 필요 |
| `procps` | `ps`, `pgrep` 등 프로세스 관련 도구 모음 |
| `cron` | 주기적 작업 스케줄러 |
| `bc` | Basic Calculator. 스크립트에서 소수점 계산에 사용 |

---

## STEP 1 — SSH 보안 설정

> **왜?** 기본 22번 포트는 전 세계 해커 봇이 1초에 수백 번 공격합니다.
> 포트를 변경하고 root 직접 로그인을 막는 것이 기본 보안입니다.

### 1-1. SSH 설정 파일 열기

```bash
nano /etc/ssh/sshd_config
```

| 부분 | 설명 |
|------|------|
| `nano` | 터미널 기반 텍스트 편집기. 화면 아래에 단축키 안내가 표시됨 |
| `/etc/ssh/sshd_config` | SSH 서버(sshd)의 설정 파일 경로. `/etc`는 설정 파일들이 모여있는 디렉토리 |

> **nano 주요 단축키:**
> - `Ctrl+W` : 검색
> - `Ctrl+O` : 저장 (Write Out)
> - `Ctrl+X` : 종료 (Exit)

편집기에서 아래 두 줄을 찾아 변경합니다.

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

> **`#` 이 왜 붙어있는가?**
> `#`은 주석(comment) 기호입니다. 줄 앞에 `#`이 있으면 그 줄은 무시됩니다.
> 기본값은 주석 처리되어 있고, 변경하려면 `#`을 제거하고 값을 수정해야 합니다.

| 설정 | 의미 |
|------|------|
| `Port 20022` | SSH가 22 대신 20022번 포트에서 접속 대기 |
| `PermitRootLogin no` | root 계정으로 SSH 직접 로그인 금지 |

---

### 1-2. SSH 서비스 시작

```bash
mkdir -p /run/sshd
```

| 부분 | 설명 |
|------|------|
| `mkdir` | Make Directory. 디렉토리(폴더) 생성 |
| `-p` | Parents. 중간 경로도 없으면 함께 생성. 이미 있어도 오류 없이 무시 |
| `/run/sshd` | sshd가 실행 시 필요로 하는 디렉토리. 없으면 sshd 시작 실패 |

```bash
service ssh start
```

| 부분 | 설명 |
|------|------|
| `service` | Linux 서비스(데몬) 관리 명령어 |
| `ssh` | 관리할 서비스 이름 |
| `start` | 서비스 시작. 다른 옵션: `stop`(중지), `restart`(재시작), `status`(상태확인) |

---

### 1-3. 확인

```bash
grep -E "^Port|^PermitRootLogin" /etc/ssh/sshd_config
```

| 부분 | 설명 |
|------|------|
| `grep` | 파일에서 특정 패턴을 찾아 출력 |
| `-E` | Extended regex. 정규표현식 확장 모드 사용 |
| `"^Port\|^PermitRootLogin"` | 찾을 패턴. `^`는 줄의 시작, `\|`는 OR 조건 |
| `/etc/ssh/sshd_config` | 검색할 파일 |

> `^Port`는 "Port로 시작하는 줄"을 의미합니다. `#Port`처럼 주석 처리된 줄은 `^#`으로 시작하므로 제외됩니다.

```bash
ss -tlnp | grep sshd
```

| 부분 | 설명 |
|------|------|
| `ss` | Socket Statistics. 네트워크 연결 상태 확인 도구 (구 `netstat` 대체) |
| `-t` | TCP 소켓만 표시 |
| `-l` | Listening 상태인 것만 표시 (연결 대기 중인 포트) |
| `-n` | Numeric. IP/포트를 숫자로 표시 (이름 변환 없이) |
| `-p` | Process. 어떤 프로세스가 사용 중인지 함께 표시 |
| `\| grep sshd` | 결과 중 `sshd`가 포함된 줄만 필터링 |

✅ `0.0.0.0:20022`와 `sshd`가 보이면 완료입니다.

---

## STEP 2 — 방화벽(UFW) 설정

> **왜?** 포트를 바꿔도 방화벽이 없으면 다른 포트가 열려 있을 수 있습니다.
> "필요한 포트만 열기" 원칙으로 최소한의 문만 열어둡니다.

### 2-1. 기본 정책 설정

```bash
ufw default deny incoming
```

| 부분 | 설명 |
|------|------|
| `ufw` | Uncomplicated Firewall. UFW 명령어 |
| `default` | 기본 정책 설정 서브명령어 |
| `deny` | 차단 (drop과 달리 거절 응답을 보냄) |
| `incoming` | 외부에서 서버로 **들어오는** 트래픽 |

```bash
ufw default allow outgoing
```

| 부분 | 설명 |
|------|------|
| `allow` | 허용 |
| `outgoing` | 서버에서 외부로 **나가는** 트래픽 |

---

### 2-2. 필요한 포트만 열기

```bash
ufw allow 20022/tcp
```

| 부분 | 설명 |
|------|------|
| `allow` | 해당 포트/프로토콜 허용 규칙 추가 |
| `20022` | 포트 번호 |
| `/tcp` | 프로토콜 지정. TCP는 연결 기반 프로토콜로 SSH, HTTP 등이 사용 |

> **TCP vs UDP:**
> - `TCP` : 데이터 전달 보장. 순서 보장. 느리지만 신뢰성 높음 (SSH, HTTP, 파일 전송)
> - `UDP` : 빠르지만 전달 보장 없음 (DNS, 게임, 스트리밍)
> SSH와 웹 서비스는 항상 TCP를 사용합니다.

```bash
ufw allow 15034/tcp
```

agent-app이 사용하는 15034 포트도 동일하게 허용합니다.

---

### 2-3. 방화벽 활성화

```bash
ufw --force enable
```

| 부분 | 설명 |
|------|------|
| `--force` | "방화벽을 켜면 현재 SSH 연결이 끊길 수 있습니다. 계속하시겠습니까?" 확인을 자동 yes 처리 |
| `enable` | 방화벽 활성화 및 부팅 시 자동 시작 등록 |

---

### 2-4. 확인

```bash
ufw status verbose
```

| 부분 | 설명 |
|------|------|
| `status` | 현재 방화벽 상태와 규칙 목록 출력 |
| `verbose` | 기본 정책(default)까지 상세하게 출력 |

✅ 두 포트만 `ALLOW IN`으로 표시되면 완료입니다.

---

## STEP 3 — 계정과 그룹 만들기

> **왜?** 역할에 따라 계정을 분리하면 실수나 침해 시 피해 범위를 줄일 수 있습니다.

### 3-1. 그룹 먼저 생성

```bash
groupadd agent-common
groupadd agent-core
```

| 부분 | 설명 |
|------|------|
| `groupadd` | 새 그룹 생성 명령어 |
| `agent-common` | 생성할 그룹 이름. 모든 계정(admin/dev/test)이 속할 공용 그룹 |
| `agent-core` | admin, dev만 속할 핵심 그룹. 보안 파일 접근용 |

> **왜 계정보다 그룹을 먼저 만드는가?**
> `useradd -G 그룹명`으로 계정 생성 시 그룹을 지정하는데, 이때 그룹이 이미 존재해야 합니다.

---

### 3-2. 계정 생성

```bash
useradd -m -s /bin/bash -G agent-common,agent-core agent-admin
useradd -m -s /bin/bash -G agent-common,agent-core agent-dev
useradd -m -s /bin/bash -G agent-common agent-test
```

| 옵션 | 설명 |
|------|------|
| `useradd` | 새 계정 생성 명령어 |
| `-m` | Make home. 홈 디렉토리(`/home/계정명`) 자동 생성 |
| `-s /bin/bash` | Shell. 기본 쉘 지정. `/bin/bash`를 지정해야 터미널 로그인 시 bash 사용 가능 |
| `-G` | Groups. 추가 그룹 지정 (기본 그룹 외 추가). 콤마로 여러 개 지정 가능 |
| `agent-admin` | 마지막 인자가 생성할 계정 이름 |

> **기본 그룹 vs 추가 그룹:**
> 계정을 만들면 계정명과 같은 이름의 기본 그룹이 자동 생성됩니다.
> `-G`는 기본 그룹 외에 **추가로** 속할 그룹을 지정합니다.
>
> ```
> agent-admin의 기본 그룹: agent-admin (자동 생성)
> agent-admin의 추가 그룹: agent-common, agent-core (-G로 지정)
> ```

---

### 3-3. sudo 권한 부여

```bash
echo 'agent-admin ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/agent-admin
```

| 부분 | 설명 |
|------|------|
| `echo '...'` | 따옴표 안의 문자열 출력 |
| `>` | 출력을 파일에 **덮어쓰기** (파일이 없으면 생성) |
| `/etc/sudoers.d/agent-admin` | sudo 설정 파일. `/etc/sudoers.d/` 하위 파일은 자동으로 sudo 설정에 포함됨 |

> **`ALL=(ALL) NOPASSWD:ALL` 의미:**
> ```
> agent-admin  ALL=(ALL) NOPASSWD:ALL
>     │         │    │       │      │
>     │         │    │       │      └ 모든 명령어
>     │         │    │       └ 비밀번호 없이
>     │         │    └ 어떤 사용자로도 실행 가능
>     │         └ 어떤 호스트에서도
>     └ 이 계정에게 적용
> ```

```bash
chmod 440 /etc/sudoers.d/agent-admin
```

| 부분 | 설명 |
|------|------|
| `chmod` | Change Mode. 파일 권한 변경 |
| `440` | `r--r-----`. 소유자와 그룹은 읽기만, 기타는 접근 불가 |

> sudo 설정 파일은 보안상 쓰기 권한이 없어야 합니다. 쓰기 권한이 있으면 sudo가 해당 파일을 무시합니다.

---

### 3-4. 확인

```bash
id agent-admin
```

| 부분 | 설명 |
|------|------|
| `id` | 계정의 UID, GID, 소속 그룹 정보 출력 |
| `agent-admin` | 확인할 계정명 |

✅ `groups=...,agent-common,agent-core` 가 보이면 완료입니다.

---

## STEP 4 — 디렉토리 구조와 권한 설정

> **왜?** 공용 디렉토리와 보안 디렉토리를 분리해야 중요한 파일(키, 로그)을
> 일부 인원만 접근할 수 있도록 보호할 수 있습니다.

### 4-1. 디렉토리 생성

```bash
AGENT_HOME=/home/agent-admin/agent-app
```

쉘 변수 선언입니다. 이후 `$AGENT_HOME`으로 이 경로를 참조할 수 있습니다.
> `=` 양쪽에 **스페이스가 없어야** 합니다. `AGENT_HOME = /path` 이렇게 쓰면 오류납니다.

```bash
mkdir -p $AGENT_HOME/upload_files
mkdir -p $AGENT_HOME/api_keys
mkdir -p $AGENT_HOME/bin
mkdir -p /var/log/agent-app
```

| 부분 | 설명 |
|------|------|
| `mkdir` | Make Directory |
| `-p` | 상위 디렉토리가 없으면 함께 생성. 이미 존재해도 오류 없음 |
| `$AGENT_HOME/upload_files` | `$변수명`으로 변수 값을 사용. `/home/agent-admin/agent-app/upload_files`로 치환됨 |
| `/var/log/agent-app` | `/var/log`는 시스템 로그 표준 경로 |

---

### 4-2. 소유자 및 권한 설정

```bash
chown agent-admin:agent-common $AGENT_HOME/upload_files
chmod 770 $AGENT_HOME/upload_files
```

| 부분 | 설명 |
|------|------|
| `chown` | Change Owner. 소유자/그룹 변경 |
| `agent-admin:agent-common` | `소유자:그룹` 형식. 소유자는 agent-admin, 그룹은 agent-common으로 설정 |
| `chmod 770` | 소유자(7=rwx), 그룹(7=rwx), 기타(0=---). 기타 사용자는 접근 불가 |

```bash
chown agent-admin:agent-core $AGENT_HOME/api_keys
chmod 770 $AGENT_HOME/api_keys

chown agent-admin:agent-core /var/log/agent-app
chmod 770 /var/log/agent-app
```

> **권한 숫자 계산법:**
> ```
> r (읽기)  = 4
> w (쓰기)  = 2
> x (실행)  = 1
>
> rwx = 4+2+1 = 7
> rw- = 4+2+0 = 6
> r-- = 4+0+0 = 4
> --- = 0+0+0 = 0
>
> 770 = rwx(소유자) rwx(그룹) ---(기타)
> 750 = rwx(소유자) r-x(그룹) ---(기타)
> 640 = rw-(소유자) r--(그룹) ---(기타)
> ```

---

### 4-3. ACL 설정

```bash
setfacl -m g:agent-common:rwx $AGENT_HOME/upload_files
setfacl -m g:agent-core:rwx $AGENT_HOME/api_keys
setfacl -m g:agent-core:rwx /var/log/agent-app
```

| 부분 | 설명 |
|------|------|
| `setfacl` | Set File ACL. ACL 규칙 설정 |
| `-m` | Modify. ACL 규칙 추가/수정 |
| `g:agent-common:rwx` | `g`=그룹(group), `agent-common`=그룹명, `rwx`=부여할 권한 |

---

### 4-4. 확인

```bash
ls -la $AGENT_HOME/
```

| 부분 | 설명 |
|------|------|
| `ls` | List. 파일/디렉토리 목록 출력 |
| `-l` | Long format. 권한, 소유자, 크기, 날짜 등 상세 정보 표시 |
| `-a` | All. `.`으로 시작하는 숨김 파일도 표시 |

```bash
getfacl $AGENT_HOME/upload_files
```

| 부분 | 설명 |
|------|------|
| `getfacl` | Get File ACL. 파일/디렉토리의 ACL 규칙 출력 |

✅ `drwxrwx---+` 처럼 끝에 `+`가 붙으면 ACL이 적용된 것입니다.

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

| 부분 | 설명 |
|------|------|
| `cat` | 내용을 출력하는 명령어. 여기서는 입력을 파일로 보내는 용도 |
| `>>` | 파일 끝에 **추가** (덮어쓰지 않음). `>`는 덮어쓰기 |
| `/home/agent-admin/.bashrc` | agent-admin 계정의 bash 설정 파일. 로그인 시 자동 실행됨 |
| `<< 'EOF'` | Here Document. 이후 `EOF`가 나올 때까지의 내용을 입력으로 사용 |
| `export` | 변수를 환경 변수로 등록. 하위 프로세스에서도 사용 가능하게 됨 |

> **`export`가 없으면?**
> `AGENT_HOME=/path` 만 쓰면 현재 쉘에서만 유효한 지역 변수입니다.
> `export`를 붙이면 자식 프로세스(앱 실행 등)에서도 이 변수를 읽을 수 있습니다.

---

### 5-2. 키 파일 생성

```bash
echo 'agent_api_key_test' > /home/agent-admin/agent-app/api_keys/t_secret.key
```

| 부분 | 설명 |
|------|------|
| `echo '텍스트'` | 텍스트를 출력. 작은따옴표는 내용을 그대로 출력 (변수 치환 없음) |
| `>` | 출력 결과를 파일에 저장 (파일이 없으면 생성, 있으면 덮어씀) |

```bash
chown agent-admin:agent-core /home/agent-admin/agent-app/api_keys/t_secret.key
chmod 640 /home/agent-admin/agent-app/api_keys/t_secret.key
```

`640` = `rw-r-----`:
- 소유자(agent-admin): 읽기+쓰기
- 그룹(agent-core): 읽기만
- 기타: 접근 불가

---

### 5-3. 확인

```bash
cat /home/agent-admin/agent-app/api_keys/t_secret.key
```

파일 내용을 터미널에 출력합니다. `agent_api_key_test`가 나와야 합니다.

```bash
ls -la /home/agent-admin/agent-app/api_keys/
```

`-rw-r-----` 권한과 `agent-admin agent-core` 소유 정보가 맞는지 확인합니다.

---

## STEP 6 — agent-app 실행하기

> **왜?** 앱이 5가지 Boot Check를 모두 통과해야 monitor.sh가 감시할 대상이 생깁니다.

### 6-1. 바이너리 파일을 컨테이너에 복사

> **새 터미널 탭을 열어서 Mac(로컬)에서 실행합니다.**

```bash
docker cp /Users/jonghan/Codyssey/B1-1/agent-app codyssey-b1:/home/agent-admin/agent-app/agent-app
```

| 부분 | 설명 |
|------|------|
| `docker cp` | 로컬 ↔ 컨테이너 간 파일 복사 |
| `/Users/.../agent-app` | 복사할 원본 파일 (Mac 로컬 경로) |
| `codyssey-b1:` | 대상 컨테이너 이름. 콜론(`:`) 뒤에 컨테이너 내부 경로 |
| `/home/.../agent-app` | 컨테이너 내부의 저장 경로와 파일명 |

---

### 6-2. 권한 설정 (컨테이너 터미널에서)

```bash
chown agent-admin:agent-core /home/agent-admin/agent-app/agent-app
chmod 750 /home/agent-admin/agent-app/agent-app
```

`750` = `rwxr-x---`:
- 소유자(agent-admin): 읽기+쓰기+실행
- 그룹(agent-core): 읽기+실행
- 기타: 접근 불가

> 실행 파일이므로 `x(실행)` 권한이 있어야 합니다.

---

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

| 부분 | 설명 |
|------|------|
| `su` | Switch User. 다른 계정으로 전환 |
| `-` | 로그인 쉘로 전환. 해당 계정의 환경 변수와 홈 디렉토리 적용 |
| `agent-admin` | 전환할 계정명 |
| `-c '명령어'` | 그 계정으로 따옴표 안의 명령어만 실행하고 다시 원래 계정으로 돌아옴 |

> **왜 agent-admin으로 실행하는가?**
> Boot Sequence 1단계에서 앱이 실행 계정을 확인합니다.
> root로 실행하면 `[1/5] Checking User Account [FAIL]`이 납니다.

---

### 6-4. 백그라운드로 실행

```bash
su - agent-admin -c '
export AGENT_HOME=/home/agent-admin/agent-app
...
nohup $AGENT_HOME/agent-app > /dev/null 2>&1 &
echo "PID: $!"
'
```

| 부분 | 설명 |
|------|------|
| `nohup` | No Hangup. 터미널이 닫혀도(SIGHUP 신호) 프로세스가 계속 실행되도록 함 |
| `> /dev/null` | 표준 출력(stdout)을 `/dev/null`(쓰레기통)로 버림 |
| `2>&1` | 표준 에러(stderr, 2번)를 표준 출력(stdout, 1번)과 같은 곳으로 보냄. 즉, 에러도 버림 |
| `&` | 백그라운드 실행. 명령어 뒤에 `&`를 붙이면 바로 프롬프트가 돌아옴 |
| `$!` | 방금 백그라운드로 실행된 프로세스의 PID |

---

### 6-5. 포트 리슨 확인

```bash
ss -tlnp | grep 15034
```

`LISTEN` 상태에서 `0.0.0.0:15034`와 `agent-app`이 보이면 정상입니다.

---

## STEP 7 — monitor.sh 직접 작성하기

> **왜?** 이것이 이번 미션의 핵심입니다. 직접 타이핑하면서 각 줄의 역할을 이해합니다.

### 7-1. 파일 생성

```bash
nano /home/agent-admin/agent-app/bin/monitor.sh
```

---

### 7-2. 스크립트 내용 입력

아래 내용을 입력합니다. 각 줄 옆의 설명을 읽으면서 타이핑하세요.

```bash
#!/bin/bash
```
> **Shebang(샤뱅)**. 이 파일을 어떤 인터프리터로 실행할지 지정합니다.
> `#!`로 시작하며, `/bin/bash`로 실행하라는 의미입니다. 반드시 첫 줄이어야 합니다.

```bash
AGENT_HOME=${AGENT_HOME:-/home/agent-admin/agent-app}
AGENT_PORT=${AGENT_PORT:-15034}
AGENT_LOG_DIR=${AGENT_LOG_DIR:-/var/log/agent-app}
```

> **`${변수:-기본값}` 문법:**
> 변수가 설정되어 있으면 그 값을 사용하고, 없으면 기본값을 사용합니다.
> cron은 환경 변수를 읽지 못할 수 있어서 기본값을 지정해 두는 것입니다.

```bash
MAX_LOG_SIZE=$((10 * 1024 * 1024))
```

> **`$(( ))` 문법:** 산술 연산. `10 * 1024 * 1024 = 10,485,760` (10MB를 바이트로 표현)

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
```

| 부분 | 설명 |
|------|------|
| `함수명() { }` | 함수 정의 |
| `[ ! -f "$파일" ]` | 파일이 **없으면** (! = NOT, -f = 파일 존재 여부) |
| `&& return` | 앞 조건이 참이면 함수 종료 |
| `local size` | 함수 내에서만 유효한 지역 변수 선언 |
| `stat -c%s 파일` | 파일 크기를 바이트 단위로 출력 |
| `2>/dev/null` | 에러 메시지를 버림 |
| `\|\| echo 0` | 앞 명령이 실패하면 `0` 출력 (파일 없을 때 대비) |
| `-ge` | Greater than or Equal. 크거나 같으면 |
| `seq 9 -1 1` | 9부터 1씩 감소하며 1까지: `9 8 7 6 5 4 3 2 1` |

```bash
PID=$(pgrep -f "$APP_PROCESS" | head -1)
```

| 부분 | 설명 |
|------|------|
| `$(명령어)` | 명령어 치환. 명령어 실행 결과를 변수에 저장 |
| `pgrep` | Process Grep. 프로세스 이름으로 PID 검색 |
| `-f` | Full. 실행 명령어 전체에서 검색 (프로세스 이름만이 아니라) |
| `\| head -1` | 결과 중 첫 번째 줄만 가져옴 (동일 이름 프로세스가 여러 개일 때 대비) |

```bash
if [ -z "$PID" ]; then
```

| 부분 | 설명 |
|------|------|
| `[ -z "$변수" ]` | Zero. 변수가 빈 문자열이면 참 |

```bash
if ! ss -tlnp 2>/dev/null | grep -q ":${AGENT_PORT} "; then
```

| 부분 | 설명 |
|------|------|
| `!` | 뒤 명령어의 결과를 반전. 성공→실패, 실패→성공 |
| `grep -q` | Quiet. 결과를 출력하지 않고 찾으면 종료코드 0(성공), 없으면 1(실패) |
| `":${AGENT_PORT} "` | 포트 번호 뒤에 공백을 붙여서 정확히 15034만 매칭 (150340 같은 숫자 오매칭 방지) |

```bash
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)
```

| 부분 | 설명 |
|------|------|
| `top -bn1` | `-b` Batch 모드(스크립트용), `-n1` 1회만 실행 |
| `grep "Cpu(s)"` | CPU 정보가 있는 줄만 추출 |
| `awk '{print $2}'` | 공백으로 나뉜 두 번째 필드 출력. `top` 출력에서 CPU 사용률 위치 |
| `cut -d. -f1` | `-d.` 점(.)을 구분자로, `-f1` 첫 번째 필드. `25.3` → `25` |

```bash
MEM=$(echo "$MEM_USED $MEM_TOTAL" | awk '{printf "%.1f", $1/$2*100}')
```

| 부분 | 설명 |
|------|------|
| `printf "%.1f"` | 소수점 1자리로 형식화해서 출력 |
| `$1/$2*100` | (사용량 / 전체) × 100 = 사용률(%) |

```bash
DISK=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
```

| 부분 | 설명 |
|------|------|
| `df /` | Disk Free. 루트(/) 파티션 디스크 사용 현황 |
| `tail -1` | 마지막 줄만. `df` 출력의 첫 줄은 헤더라 제외 |
| `awk '{print $5}'` | 5번째 필드. `df` 출력에서 사용률(Use%) 위치 |
| `tr -d '%'` | Translate. `%` 문자 삭제. `23%` → `23` |

```bash
echo "[$TIMESTAMP] PID:$PID CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK}%" >> "$LOG_FILE"
```

| 부분 | 설명 |
|------|------|
| `>>` | 파일에 **추가** (덮어쓰지 않음) |
| `${변수}%` | 중괄호로 감싸면 변수명과 뒤 문자가 구분됨. `$CPU%`는 `CPU%`라는 변수로 오인될 수 있음 |

---

### 7-3. 권한 설정

```bash
chown agent-dev:agent-core /home/agent-admin/agent-app/bin/monitor.sh
chmod 750 /home/agent-admin/agent-app/bin/monitor.sh
```

`750` = `rwxr-x---`:
- `agent-dev` (소유자): 읽기+쓰기+실행
- `agent-core` (그룹): 읽기+실행 (agent-admin이 core 소속이므로 실행 가능)
- 기타: 접근 불가

---

### 7-4. 직접 실행해보기

```bash
su - agent-admin -c '
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_LOG_DIR=/var/log/agent-app
bash /home/agent-admin/agent-app/bin/monitor.sh
'
```

> `bash 스크립트경로` : 스크립트를 bash로 실행. 실행 권한(x)이 없어도 실행 가능

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

| 부분 | 설명 |
|------|------|
| `crontab` | cron 스케줄 관리 명령어 |
| `-e` | Edit. 현재 계정의 crontab을 편집기로 열기 |
| `-l` | List. 등록된 crontab 목록 출력 (확인용) |
| `-r` | Remove. crontab 전체 삭제 (주의!) |

편집기가 열리면 맨 아래에 추가합니다:

```
* * * * * AGENT_HOME=/home/agent-admin/agent-app AGENT_PORT=15034 AGENT_LOG_DIR=/var/log/agent-app bash /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/cron.log 2>&1
```

| 부분 | 설명 |
|------|------|
| `* * * * *` | 분 시 일 월 요일. 모두 `*`이면 "매분" 실행 |
| `KEY=값` | crontab 줄에서 환경 변수 직접 지정. cron은 .bashrc를 읽지 않아서 필요 |
| `>> cron.log` | cron 실행 결과를 로그에 누적 저장 |
| `2>&1` | 에러도 같은 로그 파일에 저장 |

---

### 8-3. 등록 확인

```bash
su - agent-admin -c 'crontab -l'
```

### 8-4. 로그 자동 누적 확인

```bash
wc -l /var/log/agent-app/monitor.log
```

| 부분 | 설명 |
|------|------|
| `wc` | Word Count |
| `-l` | Line count. 줄 수만 출력 |

1분 기다렸다가 다시 실행해서 숫자가 늘어나면 자동 실행 중입니다.

```bash
tail -5 /var/log/agent-app/monitor.log
```

| 부분 | 설명 |
|------|------|
| `tail` | 파일의 마지막 부분 출력 |
| `-5` | 마지막 5줄 출력 (기본값은 10줄) |
| `-f` | Follow. 파일에 내용이 추가될 때마다 실시간으로 출력 (로그 모니터링에 유용) |

✅ 1분마다 새 줄이 추가되면 완료입니다!

---

## 최종 점검 체크리스트

```bash
# 1. SSH 포트와 root 차단
grep -E "^Port|^PermitRootLogin" /etc/ssh/sshd_config

# 2. 방화벽 상태
ufw status

# 3. 계정 그룹 확인
id agent-admin && id agent-dev && id agent-test
```

> `&&` : 앞 명령이 성공했을 때만 다음 명령 실행

```bash
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
| `Usage: docker run [OPTION]...` | `\` 뒤에 스페이스 있음 | `\` 바로 뒤에 엔터. 또는 한 줄로 입력 |
| `Permission denied` | 권한 부족 | `ls -la`로 권한 확인 후 `chmod`/`chown` 수정 |
| `pgrep: command not found` | procps 미설치 | `apt install procps` |
| `GLIBC_2.38 not found` | Ubuntu 버전 낮음 | Ubuntu 24.04 사용 |
| cron 실행 안 됨 | 환경 변수 없음 | crontab 줄에 환경 변수 직접 명시 |
| `ss: command not found` | iproute2 미설치 | `apt install iproute2` |
| UFW 작동 안 됨 | `--privileged` 없음 | 컨테이너 재생성 시 `--privileged` 추가 |
| `AGENT_HOME: unbound variable` | 변수 미설정 | `export AGENT_HOME=...` 먼저 실행 |
| `No such file or directory` | 경로 오타 또는 디렉토리 미생성 | `ls` 로 경로 존재 확인, `mkdir -p` 로 생성 |

---

> **마무리:**
> 오류 메시지를 무시하지 말고, 메시지를 읽고 원인을 파악하는 습관이 중요합니다.
> 막히는 부분이 있으면 Study.md의 관련 챕터를 다시 읽어보세요.
