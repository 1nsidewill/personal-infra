# 🚀 Personal Infrastructure 배포 가이드

## 📋 사전 요구사항

### 필수 소프트웨어 설치
```bash
# Docker & Docker Compose 설치 확인
docker --version
docker-compose --version

# 없다면 설치
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

## 🔧 초기 설정 (최초 1회만)

### 1. 리포지토리 클론
```bash
git clone <your-repo-url> personal-infra
cd personal-infra
```

### 2. 환경변수 설정
```bash
# .env 파일 생성
cp .env.example .env

# 실제 패스워드로 변경 (매우 중요!)
nano .env
```

**⚠️ 중요: .env 파일에서 다음 값들을 실제 값으로 변경하세요:**
- `POSTGRES_PASSWORD`: 강력한 패스워드
- `NEXTCLOUD_DB_PASSWORD`: Nextcloud DB 패스워드  
- `NEXTCLOUD_ADMIN_PASSWORD`: Nextcloud 관리자 패스워드
- `SAMBA_PASSWORD`: Samba 접근 패스워드
- `NEXTCLOUD_DOMAIN`: 실제 도메인 (예: cloud.yourdomain.com)
- `ACME_EMAIL`: SSL 인증서용 실제 이메일

### 3. 권한 설정
```bash
# 스크립트 실행 권한 부여
chmod +x scripts/*.sh

# Traefik acme.json 권한 설정
chmod 600 docker/traefik/acme.json
```

### 4. Docker 네트워크 생성
```bash
# 필수 네트워크 생성
docker network create web 2>/dev/null || echo "web network exists"
docker network create backend 2>/dev/null || echo "backend network exists"
```

## 🚀 배포 실행

### 방법 1: 자동 스크립트 (권장)
```bash
# 개발 환경 (로컬 테스트용)
./scripts/deploy.sh dev

# 프로덕션 환경 (모든 서비스 포함)  
./scripts/deploy.sh prod

# 개별 서비스만 배포
./scripts/deploy.sh nextcloud
./scripts/deploy.sh samba
```

### 방법 2: 수동 배포
```bash
# 1. 기본 서비스 (Traefik, PostgreSQL, Redis, Qdrant)
cd docker
docker-compose up -d

# 2. Nextcloud 추가
docker-compose -f nextcloud/docker-compose.nextcloud.yml up -d

# 3. Samba 추가  
docker-compose -f samba/docker-compose.samba.yml up -d
```

## 📊 배포 확인

### 서비스 상태 확인
```bash
# 실행 중인 컨테이너 확인
docker ps

# 로그 확인
docker-compose logs -f
```

### 서비스 접근 테스트
- **Traefik Dashboard**: http://localhost:8080
- **PostgreSQL**: localhost:5432 (DB 클라이언트로 접속)
- **Redis**: localhost:6379 
- **Qdrant**: localhost:6333
- **Nextcloud**: http://localhost (또는 설정한 도메인)
- **Samba**: `\\localhost` 또는 `\\서버IP` (Windows에서)

## 🔐 최초 접속 정보

### Nextcloud
- URL: http://localhost (또는 설정한 도메인)
- 관리자 계정: `.env`의 `NEXTCLOUD_ADMIN_USER` / `NEXTCLOUD_ADMIN_PASSWORD`

### Samba 파일 공유
- Windows: `\\localhost` 또는 `\\서버IP`  
- 계정: `.env`의 `SAMBA_USER` / `SAMBA_PASSWORD`
- 공유폴더: `nas`

### PostgreSQL
- Host: localhost:5432
- User: postgres  
- Password: `.env`의 `POSTGRES_PASSWORD`
- Database: mydb

## 🛠️ 문제 해결

### 일반적인 문제들

1. **포트 충돌**
```bash
# 사용 중인 포트 확인
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

2. **권한 문제**
```bash
# Docker 권한 확인
sudo usermod -aG docker $USER
newgrp docker
```

3. **서비스가 시작되지 않을 때**
```bash
# 상세 로그 확인
docker-compose logs 서비스명

# 컨테이너 재시작
docker-compose restart 서비스명
```

4. **데이터 초기화** (주의!)
```bash
# 모든 데이터 삭제하고 재시작
docker-compose down -v
sudo rm -rf data/*
./scripts/deploy.sh prod
```

## 📁 디렉토리 용도

- `data/`: 데이터베이스 파일들 (백업 필수!)
- `nas/media/`: 미디어 파일 저장소  
- `nas/samples/`: 샘플 파일들
- `docker/traefik/acme.json`: SSL 인증서 (백업 권장)

## 🔄 백업

```bash
# 전체 백업 실행
./scripts/backup.sh

# 백업 파일 위치: /backup/
```

## 🌐 도메인 연결 (프로덕션)

1. DNS A 레코드 설정: `yourdomain.com` → `서버IP`
2. `.env`에서 `NEXTCLOUD_DOMAIN=yourdomain.com` 설정
3. 서비스 재시작: `docker-compose restart`

## 🔧 성능 최적화 (선택사항)

```bash
# 시스템 리소스 모니터링
docker stats

# 로그 크기 제한 설정
echo '{"log-driver": "json-file", "log-opts": {"max-size": "10m", "max-file": "3"}}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
``` 