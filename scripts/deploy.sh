#!/bin/bash

# 통합 서비스 배포 및 관리 스크립트
# 사용법: ./scripts/deploy.sh [action] [service]
# 예시: ./scripts/deploy.sh start nextcloud
#       ./scripts/deploy.sh restart all
#       ./scripts/deploy.sh logs traefik

set -e

# 작업 디렉토리를 docker 폴더로 변경
cd "$(dirname "$0")/../docker"

# 색깔 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 사용 가능한 서비스들
AVAILABLE_SERVICES=(
    "traefik"
    "nextcloud"
    "fastapi"
    "redis"
    "postgres"
    "qdrant"
)

# Docker Compose 파일 매핑
declare -A COMPOSE_FILES
COMPOSE_FILES[traefik]="docker-compose.yml"
COMPOSE_FILES[nextcloud]="docker-compose.yml"
COMPOSE_FILES[fastapi]="fastapi/docker-compose.fastapi.yml"
COMPOSE_FILES[redis]="redis/docker-compose.redis.yml"
COMPOSE_FILES[postgres]="postgres/docker-compose.postgres.yml"
COMPOSE_FILES[qdrant]="qdrant/docker-compose.qdrant.yml"

# 서비스 설명
declare -A SERVICE_DESCRIPTIONS
SERVICE_DESCRIPTIONS[traefik]="리버스 프록시 & SSL 관리"
SERVICE_DESCRIPTIONS[nextcloud]="클라우드 스토리지 & 협업"
SERVICE_DESCRIPTIONS[fastapi]="FastAPI 백엔드 서비스"
SERVICE_DESCRIPTIONS[redis]="인메모리 캐시 & 세션 스토어"
SERVICE_DESCRIPTIONS[postgres]="PostgreSQL 데이터베이스"
SERVICE_DESCRIPTIONS[qdrant]="벡터 데이터베이스"

# 함수: 사용법 출력
show_usage() {
    echo -e "${BLUE}🚀 통합 서비스 관리 스크립트${NC}"
    echo "================================================"
    echo ""
    echo -e "${CYAN}사용법:${NC}"
    echo "  $0 [action] [service]"
    echo ""
    echo -e "${CYAN}Actions:${NC}"
    echo "  start     - 서비스 시작"
    echo "  stop      - 서비스 정지"
    echo "  restart   - 서비스 재시작"
    echo "  logs      - 서비스 로그 확인"
    echo "  status    - 서비스 상태 확인"
    echo "  deploy    - 전체 배포 (설정 업데이트 + 시작)"
    echo "  list      - 사용 가능한 서비스 목록"
    echo ""
    echo -e "${CYAN}Services:${NC}"
    for service in "${AVAILABLE_SERVICES[@]}"; do
        echo "  $service - ${SERVICE_DESCRIPTIONS[$service]}"
    done
    echo "  all       - 모든 서비스"
    echo ""
    echo -e "${CYAN}예시:${NC}"
    echo "  $0 deploy              # 전체 배포"
    echo "  $0 start nextcloud     # Nextcloud 시작"
    echo "  $0 logs traefik        # Traefik 로그 확인"
    echo "  $0 restart all         # 모든 서비스 재시작"
    echo ""
    echo -e "${YELLOW}💡 현재 작업 디렉토리: $(pwd)${NC}"
}

# 함수: 환경변수 파일 확인
check_env_file() {
    if [ ! -f .env ]; then
        echo -e "${YELLOW}⚠️  .env 파일이 없습니다.${NC}"
        echo "cp .env.example .env"
        echo "nano .env  # 설정을 완료한 후 다시 실행하세요"
        return 1
    fi
    
    source .env
    
    # 필수 환경변수 확인 (nextcloud 관련)
    if [ -n "$NEXTCLOUD_DOMAIN" ] && [ "$NEXTCLOUD_DOMAIN" != "nextcloud.yourdomain.com" ]; then
        if [ -z "$ACME_EMAIL" ] || [ "$ACME_EMAIL" = "your-email@example.com" ]; then
            echo -e "${RED}❌ ACME_EMAIL을 설정해주세요!${NC}"
            return 1
        fi
    fi
    
    return 0
}

# 함수: Docker 네트워크 확인/생성
ensure_network() {
    echo -e "${YELLOW}🌐 Docker 네트워크 확인/생성 중...${NC}"
    docker network inspect web >/dev/null 2>&1 || docker network create web
}

# 함수: Traefik 설정 업데이트
update_traefik_config() {
    if [ -n "$NEXTCLOUD_DOMAIN" ] && [ "$NEXTCLOUD_DOMAIN" != "nextcloud.yourdomain.com" ]; then
        echo -e "${YELLOW}🔧 Traefik 설정 업데이트 중...${NC}"
        sed -i "s/your-nextcloud-domain.com/$NEXTCLOUD_DOMAIN/g" traefik/dynamic/nextcloud.yml
    fi
}

# 함수: 서비스별 Docker Compose 실행
run_compose() {
    local action=$1
    local service=$2
    local compose_file=${COMPOSE_FILES[$service]}
    
    if [ -z "$compose_file" ]; then
        echo -e "${RED}❌ 알 수 없는 서비스: $service${NC}"
        return 1
    fi
    
    if [ ! -f "$compose_file" ]; then
        echo -e "${YELLOW}⚠️  파일이 없습니다: $compose_file${NC}"
        echo "해당 서비스는 아직 설정되지 않았습니다."
        return 1
    fi
    
    echo -e "${GREEN}📦 $service ($action)${NC}"
    docker compose -f "$compose_file" $action
}

# 함수: 모든 서비스에 대해 실행
run_all_services() {
    local action=$1
    
    for service in "${AVAILABLE_SERVICES[@]}"; do
        local compose_file=${COMPOSE_FILES[$service]}
        if [ -f "$compose_file" ]; then
            echo -e "${GREEN}📦 $service ($action)${NC}"
            docker compose -f "$compose_file" $action 2>/dev/null || true
        fi
    done
}

# 함수: 서비스 상태 확인
show_status() {
    local service=$1
    
    if [ "$service" = "all" ]; then
        echo -e "${BLUE}📊 전체 서비스 상태:${NC}"
        docker compose -f docker-compose.yml ps 2>/dev/null || true
        for service_name in "${AVAILABLE_SERVICES[@]}"; do
            local compose_file=${COMPOSE_FILES[$service_name]}
            if [ -f "$compose_file" ] && [ "$compose_file" != "docker-compose.yml" ]; then
                echo ""
                echo -e "${CYAN}$service_name:${NC}"
                docker compose -f "$compose_file" ps 2>/dev/null || true
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
        echo -e "${BLUE}📝 전체 서비스 로그:${NC}"
        docker compose -f docker-compose.yml logs -f
    else
        run_compose "logs -f" "$service"
    fi
}

# 함수: 전체 배포
deploy_all() {
    echo -e "${BLUE}🚀 통합 서비스 배포 시작${NC}"
    echo "================================================"
    echo "작업 디렉토리: $(pwd)"
    echo ""
    
    # 환경변수 확인
    if ! check_env_file; then
        exit 1
    fi
    
    echo -e "${GREEN}✅ 설정 확인됨${NC}"
    if [ -n "$NEXTCLOUD_DOMAIN" ] && [ "$NEXTCLOUD_DOMAIN" != "nextcloud.yourdomain.com" ]; then
        echo "   - Nextcloud 도메인: $NEXTCLOUD_DOMAIN"
        echo "   - 이메일: $ACME_EMAIL"
    fi
    echo ""
    
    # 네트워크 생성
    ensure_network
    
    # Traefik 설정 업데이트
    update_traefik_config
    
    # 기존 서비스 정리
    echo -e "${YELLOW}🛑 기존 서비스 정리 중...${NC}"
    run_all_services "down"
    
    # 새 서비스 시작
    echo -e "${GREEN}🚀 서비스 시작 중...${NC}"
    run_all_services "up -d"
    
    # 상태 확인
    echo -e "${YELLOW}⏳ 서비스 시작 대기 중...${NC}"
    sleep 10
    
    show_status "all"
    
    echo ""
    echo -e "${GREEN}🎉 배포 완료!${NC}"
    echo "================================================"
    
    # 접속 정보 출력
    if [ -n "$NEXTCLOUD_DOMAIN" ] && [ "$NEXTCLOUD_DOMAIN" != "nextcloud.yourdomain.com" ]; then
        echo -e "${BLUE}📋 서비스 접속 정보:${NC}"
        echo ""
        echo "🔧 AIO 관리자 패널: https://$NEXTCLOUD_DOMAIN:8080"
        echo "📱 Nextcloud: https://$NEXTCLOUD_DOMAIN"
        echo "🛠️  Traefik Dashboard: http://$(curl -s ifconfig.me 2>/dev/null || echo "서버IP"):9090"
        echo ""
        echo -e "${YELLOW}💡 참고사항:${NC}"
        echo "- DNS 전파까지 몇 분 정도 걸릴 수 있습니다"
        echo "- SSL 인증서 발급까지 1-2분 정도 소요됩니다"
    fi
}

# 메인 로직
ACTION=$1
SERVICE=$2

case $ACTION in
    "start")
        if [ -z "$SERVICE" ]; then
            echo -e "${RED}❌ 서비스를 지정해주세요${NC}"
            show_usage
            exit 1
        fi
        ensure_network
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