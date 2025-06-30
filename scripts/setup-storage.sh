#!/bin/bash

# 🗄️  NAS Storage Setup Script (Revised)
# - Formats and mounts a large disk (default: /dev/sda)
# - Prepares two top-level folders: storage (WebDAV/Nextcloud) and smb (SMB share)
# - Creates project-local symlinks: nas/storage and nas/smb
#
#   ⚠️  데이터가 삭제됩니다. 실행 전 반드시 백업하세요!

set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────
# 🎨 컬러 및 로깅 헬퍼
# ─────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log()      { echo -e "${BLUE}ℹ️  INFO${NC} | $1"; }
log_ok()   { echo -e "${GREEN}✅ SUCCESS${NC} | $1"; }
log_warn() { echo -e "${YELLOW}⚠️  WARNING${NC} | $1"; }
log_err()  { echo -e "${RED}❌ ERROR${NC} | $1"; }
step()     { echo -e "${PURPLE}🚀 STEP${NC} | $1"; }

# ─────────────────────────────────────────────────────────────
# 설정값
# ─────────────────────────────────────────────────────────────
DISK_DEVICE=${DISK_DEVICE:-/dev/sda}
MOUNT_POINT=/mnt/nas-storage
PROJECT_ROOT=/srv/personal-infra

# ─────────────────────────────────────────────────────────────
# 디스크 확인 & 사용자 확인
# ─────────────────────────────────────────────────────────────
check_disk() {
  step "디스크 정보 확인 중..."
  lsblk
  echo -e "\n${YELLOW}⚠️  ${DISK_DEVICE} 를 포맷합니다. 기존 데이터가 모두 삭제됩니다!${NC}"
  read -rp "계속하시겠습니까? (y/N): " ans
  [[ ${ans,,} == y ]] || { log "작업 취소"; exit 0; }
}

# ─────────────────────────────────────────────────────────────
format_disk() {
  step "디스크 포맷 시작..."

  # 레이지 언마운트 & 시그니처 삭제
  umount -l ${DISK_DEVICE}?* 2>/dev/null || true
  wipefs -a "$DISK_DEVICE"

  # GPT + 단일 파티션
  parted "$DISK_DEVICE" --script mklabel gpt
  parted "$DISK_DEVICE" --script mkpart primary ext4 0% 100%

  partprobe "$DISK_DEVICE" || true

  mkfs.ext4 -F ${DISK_DEVICE}1
  e2label ${DISK_DEVICE}1 NAS_Storage
  log_ok "디스크 포맷 완료"
}

# ─────────────────────────────────────────────────────────────
setup_mount() {
  step "마운트 설정 중..."
  mkdir -p "$MOUNT_POINT"
  mount ${DISK_DEVICE}1 "$MOUNT_POINT" || true

  # fstab 등록
  uuid=$(blkid -s UUID -o value ${DISK_DEVICE}1)
  grep -q "$uuid" /etc/fstab || echo "UUID=$uuid $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
  mount -a
  log_ok "마운트 완료: $MOUNT_POINT"
}

# ─────────────────────────────────────────────────────────────
create_directories() {
  step "디렉토리 구조 생성 중..."
  for dir in "$MOUNT_POINT/storage" "$MOUNT_POINT/smb"; do
    mkdir -p "$dir"
    chmod 755 "$dir"
    log "디렉토리 생성: $dir"
  done

  # 프로젝트 내 심볼릭 링크
  if [[ -d "$PROJECT_ROOT" ]]; then
    cd "$PROJECT_ROOT"
    mkdir -p nas
    for sub in storage smb; do
      [[ -L "nas/$sub" ]] && continue
      ln -sf "$MOUNT_POINT/$sub" "nas/$sub"
      log "링크: nas/$sub -> $MOUNT_POINT/$sub"
    done
  fi
  log_ok "디렉토리/링크 준비 완료"
}

# ─────────────────────────────────────────────────────────────
create_test_files() {
  step "README 파일 생성 중..."
  cat > "$MOUNT_POINT/storage/README.md" <<'EOF'
# 🗄️ Storage (WebDAV/Nextcloud)
Nextcloud 외부 저장소로 마운트되는 메인 스토리지 디렉토리입니다.
하위 폴더(photos, videos 등)를 자유롭게 생성·사용하세요.
EOF

  cat > "$MOUNT_POINT/smb/README.md" <<'EOF'
# 📁 SMB Share
SMB/CIFS로 공유되는 디렉토리입니다.
EOF
  log_ok "README 작성 완료"
}

# ─────────────────────────────────────────────────────────────
status() {
  step "상태 확인..."
  df -h "$MOUNT_POINT" | tail -n +1
  echo "\n[MOUNT TREE]" && ls -al "$MOUNT_POINT"
  echo "\n[PROJECT LINKS]" && ls -al "$PROJECT_ROOT/nas"
}

# ─────────────────────────────────────────────────────────────
main() {
  case "${1:-}" in
    --format)
      check_disk
      format_disk
      setup_mount
      create_directories
      create_test_files
      ;;
    --mount-only)
      setup_mount
      create_directories
      ;;
    --directories-only)
      create_directories
      ;;
    --status)
      status
      ;;
    *)
      echo "사용법: $0 [--format | --mount-only | --directories-only | --status]" && exit 1
      ;;
  esac
}

# 루트 권한 체크
[[ $EUID -eq 0 ]] || { log_err "루트 권한이 필요합니다"; exit 1; }

main "$@" 