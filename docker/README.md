# 🚀 통합 서비스 관리 시스템

Docker 기반의 확장 가능한 서비스 관리 플랫폼입니다.

## 📋 **지원 서비스**

- **🌐 Traefik** - 리버스 프록시 & SSL 관리  
- **☁️ Nextcloud** - 클라우드 스토리지 & 협업  
- **⚡ FastAPI** - 백엔드 API 서버  
- **🔴 Redis** - 인메모리 캐시 & 세션  
- **🐘 PostgreSQL** - 관계형 데이터베이스  
- **🔍 Qdrant** - 벡터 데이터베이스  

## 🛠️ **설치 & 초기 설정**

### 1. 환경 설정

```bash
# 환경변수 파일 생성
cp .env.example .env

# 필수 설정 편집
nano .env
```

### 2. DNS 설정 (Nextcloud용)

**Cloudflare DNS:**
- Type: `A`  
- Name: `your-domain.com` 또는 `nextcloud`  
- Value: `서버IP`  
- **Proxy Status: DNS Only (중요!)**

### 3. 전체 배포

```bash
# 모든 설정된 서비스 배포
./scripts/deploy.sh deploy
```

## 🎮 **서비스 관리**

### 기본 명령어

```bash
# 사용법 확인
./scripts/deploy.sh

# 서비스 목록 확인
./scripts/deploy.sh list

# 모든 서비스 시작
./scripts/deploy.sh start all

# 특정 서비스 시작
./scripts/deploy.sh start nextcloud

# 서비스 상태 확인
./scripts/deploy.sh status all

# 로그 확인
./scripts/deploy.sh logs nextcloud

# 서비스 재시작
./scripts/deploy.sh restart traefik

# 서비스 정지
./scripts/deploy.sh stop all
```

### 확장 가능한 구조

```
.
├── scripts/
│   └── deploy.sh               # 통합 관리 스크립트
├── docker/
│   ├── docker-compose.yml     # 기본 서비스 (Traefik + Nextcloud)
│   ├── .env                   # 환경변수
│   ├── fastapi/
│   │   └── docker-compose.fastapi.yml    # FastAPI 서비스
│   ├── redis/
│   │   └── docker-compose.redis.yml      # Redis 서비스
│   ├── postgres/
│   │   └── docker-compose.postgres.yml   # PostgreSQL 서비스
│   └── qdrant/
│       └── docker-compose.qdrant.yml     # Qdrant 서비스
```

## 🌟 **새 서비스 추가하기**

### 1. Compose 파일 생성

```bash
mkdir docker/myservice
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

`scripts/deploy.sh` 파일의 다음 섹션들을 수정:

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

### 3. 서비스 배포

```bash
./scripts/deploy.sh start myservice
```

## 🔧 **환경변수 설정**

```bash
# Nextcloud 설정
NEXTCLOUD_DOMAIN=nextcloud.yourdomain.com
ACME_EMAIL=your-email@example.com
SKIP_DOMAIN_VALIDATION=false

# FastAPI 설정 (추가시)
FASTAPI_PORT=8000
FASTAPI_SECRET_KEY=your-secret-key

# 데이터베이스 설정 (추가시)
POSTGRES_DB=myapp
POSTGRES_USER=myuser
POSTGRES_PASSWORD=mypassword
```

## 📱 **서비스 접속**

### Nextcloud
- **관리자 패널**: `https://your-domain.com:8080`
- **메인 앱**: `https://your-domain.com`

### Traefik
- **Dashboard**: `http://서버IP:9090`

### 기타 서비스
설정에 따라 하위 도메인 또는 포트로 접속

## 🔍 **문제 해결**

### 일반적인 문제들

```bash
# 상태 확인
./scripts/deploy.sh status all

# 로그 확인
./scripts/deploy.sh logs nextcloud

# 네트워크 문제
docker network ls
docker network inspect web

# 서비스 재시작
./scripts/deploy.sh restart all
```

### Nextcloud 문제

1. **도메인 접근 불가**
   - DNS 전파 확인 (최대 24시간)
   - Cloudflare Proxy 비활성화 확인

2. **SSL 인증서 오류**
   - Let's Encrypt 로그 확인
   - HTTP 챌린지 접근 가능 확인

3. **모바일 앱 연결 안됨**
   - 도메인 설정 정확한지 확인
   - AIO 관리자 패널에서 Nextcloud 설정 완료 확인

## 🚀 **성능 최적화**

### 자동 업데이트 (Watchtower)

```bash
docker run -d \
  --name watchtower \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower
```

### 백업 자동화

```bash
# Crontab에 추가
0 2 * * * /path/to/backup-script.sh
```

## 📚 **참고 자료**

- [Nextcloud AIO 공식 문서](https://github.com/nextcloud/all-in-one)
- [Traefik 공식 문서](https://doc.traefik.io/traefik/)
- [Docker Compose 가이드](https://docs.docker.com/compose/)

---

**🎯 목표:** 하나의 명령어로 모든 서비스를 관리하고, 새로운 서비스를 쉽게 추가할 수 있는 확장 가능한 인프라! 