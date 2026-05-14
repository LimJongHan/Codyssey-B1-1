#!/bin/bash

AGENT_HOME=${AGENT_HOME:-/home/agent-admin/agent-app}
AGENT_PORT=${AGENT_PORT:-15034}
AGENT_LOG_DIR=${AGENT_LOG_DIR:-/var/log/agent-app}
LOG_FILE="$AGENT_LOG_DIR/monitor.log"
APP_PROCESS="agent-app"
MAX_LOG_SIZE=$((10 * 1024 * 1024))  # 10MB
MAX_LOG_COUNT=10

CPU_THRESHOLD=20
MEM_THRESHOLD=10
DISK_THRESHOLD=80

echo "====== SYSTEM MONITOR RESULT ======"
echo ""

# ── 로그 용량 관리 ──────────────────────────────────────────────
rotate_log() {
    [ ! -f "$LOG_FILE" ] && return
    local size
    size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
    if [ "$size" -ge "$MAX_LOG_SIZE" ]; then
        for i in $(seq $((MAX_LOG_COUNT - 1)) -1 1); do
            [ -f "${LOG_FILE}.$i" ] && mv "${LOG_FILE}.$i" "${LOG_FILE}.$((i+1))"
        done
        mv "$LOG_FILE" "${LOG_FILE}.1"
        # MAX_LOG_COUNT 초과 파일 삭제
        local idx=$((MAX_LOG_COUNT + 1))
        while [ -f "${LOG_FILE}.$idx" ]; do
            rm -f "${LOG_FILE}.$idx"
            idx=$((idx + 1))
        done
    fi
}

rotate_log

# ── Health Check ────────────────────────────────────────────────
echo "[HEALTH CHECK]"

PID=$(pgrep -f "$APP_PROCESS" | head -1)
if [ -z "$PID" ]; then
    echo "Checking process '$APP_PROCESS'... [FAIL] Process not running"
    exit 1
fi
echo "Checking process '$APP_PROCESS'... [OK] (PID: $PID)"

if ! ss -tlnp 2>/dev/null | grep -q ":${AGENT_PORT} "; then
    echo "Checking port $AGENT_PORT... [FAIL] Not listening"
    exit 1
fi
echo "Checking port $AGENT_PORT... [OK]"
echo ""

# ── 방화벽 상태 점검 ────────────────────────────────────────────
if command -v ufw &>/dev/null; then
    UFW_STATUS=$(ufw status 2>/dev/null | head -1)
    if echo "$UFW_STATUS" | grep -q "inactive"; then
        echo "[WARNING] Firewall (ufw) is inactive"
    fi
elif command -v firewall-cmd &>/dev/null; then
    if ! firewall-cmd --state &>/dev/null | grep -q "running"; then
        echo "[WARNING] Firewall (firewalld) is inactive"
    fi
fi

# ── 자원 수집 ────────────────────────────────────────────────────
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

# ── 임계값 경고 ──────────────────────────────────────────────────
[ "$CPU" -gt "$CPU_THRESHOLD" ] 2>/dev/null && \
    echo "[WARNING] CPU threshold exceeded (${CPU}% > ${CPU_THRESHOLD}%)"

[ "$MEM_INT" -gt "$MEM_THRESHOLD" ] 2>/dev/null && \
    echo "[WARNING] MEM threshold exceeded (${MEM}% > ${MEM_THRESHOLD}%)"

[ "$DISK" -gt "$DISK_THRESHOLD" ] 2>/dev/null && \
    echo "[WARNING] DISK threshold exceeded (${DISK}% > ${DISK_THRESHOLD}%)"

# ── 로그 기록 ────────────────────────────────────────────────────
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] PID:$PID CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK}%" >> "$LOG_FILE"
echo ""
echo "[INFO] Log appended: $LOG_FILE"
echo "======================================"
