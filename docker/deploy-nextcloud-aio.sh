#!/bin/bash

# Nextcloud AIO 배포 스크립트

set -e

# 색깔 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Nextcloud All-in-One 배포 스크립트${NC}"
echo "================================================"

# 환경변수 파일 확인
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  .env 파일이 없습니다. .env.example을 복사해서 .env 파일을 만들어주세요.${NC}"
    echo "cp .env.example .env"
    echo "nano .env  # 도메인과 이메일 설정"
    exit 1
fi

# .env 파일 로드
source .env

# 필수 환경변수 확인
if [ -z "$NEXTCLOUD_DOMAIN" ] || [ "$NEXTCLOUD_DOMAIN" = "nextcloud.yourdomain.com" ]; then
    echo -e "${RED}❌ NEXTCLOUD_DOMAIN을 설정해주세요!${NC}"
    exit 1
fi

if [ -z "$ACME_EMAIL" ] || [ "$ACME_EMAIL" = "your-email@example.com" ]; then
    echo -e "${RED}❌ ACME_EMAIL을 설정해주세요!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 설정 확인됨:${NC}"
echo "   - 도메인: $NEXTCLOUD_DOMAIN"
echo "   - 이메일: $ACME_EMAIL"
echo ""

# Traefik dynamic config 업데이트
echo -e "${YELLOW}🔧 Traefik 설정 업데이트 중...${NC}"
sed -i "s/your-nextcloud-domain.com/$NEXTCLOUD_DOMAIN/g" traefik/dynamic/nextcloud.yml

# Docker 네트워크 생성
echo -e "${YELLOW}🌐 Docker 네트워크 확인/생성 중...${NC}"
docker network inspect web >/dev/null 2>&1 || docker network create web

# 기존 컨테이너 정지 및 제거 (필요시)
echo -e "${YELLOW}🛑 기존 컨테이너 정리 중...${NC}"
docker-compose down 2>/dev/null || true

# 새 컨테이너 시작
echo -e "${GREEN}🚀 새 컨테이너 시작 중...${NC}"
docker-compose up -d

# 컨테이너 상태 확인
echo -e "${YELLOW}⏳ 컨테이너 시작 대기 중...${NC}"
sleep 10

echo -e "${GREEN}📊 컨테이너 상태:${NC}"
docker-compose ps

echo ""
echo -e "${GREEN}🎉 배포 완료!${NC}"
echo "================================================"
echo -e "${BLUE}📋 다음 단계:${NC}"
echo ""
echo "1. 🌐 DNS 설정 (Cloudflare - DNS Only 권장):"
echo "   A 레코드: $NEXTCLOUD_DOMAIN -> $(curl -s ifconfig.me 2>/dev/null || echo "서버IP")"
echo "   ⚠️  Proxied를 끄고 DNS Only로 설정하세요!"
echo ""
echo "2. 🔧 AIO 관리자 패널 접속:"
echo "   https://$NEXTCLOUD_DOMAIN:8080"
echo ""
echo "3. 📱 Nextcloud 앱 접속:"
echo "   https://$NEXTCLOUD_DOMAIN"
echo ""
echo "4. 🛠️  대시보드 접속:"
echo "   Traefik Dashboard: http://$(curl -s ifconfig.me 2>/dev/null || echo "서버IP"):9090"
echo ""
echo "5. 📝 로그 확인:"
echo "   docker logs nextcloud-aio-mastercontainer"
echo "   docker logs traefik"
echo ""
echo -e "${YELLOW}💡 참고사항:${NC}"
echo "- AIO 관리자 패널에서 앱들을 설치하고 설정해야 합니다"
echo "- DNS 전파까지 몇 분 정도 걸릴 수 있습니다"
echo "- SSL 인증서 발급까지 1-2분 정도 소요됩니다" 