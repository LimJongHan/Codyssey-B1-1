#!/bin/bash

AGENT_LOG_DIR=${AGENT_LOG_DIR:-/var/log/agent-app}
LOG_FILE="$AGENT_LOG_DIR/monitor.log"

usage() {
    echo "Usage: $0 [-s 'YYYY-MM-DD HH:MM:SS'] [-e 'YYYY-MM-DD HH:MM:SS']"
    echo "  -s  시작 시간 (생략 시 전체)"
    echo "  -e  종료 시간 (생략 시 전체)"
    exit 1
}

START_TIME=""
END_TIME=""

while getopts "s:e:h" opt; do
    case $opt in
        s) START_TIME="$OPTARG" ;;
        e) END_TIME="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# ── 사전 검증 ────────────────────────────────────────────────────
if [ ! -f "$LOG_FILE" ]; then
    echo "[ERROR] Log file not found: $LOG_FILE"
    exit 1
fi

if [ ! -r "$LOG_FILE" ]; then
    echo "[ERROR] Permission denied: $LOG_FILE"
    exit 1
fi

# ── 구간 필터링 ──────────────────────────────────────────────────
FILTERED=$(awk -v start="$START_TIME" -v end="$END_TIME" '
/^\[/ {
    # 타임스탬프 추출: [YYYY-MM-DD HH:MM:SS]
    ts = substr($0, 2, 19)
    if (start != "" && ts < start) next
    if (end   != "" && ts > end)   next
    print
}
' "$LOG_FILE")

if [ -z "$FILTERED" ]; then
    echo "[WARNING] 해당 구간에 로그 데이터가 없습니다."
    [ -n "$START_TIME" ] && echo "  시작: $START_TIME"
    [ -n "$END_TIME"   ] && echo "  종료: $END_TIME"
    exit 0
fi

# ── 통계 계산 ────────────────────────────────────────────────────
calc_stats() {
    local field="$1"    # CPU / MEM / DISK_USED
    local unit="$2"     # % 등

    echo "$FILTERED" | awk -v field="$field" -v unit="$unit" '
    {
        for (i=1; i<=NF; i++) {
            if ($i ~ field":") {
                val = $i
                sub(field":", "", val)
                gsub(unit, "", val)
                values[NR] = val+0
                ts = substr($0, 2, 19)
                timestamps[NR] = ts
                sum += val+0
                count++
                if (count == 1 || val+0 > max_val) { max_val = val+0; max_ts = ts }
                if (count == 1 || val+0 < min_val) { min_val = val+0; min_ts = ts }
            }
        }
    }
    END {
        if (count == 0) exit
        printf "    Average : %.1f%s\n", sum/count, unit
        printf "    Maximum : %.1f%s at %s\n", max_val, unit, max_ts
        printf "    Minimum : %.1f%s at %s\n", min_val, unit, min_ts
        printf "    _count=%d\n", count
    }
    '
}

# ── 출력 ─────────────────────────────────────────────────────────
echo "====== STATISTICS REPORT ======"
[ -n "$START_TIME" ] && echo "  From : $START_TIME"
[ -n "$END_TIME"   ] && echo "  To   : $END_TIME"
echo ""

echo "  [CPU]"
CPU_STATS=$(calc_stats "CPU" "%")
echo "$CPU_STATS" | grep -v "_count="

echo "  [Memory]"
calc_stats "MEM" "%" | grep -v "_count="

echo "  [Disk]"
calc_stats "DISK_USED" "%" | grep -v "_count="

SAMPLE_COUNT=$(echo "$FILTERED" | grep -c "^\[")
echo "  [Samples]"
echo "    Data Points: $SAMPLE_COUNT samples"
echo ""
echo "=============================="
