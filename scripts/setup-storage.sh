#!/bin/bash

# 🗄️ NAS Storage Setup Script
# 10.9TB WD Elements 디스크 포맷 및 마운트 설정

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  INFO${NC} | $1"
}

log_success() {
    echo -e "${GREEN}✅ SUCCESS${NC} | $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARNING${NC} | $1"
}

log_error() {
    echo -e "${RED}❌ ERROR${NC} | $1"
}

log_step() {
    echo -e "${PURPLE}🚀 STEP${NC} | $1"
}

# 디스크 정보 확인
check_disk() {
    log_step "디스크 정보 확인 중..."
    
    echo -e "\n${BLUE}📀 현재 디스크 상태:${NC}"
    lsblk
    
    echo -e "\n${YELLOW}⚠️  주의: /dev/sda (10.9TB)를 포맷할 예정입니다.${NC}"
    echo -e "${YELLOW}   기존 데이터가 모두 삭제됩니다!${NC}"
    
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "작업이 취소되었습니다."
        exit 0
    fi
}

# 디스크 포맷
format_disk() {
    log_step "디스크 포맷 시작..."
    
    # 기존 마운트 해제
    log_info "기존 마운트 해제 중..."
    umount /dev/sda1 2>/dev/null || true
    umount /dev/sda2 2>/dev/null || true
    
    # 파티션 테이블 생성
    log_info "GPT 파티션 테이블 생성 중..."
    parted /dev/sda --script mklabel gpt
    
    # 전체 디스크를 하나의 파티션으로 생성
    log_info "파티션 생성 중..."
    parted /dev/sda --script mkpart primary ext4 0% 100%
    
    # ext4 파일시스템으로 포맷
    log_info "ext4 파일시스템으로 포맷 중... (시간이 걸릴 수 있습니다)"
    mkfs.ext4 -F /dev/sda1
    
    # 파일시스템 라벨 설정
    log_info "파일시스템 라벨 설정 중..."
    e2label /dev/sda1 "NAS_Storage"
    
    log_success "디스크 포맷 완료"
}

# 마운트 설정
setup_mount() {
    log_step "마운트 설정 중..."
    
    # 마운트 포인트 생성
    mkdir -p /mnt/nas-storage
    
    # 임시 마운트
    log_info "임시 마운트 중..."
    mount /dev/sda1 /mnt/nas-storage
    
    # 소유권 및 권한 설정
    log_info "권한 설정 중..."
    chown -R root:root /mnt/nas-storage
    chmod 755 /mnt/nas-storage
    
    # UUID 확인
    local uuid=$(blkid -s UUID -o value /dev/sda1)
    log_info "디스크 UUID: $uuid"
    
    # fstab 백업
    cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)
    
    # fstab에 영구 마운트 추가
    log_info "fstab에 영구 마운트 설정 추가 중..."
    echo "UUID=$uuid /mnt/nas-storage ext4 defaults,nofail 0 2" >> /etc/fstab
    
    # fstab 테스트
    log_info "fstab 설정 테스트 중..."
    mount -a
    
    log_success "마운트 설정 완료"
}

# 디렉토리 구조 생성
create_directories() {
    log_step "디렉토리 구조 생성 중..."
    
    local nas_dirs=(
        "/mnt/nas-storage/storage"
        "/mnt/nas-storage/media-samples"
        "/mnt/nas-storage/projects"
    )
    
    for dir in "${nas_dirs[@]}"; do
        mkdir -p "$dir"
        chmod 755 "$dir"
        log_info "디렉토리 생성: $dir"
    done
    
    # 프로젝트 폴더의 심볼릭 링크 생성
    local project_root="/srv/personal-infra"
    
    if [[ -d "$project_root" ]]; then
        cd "$project_root"
        
        # 기존 디렉토리를 심볼릭 링크로 교체
        for subdir in photos videos media-samples projects; do
            if [[ -d "nas/$subdir" && ! -L "nas/$subdir" ]]; then
                log_info "기존 디렉토리 백업: nas/$subdir -> nas/${subdir}.backup"
                mv "nas/$subdir" "nas/${subdir}.backup"
            fi
            
            if [[ ! -L "nas/$subdir" ]]; then
                ln -sf "/mnt/nas-storage/$subdir" "nas/$subdir"
                log_info "심볼릭 링크 생성: nas/$subdir -> /mnt/nas-storage/$subdir"
            fi
        done
    fi
    
    log_success "디렉토리 구조 생성 완료"
}

# 테스트 파일 생성
create_test_files() {
    log_step "테스트 파일 생성 중..."
    
    # 각 디렉토리에 README 파일 생성
    cat > /mnt/nas-storage/storage/README.md << 'EOF'
# 🗄️ Storage Directory

이 폴더는 NAS의 모든 데이터를 저장하는 메인 스토리지입니다.

- Nextcloud, SMB, 기타 서비스에서 공유
- 하위 폴더로 photos, videos, texts, utils 등 자유롭게 생성/관리
EOF

    cat > /mnt/nas-storage/media-samples/README.md << 'EOF'
# 🎵 Media Samples Directory

이 폴더는 미디어 샘플 파일들을 저장하는 곳입니다.

## 접근 방법:

### SMB/CIFS 공유 (추천)
- Mac: smb://server-ip/media-samples
- Windows: \\server-ip\media-samples
- 직접 파일 편집 및 복사 가능

### Nextcloud 웹 인터페이스
- 브라우저에서 링크 공유 가능
- 외부 공유 링크 생성 가능

지원 형식: 모든 미디어 파일 형식
EOF

    cat > /mnt/nas-storage/projects/README.md << 'EOF'
# 📁 Projects Directory

이 폴더는 프로젝트 파일들을 저장하는 곳입니다.

## 이중 접근 방식:

### 1. SMB/CIFS 공유
- Mac Finder, Windows 탐색기에서 직접 접근
- 로컬 드라이브처럼 사용 가능
- 대용량 파일 전송에 최적화

### 2. Nextcloud 링크 공유
- 웹 브라우저에서 파일 공유 링크 생성
- 외부 사용자와 안전한 파일 공유
- 접근 권한 및 만료일 설정 가능

## 사용 예시:
- 프로젝트 파일을 SMB로 편집
- 완성된 파일을 Nextcloud로 공유

지원 형식: 모든 파일 형식
EOF

    log_success "테스트 파일 생성 완료"
}

# 상태 확인
check_status() {
    log_step "설정 상태 확인 중..."
    
    echo -e "\n${BLUE}💿 마운트 상태:${NC}"
    df -h /mnt/nas-storage
    
    echo -e "\n${BLUE}📁 디렉토리 구조:${NC}"
    tree /mnt/nas-storage -L 2 2>/dev/null || ls -la /mnt/nas-storage
    
    echo -e "\n${BLUE}🔗 심볼릭 링크:${NC}"
    if [[ -d "/srv/personal-infra/nas" ]]; then
        ls -la /srv/personal-infra/nas/
    fi
    
    echo -e "\n${BLUE}📄 fstab 설정:${NC}"
    grep "nas-storage" /etc/fstab || log_warning "fstab에 설정이 없습니다"
    
    log_success "상태 확인 완료"
}

# 메인 함수
main() {
    echo -e "${PURPLE}🗄️ NAS Storage Setup Script${NC}"
    echo -e "${BLUE}═══════════════════════════════${NC}"
    
    case "${1:-}" in
        --format)
            check_disk
            format_disk
            setup_mount
            create_directories
            create_test_files
            check_status
            ;;
        --mount-only)
            setup_mount
            create_directories
            create_test_files
            check_status
            ;;
        --directories-only)
            create_directories
            create_test_files
            ;;
        --status)
            check_status
            ;;
        --help|-h)
            cat << EOF
사용법: $0 [옵션]

옵션:
  --format           전체 디스크 포맷 및 설정 (⚠️ 데이터 삭제)
  --mount-only       마운트 및 디렉토리 설정만
  --directories-only 디렉토리 구조만 생성
  --status           현재 상태 확인
  --help, -h         이 도움말 표시

예시:
  sudo $0 --format     # 전체 설정 (주의: 데이터 삭제)
  sudo $0 --status     # 상태 확인
EOF
            ;;
        *)
            log_error "옵션을 선택해주세요. --help로 도움말을 확인해보세요."
            exit 1
            ;;
    esac
}

# 루트 권한 확인
if [[ $EUID -ne 0 ]]; then
    log_error "이 스크립트는 루트 권한이 필요합니다. sudo로 실행해주세요."
    exit 1
fi

main "$@" 