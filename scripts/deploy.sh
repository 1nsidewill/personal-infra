#!/bin/bash

# Nextcloud AIO + Traefik 통합 배포 스크립트
# 참조: https://github.com/techworks-id/nextcloud_aio-traefik
# 사용법: ./scripts/deploy.sh [action] [service]
# 예시: ./scripts/deploy.sh setup
#       ./scripts/deploy.sh start traefik
#       ./scripts/deploy.sh logs nextcloud

set -e

# 작업 디렉토리를 docker 폴더로 변경
cd "$(dirname "$0")/../docker"

# 색깔 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# ===========================================
# 🎯 서비스 설정
# ===========================================

# 사용 가능한 서비스들 (순서 중요!)
AVAILABLE_SERVICES=(
    "traefik"       # 1순위: 리버스 프록시
    "nextcloud"     # 2순위: Nextcloud AIO
    "fastapi"       # 3순위: 백엔드 서비스들
    "redis"
    "postgres"
    "qdrant"
)

# Docker Compose 파일 매핑 (참조 레포 방식)
declare -A COMPOSE_FILES
COMPOSE_FILES[traefik]="docker-compose-traefik.yml"
COMPOSE_FILES[nextcloud]="docker-compose-nextcloud_aio.yml"
COMPOSE_FILES[fastapi]="fastapi/docker-compose-fastapi.yml"
COMPOSE_FILES[redis]="redis/docker-compose-redis.yml"
COMPOSE_FILES[postgres]="postgres/docker-compose-postgres.yml"
COMPOSE_FILES[qdrant]="qdrant/docker-compose-qdrant.yml"

# 프로젝트명 매핑 (참조 레포와 동일)
declare -A PROJECT_NAMES
PROJECT_NAMES[traefik]="traefik"
PROJECT_NAMES[nextcloud]="nextcloud_aio"
PROJECT_NAMES[fastapi]="fastapi"
PROJECT_NAMES[redis]="redis"
PROJECT_NAMES[postgres]="postgres"
PROJECT_NAMES[qdrant]="qdrant"

# 서비스 설명
declare -A SERVICE_DESCRIPTIONS
SERVICE_DESCRIPTIONS[traefik]="리버스 프록시 & SSL 인증서 관리"
SERVICE_DESCRIPTIONS[nextcloud]="Nextcloud All-in-One (AIO) 클라우드"
SERVICE_DESCRIPTIONS[fastapi]="FastAPI 백엔드 서비스"
SERVICE_DESCRIPTIONS[redis]="인메모리 캐시 & 세션 스토어"
SERVICE_DESCRIPTIONS[postgres]="PostgreSQL 데이터베이스"
SERVICE_DESCRIPTIONS[qdrant]="벡터 데이터베이스"

# 필수 네트워크들
REQUIRED_NETWORKS=("proxy" "nextcloud-aio")

# ===========================================
# 📋 유틸리티 함수들
# ===========================================

# 함수: 사용법 출력
show_usage() {
    echo -e "${BLUE}🚀 Nextcloud AIO + Traefik 통합 관리 스크립트${NC}"
    echo -e "${PURPLE}참조: https://github.com/techworks-id/nextcloud_aio-traefik${NC}"
    echo "================================================"
    echo ""
    echo -e "${CYAN}사용법:${NC}"
    echo "  $0 [action] [service]"
    echo ""
    echo -e "${CYAN}Actions:${NC}"
    echo "  setup     - 🏗️  초기 설정 (네트워크 생성 + 환경설정)"
    echo "  start     - ▶️  서비스 시작"
    echo "  stop      - ⏹️  서비스 정지"  
    echo "  restart   - 🔄 서비스 재시작"
    echo "  logs      - 📝 서비스 로그 확인"
    echo "  status    - 📊 서비스 상태 확인"
    echo "  deploy    - 🚀 전체 배포 (setup + start)"
    echo "  cleanup   - 🧹 서비스 정리 (컨테이너 + 네트워크)"
    echo "  list      - 📜 사용 가능한 서비스 목록"
    echo ""
    echo -e "${CYAN}Services:${NC}"
    for service in "${AVAILABLE_SERVICES[@]}"; do
        echo "  $service - ${SERVICE_DESCRIPTIONS[$service]}"
    done
    echo "  all       - 모든 서비스"
    echo ""
    echo -e "${CYAN}예시:${NC}"
    echo "  $0 setup               # 초기 설정 (최초 실행)"
    echo "  $0 deploy              # 전체 배포"
    echo "  $0 start traefik       # Traefik만 시작"
    echo "  $0 logs nextcloud      # Nextcloud 로그 확인"
    echo "  $0 restart all         # 모든 서비스 재시작"
    echo ""
    echo -e "${YELLOW}💡 현재 작업 디렉토리: $(pwd)${NC}"
}

# 함수: 환경변수 파일 확인 및 검증
check_env_file() {
    local env_file=".env"
    
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}❌ .env 파일이 없습니다!${NC}"
        echo ""
        echo -e "${YELLOW}🔧 설정 방법:${NC}"
        echo "1. cp .env.example .env"
        echo "2. nano .env  # 설정 편집"
        echo "3. $0 setup   # 초기 설정 실행"
        return 1
    fi
    
    # .env 파일 로드
    set -a  # 자동으로 export
    source "$env_file"
    set +a
    
    echo -e "${GREEN}✅ .env 파일 로드됨${NC}"
    
    # 필수 환경변수 검증
    local missing_vars=()
    
    [ -z "$NEXTCLOUD_DOMAIN" ] && missing_vars+=("NEXTCLOUD_DOMAIN")
    [ -z "$ACME_EMAIL" ] && missing_vars+=("ACME_EMAIL")
    [ -z "$TZ" ] && missing_vars+=("TZ")
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo -e "${RED}❌ 필수 환경변수가 누락되었습니다:${NC}"
        for var in "${missing_vars[@]}"; do
            echo "   - $var"
        done
        echo ""
        echo "👉 .env 파일을 확인하고 설정해주세요!"
        return 1
    fi
    
    # 기본값 확인
    if [ "$NEXTCLOUD_DOMAIN" = "nextcloud.insidewill.site" ] || [ "$ACME_EMAIL" = "yiguha@gmail.com" ]; then
        echo -e "${YELLOW}⚠️  기본값 사용 중 - 실제 값으로 변경을 권장합니다${NC}"
    fi
    
    echo -e "${CYAN}📋 설정 정보:${NC}"
    echo "   - 도메인: $NEXTCLOUD_DOMAIN"
    echo "   - 이메일: $ACME_EMAIL"
    echo "   - 시간대: $TZ"
    echo "   - AIO 포트: ${AIO_ADMIN_PORT:-8081}"
    
    return 0
}

# 함수: Docker 네트워크 생성
ensure_networks() {
    echo -e "${YELLOW}🌐 Docker 네트워크 확인/생성 중...${NC}"
    
    for network in "${REQUIRED_NETWORKS[@]}"; do
        if ! docker network inspect "$network" >/dev/null 2>&1; then
            echo -e "${GREEN}📶 네트워크 생성: $network${NC}"
            docker network create --driver=bridge "$network"
        else
            echo -e "${BLUE}✅ 네트워크 존재: $network${NC}"
        fi
    done
}

# 함수: 서비스별 Docker Compose 실행 (참조 레포 방식)
run_compose() {
    local action=$1
    local service=$2
    local compose_file=${COMPOSE_FILES[$service]}
    local project_name=${PROJECT_NAMES[$service]}
    
    if [ -z "$compose_file" ]; then
        echo -e "${RED}❌ 알 수 없는 서비스: $service${NC}"
        return 1
    fi
    
    if [ ! -f "$compose_file" ]; then
        echo -e "${YELLOW}⚠️  파일이 없습니다: $compose_file${NC}"
        echo "해당 서비스는 아직 설정되지 않았습니다."
        return 1
    fi
    
    echo -e "${GREEN}📦 $service ${action} (프로젝트: $project_name)${NC}"
    docker compose -p "$project_name" -f "$compose_file" $action
}

# 함수: 모든 서비스에 대해 실행 (순서 고려)
run_all_services() {
    local action=$1
    
    if [ "$action" = "down" ] || [ "$action" = "stop" ]; then
        # 정지 시에는 역순으로
        for ((i=${#AVAILABLE_SERVICES[@]}-1; i>=0; i--)); do
            local service="${AVAILABLE_SERVICES[i]}"
            local compose_file=${COMPOSE_FILES[$service]}
            local project_name=${PROJECT_NAMES[$service]}
            if [ -f "$compose_file" ]; then
                echo -e "${GREEN}📦 $service $action (프로젝트: $project_name)${NC}"
                docker compose -p "$project_name" -f "$compose_file" $action 2>/dev/null || true
            fi
        done
    else
        # 시작 시에는 정순으로 (traefik 먼저)
        for service in "${AVAILABLE_SERVICES[@]}"; do
            local compose_file=${COMPOSE_FILES[$service]}
            local project_name=${PROJECT_NAMES[$service]}
            if [ -f "$compose_file" ]; then
                echo -e "${GREEN}📦 $service $action (프로젝트: $project_name)${NC}"
                docker compose -p "$project_name" -f "$compose_file" $action 2>/dev/null || true
                
                # 시작 시 잠시 대기 (네트워크 안정화)
                if [ "$action" = "up -d" ] && [ "$service" = "traefik" ]; then
                    echo -e "${YELLOW}⏳ Traefik 초기화 대기 중...${NC}"
                    sleep 5
                fi
            fi
        done
    fi
}

# 함수: 서비스 상태 확인
show_status() {
    local service=$1
    
    if [ "$service" = "all" ]; then
        echo -e "${BLUE}📊 전체 서비스 상태:${NC}"
        echo "================================================"
        
        for service_name in "${AVAILABLE_SERVICES[@]}"; do
            local compose_file=${COMPOSE_FILES[$service_name]}
            local project_name=${PROJECT_NAMES[$service_name]}
            if [ -f "$compose_file" ]; then
                echo ""
                echo -e "${CYAN}$service_name (${SERVICE_DESCRIPTIONS[$service_name]}) - 프로젝트: $project_name:${NC}"
                docker compose -p "$project_name" -f "$compose_file" ps 2>/dev/null || echo "  (서비스 없음)"
            fi
        done
        
        echo ""
        echo -e "${PURPLE}네트워크 상태:${NC}"
        for network in "${REQUIRED_NETWORKS[@]}"; do
            if docker network inspect "$network" >/dev/null 2>&1; then
                echo -e "  ✅ $network"
            else
                echo -e "  ❌ $network"
            fi
        done
    else
        run_compose "ps" "$service"
    fi
}

# 함수: 서비스 로그 확인
show_logs() {
    local service=$1
    
    if [ "$service" = "all" ]; then
        echo -e "${BLUE}📝 전체 서비스 로그 (Ctrl+C로 종료):${NC}"
        # 여러 compose 파일의 로그를 동시에 보기는 복잡하므로 개별 확인 안내
        echo -e "${YELLOW}💡 개별 서비스 로그를 확인하려면:${NC}"
        for service_name in "${AVAILABLE_SERVICES[@]}"; do
            echo "   $0 logs $service_name"
        done
        echo ""
        echo -e "${CYAN}Traefik 로그 시작:${NC}"
        run_compose "logs -f" "traefik"
    else
        run_compose "logs -f" "$service"
    fi
}

# 함수: 초기 설정
setup() {
    echo -e "${BLUE}🏗️  Nextcloud AIO + Traefik 초기 설정${NC}"
    echo "================================================"
    
    # 환경변수 확인
    if ! check_env_file; then
        exit 1
    fi
    
    # 네트워크 생성
    ensure_networks
    
    echo ""
    echo -e "${GREEN}🎉 초기 설정 완료!${NC}"
    echo ""
    echo -e "${CYAN}다음 단계:${NC}"
    echo "1. $0 deploy      # 전체 서비스 배포"
    echo "2. $0 status      # 상태 확인"
    echo "3. $0 logs traefik # 로그 확인"
}

# 함수: 전체 배포
deploy_all() {
    echo -e "${BLUE}🚀 Nextcloud AIO + Traefik 전체 배포${NC}"
    echo "================================================"
    
    # 초기 설정
    setup
    
    echo ""
    echo -e "${YELLOW}🛑 기존 서비스 정리 중...${NC}"
    run_all_services "down"
    
    echo ""
    echo -e "${GREEN}🚀 서비스 시작 중...${NC}"
    run_all_services "up -d"
    
    echo ""
    echo -e "${YELLOW}⏳ 서비스 초기화 대기 중...${NC}"
    sleep 15
    
    echo ""
    show_status "all"
    
    echo ""
    echo -e "${GREEN}🎉 배포 완료!${NC}"
    echo "================================================"
    
    # 접속 정보 출력
    echo -e "${BLUE}📋 서비스 접속 정보:${NC}"
    echo ""
    echo "🔧 AIO 관리자 패널: http://$(curl -s ifconfig.me 2>/dev/null || echo "서버IP"):${AIO_ADMIN_PORT:-8081}"
    echo "📱 Nextcloud: https://$NEXTCLOUD_DOMAIN"
    echo "🛠️  Traefik Dashboard: http://$(curl -s ifconfig.me 2>/dev/null || echo "서버IP"):${TRAEFIK_DASHBOARD_PORT:-9090}"
    echo ""
    echo -e "${YELLOW}💡 참고사항:${NC}"
    echo "- DNS 전파까지 몇 분 정도 걸릴 수 있습니다"
    echo "- SSL 인증서 발급까지 1-2분 정도 소요됩니다"
    echo "- AIO 설정에서 도메인을 확인하고 Nextcloud를 설치하세요"
}

# 함수: 서비스 정리
cleanup() {
    echo -e "${YELLOW}🧹 서비스 정리 중...${NC}"
    
    # 모든 서비스 정지
    run_all_services "down"
    
    # 미사용 리소스 정리
    echo -e "${YELLOW}🗑️  미사용 리소스 정리 중...${NC}"
    docker system prune -f
    
    echo -e "${GREEN}✅ 정리 완료${NC}"
}

# ===========================================
# 🎯 메인 로직
# ===========================================

ACTION=$1
SERVICE=$2

case $ACTION in
    "setup")
        setup
        ;;
    "start")
        if [ -z "$SERVICE" ]; then
            echo -e "${RED}❌ 서비스를 지정해주세요${NC}"
            show_usage
            exit 1
        fi
        ensure_networks
        if [ "$SERVICE" = "all" ]; then
            run_all_services "up -d"
        else
            run_compose "up -d" "$SERVICE"
        fi
        ;;
    "stop")
        if [ -z "$SERVICE" ]; then
            echo -e "${RED}❌ 서비스를 지정해주세요${NC}"
            show_usage
            exit 1
        fi
        if [ "$SERVICE" = "all" ]; then
            run_all_services "down"
        else
            run_compose "down" "$SERVICE"
        fi
        ;;
    "restart")
        if [ -z "$SERVICE" ]; then
            echo -e "${RED}❌ 서비스를 지정해주세요${NC}"
            show_usage
            exit 1
        fi
        if [ "$SERVICE" = "all" ]; then
            run_all_services "restart"
        else
            run_compose "restart" "$SERVICE"
        fi
        ;;
    "logs")
        if [ -z "$SERVICE" ]; then
            echo -e "${RED}❌ 서비스를 지정해주세요${NC}"
            show_usage
            exit 1
        fi
        show_logs "$SERVICE"
        ;;
    "status")
        SERVICE=${SERVICE:-"all"}
        show_status "$SERVICE"
        ;;
    "deploy")
        deploy_all
        ;;
    "cleanup")
        cleanup
        ;;
    "list")
        echo -e "${CYAN}사용 가능한 서비스:${NC}"
        for service in "${AVAILABLE_SERVICES[@]}"; do
            local compose_file=${COMPOSE_FILES[$service]}
            local status="❌ 미설정"
            if [ -f "$compose_file" ]; then
                status="✅ 설정됨"
            fi
            echo "  $service - ${SERVICE_DESCRIPTIONS[$service]} ($status)"
        done
        ;;
    *)
        show_usage
        exit 1
        ;;
esac 