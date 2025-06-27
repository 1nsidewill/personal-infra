# Personal Infrastructure

Docker 기반 개인 인프라 구성을 위한 프로젝트입니다.

## 구조

```
personal-infra/
├── README.md
├── .gitignore
├── docker/                        # Docker 설정 파일들
│   ├── docker-compose.yml         # 메인 서비스 (Traefik, PostgreSQL, Redis, Qdrant)
│   ├── traefik/                   # Traefik 리버스 프록시 설정
│   │   ├── traefik.yml
│   │   └── acme.json              # SSL 인증서 저장
│   ├── nextcloud/                 # Nextcloud 파일 서버
│   │   └── docker-compose.nextcloud.yml
│   ├── samba/                     # Samba 파일 공유
│   │   └── docker-compose.samba.yml
│   └── fastapi-template/          # FastAPI 템플릿 (선택사항)
├── data/                          # 데이터베이스 볼륨
│   ├── postgres/
│   ├── redis/
│   └── qdrant/
├── nas/                           # NAS 스토리지
│   ├── media/
│   └── samples/
└── scripts/                       # 운영 스크립트
    ├── backup.sh                  # 백업 스크립트
    └── deploy.sh                  # 배포 스크립트
```

## 주요 서비스

- **Traefik**: 리버스 프록시 & 로드 밸런서 (자동 SSL)
- **PostgreSQL**: 메인 데이터베이스
- **Redis**: 캐시 & 세션 스토어
- **Qdrant**: 벡터 데이터베이스
- **Nextcloud**: 개인 클라우드 파일 서버
- **Samba**: 네트워크 파일 공유

## 빠른 시작

### 1. 환경 설정

```bash
# .env 파일 생성 (필요한 환경변수 설정)
cp .env.example .env
```

### 2. 네트워크 생성

```bash
docker network create web
docker network create backend
```

### 3. 배포

```bash
# 개발 환경 전체 배포
./scripts/deploy.sh dev

# 프로덕션 환경 전체 배포
./scripts/deploy.sh prod

# 개별 서비스 배포
./scripts/deploy.sh nextcloud
./scripts/deploy.sh samba
```

### 4. 서비스 접근

- Traefik Dashboard: http://localhost:8080
- Nextcloud: https://nextcloud.yourdomain.com (또는 localhost)
- PostgreSQL: localhost:5432
- Redis: localhost:6379
- Qdrant: localhost:6333

## 환경 변수

`.env` 파일에서 다음 변수들을 설정하세요:

```env
# Database
POSTGRES_PASSWORD=your_secure_password

# Nextcloud
NEXTCLOUD_DB_PASSWORD=nextcloud_db_password
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=admin_password
NEXTCLOUD_DOMAIN=nextcloud.yourdomain.com

# Samba
SAMBA_USER=admin
SAMBA_PASSWORD=samba_password
SAMBA_WORKGROUP=WORKGROUP
```

## 백업

```bash
# 전체 백업 실행
./scripts/backup.sh
```

백업 파일은 `/backup` 디렉토리에 저장되며, 7일 이상 된 백업은 자동으로 삭제됩니다.

## 개발 가이드

### FastAPI 템플릿 사용

`docker/fastapi-template/` 디렉토리에서 FastAPI 애플리케이션 개발을 시작할 수 있습니다.

### 서비스 추가

새로운 서비스를 추가하려면:

1. `docker/your-service/` 디렉토리 생성
2. `docker-compose.your-service.yml` 파일 작성
3. `scripts/deploy.sh`에 배포 옵션 추가

## 문제 해결

### 로그 확인

```bash
# 모든 서비스 로그
docker-compose logs -f

# 특정 서비스 로그
docker-compose logs -f traefik
```

### 컨테이너 상태 확인

```bash
docker ps
docker-compose ps
```

### 데이터 초기화

```bash
# 주의: 모든 데이터가 삭제됩니다!
docker-compose down -v
sudo rm -rf data/*
```

## 보안 주의사항

1. 프로덕션 환경에서는 기본 패스워드를 변경하세요
2. `acme.json` 파일 권한을 600으로 설정하세요
3. 방화벽 설정을 확인하세요
4. 정기적으로 백업을 수행하세요
