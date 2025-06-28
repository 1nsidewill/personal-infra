# 🚀 빠른 시작 가이드

## 📋 **개요**

우분투 서버에서 통합 서비스 시스템을 배포하는 완전한 프로세스입니다.

## 🔄 **서버 배포 프로세스**

### 1. 서버 접속 및 코드 업데이트

```bash
# 서버 접속
ssh your-user@your-server

# 프로젝트 디렉토리로 이동
cd personal-infra

# 최신 코드 받기
git pull origin main

# 스크립트 실행 권한 확인
chmod +x scripts/deploy.sh
```

### 2. 환경 설정

```bash
# docker 디렉토리로 이동
cd docker

# 환경변수 파일 생성 (첫 번째 배포시만)
cp .env.example .env

# 환경변수 설정
nano .env
```

**필수 설정 항목:**
```bash
# Nextcloud 도메인 (실제 도메인으로 변경)
NEXTCLOUD_DOMAIN=nextcloud.yourdomain.com

# Let's Encrypt 이메일 (실제 이메일로 변경)
ACME_EMAIL=your-email@example.com

# 기타 설정
SKIP_DOMAIN_VALIDATION=false
```

### 3. DNS 설정 확인

**Cloudflare 설정 (권장):**
- Type: `A`
- Name: `nextcloud` (또는 전체 도메인)
- Content: `서버 IP`
- **Proxy Status: DNS Only** ⭐ (중요!)

### 4. 배포 실행

```bash
# 프로젝트 루트로 이동
cd /path/to/personal-infra

# 통합 배포 실행
./scripts/deploy.sh deploy
```

## 🎮 **일상적인 관리**

### 서비스 상태 확인
```bash
./scripts/deploy.sh status all
```

### 로그 확인
```bash
# 전체 로그
./scripts/deploy.sh logs all

# 특정 서비스 로그
./scripts/deploy.sh logs nextcloud
./scripts/deploy.sh logs traefik
```

### 서비스 재시작
```bash
# 전체 재시작
./scripts/deploy.sh restart all

# 특정 서비스만
./scripts/deploy.sh restart nextcloud
```

### 서비스 정지/시작
```bash
# 전체 정지
./scripts/deploy.sh stop all

# 전체 시작
./scripts/deploy.sh start all
```

## 🔄 **코드 업데이트 후 재배포**

새로운 기능이나 설정 변경 후:

```bash
# 1. 코드 업데이트
git pull origin main

# 2. 재배포 (기존 컨테이너 정리 + 새로 시작)
./scripts/deploy.sh deploy
```

## 🌟 **새로운 서비스 추가 워크플로우**

### 1. 로컬에서 개발

```bash
# 새 서비스 디렉토리 생성
mkdir docker/myservice

# Compose 파일 생성
cat > docker/myservice/docker-compose.myservice.yml << 'EOF'
services:
  myservice:
    image: myservice:latest
    container_name: myservice
    restart: unless-stopped
    networks:
      - web

networks:
  web:
    external: true
EOF
```

### 2. 스크립트에 등록

`scripts/deploy.sh` 수정:
```bash
# 서비스 목록에 추가
AVAILABLE_SERVICES+=(
    "myservice"
)

# 파일 매핑 추가
COMPOSE_FILES[myservice]="myservice/docker-compose.myservice.yml"

# 설명 추가
SERVICE_DESCRIPTIONS[myservice]="내 새로운 서비스"
```

### 3. 서버에 배포

```bash
# 코드 푸시
git add .
git commit -m "Add myservice"
git push origin main

# 서버에서 업데이트
ssh your-user@your-server
cd personal-infra
git pull origin main

# 새 서비스 시작
./scripts/deploy.sh start myservice
```

## 🔧 **포트 & 접속 정보**

### 기본 포트
- **80**: HTTP → HTTPS 리다이렉트
- **443**: HTTPS (Nextcloud 메인)
- **8080**: AIO 관리자 패널
- **9090**: Traefik Dashboard

### 접속 URL
- **Nextcloud**: `https://your-domain.com`
- **AIO 관리자**: `https://your-domain.com:8080`
- **Traefik Dashboard**: `http://서버IP:9090`

## 🔍 **문제 해결**

### SSL 인증서 발급 실패
```bash
# DNS 전파 확인
nslookup your-domain.com

# Cloudflare Proxy 상태 확인 (DNS Only여야 함)
# 포트 80/443 접근성 확인
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443
```

### 컨테이너 시작 실패
```bash
# 로그 확인
./scripts/deploy.sh logs nextcloud

# Docker 상태 확인
docker ps -a
docker network ls
```

### 방화벽 설정 (Ubuntu)
```bash
# 필요한 포트 열기
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 8080
sudo ufw allow 9090
```

## 📚 **참고 명령어**

### Docker 정리
```bash
# 사용하지 않는 이미지/컨테이너 정리
docker system prune -f

# 볼륨 정리 (주의!)
docker volume prune
```

### Git 상태 확인
```bash
# 현재 브랜치와 상태
git status

# 최근 커밋 로그
git log --oneline -5
```

---

## 🎯 **핵심 워크플로우**

1. **개발**: 로컬에서 새 서비스 추가
2. **커밋**: Git으로 코드 관리
3. **배포**: 서버에서 `git pull` → `./scripts/deploy.sh deploy`
4. **관리**: `./scripts/deploy.sh [action] [service]`

**목표**: 한 번의 명령어로 모든 서비스 관리! 🚀 