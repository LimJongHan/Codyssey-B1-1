#!/bin/bash

AGENT_LOG_DIR=${AGENT_LOG_DIR:-/var/log/agent-app}
ARCHIVE_DIR="/var/log/monitor/agent-app/archive"
COMPRESS_DAYS=7
DELETE_DAYS=30

log_info()    { echo "[INFO]    $*"; }
log_warn()    { echo "[WARNING] $*"; }
log_error()   { echo "[ERROR]   $*"; }

# ── 아카이브 디렉토리 준비 ───────────────────────────────────────
if [ ! -d "$ARCHIVE_DIR" ]; then
    mkdir -p "$ARCHIVE_DIR" 2>/dev/null || {
        log_error "아카이브 디렉토리 생성 실패: $ARCHIVE_DIR (권한 부족)"
        exit 1
    }
    log_info "아카이브 디렉토리 생성: $ARCHIVE_DIR"
fi

if [ ! -w "$ARCHIVE_DIR" ]; then
    log_error "아카이브 디렉토리에 쓰기 권한 없음: $ARCHIVE_DIR"
    exit 1
fi

# ── 소스 디렉토리 확인 ───────────────────────────────────────────
if [ ! -d "$AGENT_LOG_DIR" ]; then
    log_error "로그 디렉토리가 존재하지 않음: $AGENT_LOG_DIR"
    exit 1
fi

echo "====== LOG ARCHIVE PROCESS ======"
echo ""

# ── Step 1: 7일 경과 .log 파일 압축 후 아카이브로 이동 ───────────
log_info "Step 1: ${COMPRESS_DAYS}일 경과 로그 파일 압축 및 아카이브 이동"

COMPRESS_COUNT=0
COMPRESS_FAIL=0

while IFS= read -r -d '' filepath; do
    filename=$(basename "$filepath")

    if [ ! -r "$filepath" ]; then
        log_warn "읽기 권한 없음, 건너뜀: $filepath"
        COMPRESS_FAIL=$((COMPRESS_FAIL + 1))
        continue
    fi

    gz_name="${filename}.gz"
    gz_path="$ARCHIVE_DIR/$gz_name"

    if [ -f "$gz_path" ]; then
        log_warn "이미 아카이브에 존재, 건너뜀: $gz_name"
        continue
    fi

    if gzip -c "$filepath" > "$gz_path" 2>/dev/null; then
        rm -f "$filepath"
        log_info "압축 완료: $filename → $gz_path"
        COMPRESS_COUNT=$((COMPRESS_COUNT + 1))
    else
        rm -f "$gz_path"
        log_warn "압축 실패: $filepath"
        COMPRESS_FAIL=$((COMPRESS_FAIL + 1))
    fi
done < <(find "$AGENT_LOG_DIR" -maxdepth 1 -name "*.log" -mtime +${COMPRESS_DAYS} -print0 2>/dev/null)

if [ "$COMPRESS_COUNT" -eq 0 ] && [ "$COMPRESS_FAIL" -eq 0 ]; then
    log_info "${COMPRESS_DAYS}일 경과 로그 파일 없음 (건너뜀)"
else
    log_info "압축 완료: ${COMPRESS_COUNT}개 / 실패: ${COMPRESS_FAIL}개"
fi

echo ""

# ── Step 2: 30일 경과 아카이브 .gz 삭제 ─────────────────────────
log_info "Step 2: ${DELETE_DAYS}일 경과 아카이브 파일 삭제"

DELETE_COUNT=0
DELETE_FAIL=0

while IFS= read -r -d '' filepath; do
    if [ ! -w "$filepath" ]; then
        log_warn "삭제 권한 없음, 건너뜀: $filepath"
        DELETE_FAIL=$((DELETE_FAIL + 1))
        continue
    fi

    if rm -f "$filepath" 2>/dev/null; then
        log_info "삭제 완료: $(basename "$filepath")"
        DELETE_COUNT=$((DELETE_COUNT + 1))
    else
        log_warn "삭제 실패: $filepath"
        DELETE_FAIL=$((DELETE_FAIL + 1))
    fi
done < <(find "$ARCHIVE_DIR" -maxdepth 1 -name "*.gz" -mtime +${DELETE_DAYS} -print0 2>/dev/null)

if [ "$DELETE_COUNT" -eq 0 ] && [ "$DELETE_FAIL" -eq 0 ]; then
    log_info "${DELETE_DAYS}일 경과 아카이브 파일 없음 (건너뜀)"
else
    log_info "삭제 완료: ${DELETE_COUNT}개 / 실패: ${DELETE_FAIL}개"
fi

echo ""
log_info "아카이브 처리 완료"
echo "=================================="
