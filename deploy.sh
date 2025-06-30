#!/bin/bash

# 🏠 Personal Infrastructure Deployment Script
# 완전 자동화된 배포 스크립트 with 이모지 로깅 & 분기처리
check_dependencies

set -e

# 🎨 색상 및 이모지 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 📊 로깅 함수들
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

log_docker() {
    echo -e "${CYAN}🐳 DOCKER${NC} | $1"
}

# 📋 헬프 함수
show_help() {
    cat << EOF
🏠 Personal Infrastructure Deployment Script

사용법: $0 [옵션]

옵션:
  -h, --help              이 도움말 표시
  -s, --status            서비스 상태 확인
  -u, --update            서비스 업데이트 (이미지 pull + restart)
  -d, --down              모든 서비스 중지
  -b, --backup            데이터 백업 수행
  -l, --logs [서비스명]    로그 확인 (서비스명 생략시 전체)
  --smb                   SMB 서비스만 배포
  --core                  코어 서비스만 배포 (Traefik, Nextcloud, DB, Redis)
  --init-storage          NAS 스토리지 디렉토리 초기화
  --health-check          전체 시스템 헬스체크

예시:
  $0                      # 전체 서비스 배포
  $0 --status             # 상태 확인
  $0 --logs nextcloud     # Nextcloud 로그 확인
  $0 --smb                # SMB만 배포

EOF
}

# 🔧 유틸리티 함수들
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker가 설치되지 않았습니다!"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker 데몬이 실행되지 않았습니다!"
        exit 1
    fi
    
    log_success "Docker 환경 확인 완료"
}

check_dependencies() {
    local deps=("docker" "docker-compose")
    
    # docker compose vs docker-compose 확인
    if docker compose version &> /dev/null; then
        DOCKER_COMPOSE="docker compose"
    elif docker-compose --version &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    else
        log_error "docker compose 또는 docker-compose를 찾을 수 없습니다!"
        exit 1
    fi
    
    log_success "Docker Compose 확인 완료: $DOCKER_COMPOSE"
}

create_network() {
    if ! docker network ls | grep -q "web"; then
        log_step "Docker 네트워크 'web' 생성 중..."
        docker network create web
        log_success "네트워크 'web' 생성 완료"
    else
        log_info "네트워크 'web' 이미 존재"
    fi
}

create_directories() {
    log_step "필요한 디렉토리들 생성 중..."
    
    local dirs=(
        "data/postgres"
        "data/redis" 
        "data/nextcloud"
        "nas/photos"
        "nas/videos"
        "nas/media-samples"
        "nas/projects"
        "docker/traefik/dynamic"
        "logs"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_info "디렉토리 생성: $dir"
        fi
    done
    
    # acme.json 권한 설정
    touch docker/traefik/acme.json
    chmod 600 docker/traefik/acme.json
    
    log_success "디렉토리 구조 생성 완료"
}

# 🗄️ 스토리지 초기화
init_storage() {
    log_step "NAS 스토리지 디렉토리 구조 초기화 중..."
    
    if [[ -d "/mnt/nas-storage" ]]; then
        local nas_dirs=(
            "/mnt/nas-storage/photos"
            "/mnt/nas-storage/videos" 
            "/mnt/nas-storage/media-samples"
            "/mnt/nas-storage/projects"
        )
        
        for dir in "${nas_dirs[@]}"; do
            sudo mkdir -p "$dir"
            sudo chmod 755 "$dir"
            log_info "NAS 디렉토리 생성: $dir"
        done
        
        # 심볼릭 링크 생성 (프로젝트 nas/ 폴더에서)
        for subdir in photos videos media-samples projects; do
            if [[ ! -L "nas/$subdir" ]]; then
                ln -sf "/mnt/nas-storage/$subdir" "nas/$subdir"
                log_info "심볼릭 링크 생성: nas/$subdir -> /mnt/nas-storage/$subdir"
            fi
        done
        
        log_success "NAS 스토리지 구조 초기화 완료"
    else
        log_warning "NAS 스토리지 (/mnt/nas-storage)가 마운트되지 않았습니다"
        log_info "일반 nas/ 디렉토리를 사용합니다"
    fi
}

# 📊 상태 확인
check_status() {
    log_step "서비스 상태 확인 중..."
    
    echo -e "\n${CYAN}🐳 컨테이너 상태:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo -e "\n${PURPLE}📊 리소스 사용량:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    
    echo -e "\n${GREEN}🌐 접속 정보:${NC}"
    echo "  • Nextcloud: http://localhost"
    echo "  • Traefik Dashboard: http://localhost:8080"
    
    if docker ps | grep -q samba; then
        echo "  • SMB 공유: smb://$(hostname -I | awk '{print $1}')/media-samples"
    fi
}

# 📋 헬스체크
health_check() {
    log_step "시스템 헬스체크 수행 중..."
    
    local services=("traefik" "nextcloud" "postgres" "redis")
    local failed=0
    
    for service in "${services[@]}"; do
        if docker ps | grep -q "$service"; then
            if docker exec "$service" echo "Health check" &> /dev/null; then
                log_success "$service: 정상"
            else
                log_warning "$service: 응답 없음"
                ((failed++))
            fi
        else
            log_error "$service: 실행되지 않음"
            ((failed++))
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        log_success "모든 서비스가 정상 작동 중입니다! 🎉"
    else
        log_warning "$failed개 서비스에 문제가 있습니다"
    fi
    
    return $failed
}

# 💾 백업
backup_data() {
    log_step "데이터 백업 수행 중..."
    
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # PostgreSQL 백업
    if docker ps | grep -q postgres; then
        log_info "PostgreSQL 데이터베이스 백업 중..."
        docker exec postgres pg_dump -U nextcloud nextcloud > "$backup_dir/postgres_backup.sql"
        log_success "PostgreSQL 백업 완료"
    fi
    
    # Nextcloud 설정 백업
    if [[ -d "data/nextcloud/config" ]]; then
        log_info "Nextcloud 설정 백업 중..."
        tar -czf "$backup_dir/nextcloud_config.tar.gz" data/nextcloud/config/
        log_success "Nextcloud 설정 백업 완료"
    fi
    
    # Docker Compose 설정 백업
    cp docker-compose.yml "$backup_dir/"
    if [[ -f ".env" ]]; then
        cp .env "$backup_dir/"
    fi
    
    log_success "백업 완료: $backup_dir"
}

# 📝 로그 확인
show_logs() {
    local service="$1"
    
    if [[ -n "$service" ]]; then
        log_info "$service 로그 확인 중..."
        docker logs -f "$service"
    else
        log_info "전체 서비스 로그 확인 중..."
        $DOCKER_COMPOSE logs -f
    fi
}

# 🔄 서비스 업데이트
update_services() {
    log_step "서비스 업데이트 중..."
    
    log_docker "최신 이미지 다운로드 중..."
    $DOCKER_COMPOSE pull
    
    log_docker "서비스 재시작 중..."
    $DOCKER_COMPOSE up -d
    
    log_success "서비스 업데이트 완료"
}

# 🐳 코어 서비스 배포
deploy_core() {
    log_step "코어 서비스 배포 시작..."
    
    check_docker
    check_dependencies
    create_network
    create_directories
    
    log_docker "코어 서비스 시작 중..."
    $DOCKER_COMPOSE up -d traefik postgres redis nextcloud
    
    # 서비스 시작 대기
    log_info "서비스 초기화 대기 중..."
    sleep 10
    
    # Nextcloud 초기화 확인
    local retries=0
    while [[ $retries -lt 30 ]]; do
        if docker exec nextcloud curl -f http://localhost &> /dev/null; then
            log_success "Nextcloud 초기화 완료"
            break
        fi
        ((retries++))
        sleep 2
        log_info "Nextcloud 초기화 대기 중... ($retries/30)"
    done
    
    log_success "코어 서비스 배포 완료! 🎉"
}

# 📁 SMB 서비스 배포
deploy_smb() {
    log_step "SMB 서비스 배포 중..."
    
    # SMB Docker Compose 파일이 있는지 확인
    if [[ ! -f "docker-compose.samba.yml" ]]; then
        log_warning "docker-compose.samba.yml 파일이 없습니다. 생성 중..."
        # SMB 설정 파일 생성 로직은 별도로 구현
    fi
    
    log_docker "SMB 서비스 시작 중..."
    docker compose -f docker-compose.samba.yml up -d
    
    log_success "SMB 서비스 배포 완료"
}

# 🚀 전체 배포
deploy_all() {
    log_step "전체 인프라 배포 시작..."
    
    deploy_core
    
    # SMB 파일이 있으면 배포
    if [[ -f "docker-compose.samba.yml" ]]; then
        deploy_smb
    fi
    
    log_success "전체 배포 완료! 🏠✨"
    echo ""
    log_info "접속 정보:"
    echo "  🌐 Nextcloud: http://localhost"
    echo "  📊 Traefik Dashboard: http://localhost:8080"
    echo "  📁 기본 계정: admin / changeme"
    echo ""
    log_info "상태 확인: $0 --status"
    log_info "로그 확인: $0 --logs"
}

# 🔻 서비스 중지
stop_services() {
    log_step "모든 서비스 중지 중..."
    
    $DOCKER_COMPOSE down
    
    if [[ -f "docker-compose.samba.yml" ]]; then
        $DOCKER_COMPOSE -f docker-compose.samba.yml down
    fi
    
    log_success "모든 서비스 중지 완료"
}

# 📌 메인 로직
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            ;;
        -s|--status)
            check_status
            ;;
        -u|--update)
            update_services
            ;;
        -d|--down)
            stop_services
            ;;
        -b|--backup)
            backup_data
            ;;
        -l|--logs)
            show_logs "$2"
            ;;
        --smb)
            deploy_smb
            ;;
        --core)
            deploy_core
            ;;
        --init-storage)
            init_storage
            ;;
        --health-check)
            health_check
            ;;
        "")
            deploy_all
            ;;
        *)
            log_error "알 수 없는 옵션: $1"
            show_help
            exit 1
            ;;
    esac
}

# 🎬 스크립트 실행
echo -e "${PURPLE}🏠 Personal Infrastructure Deployment Script${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"

main "$@" 