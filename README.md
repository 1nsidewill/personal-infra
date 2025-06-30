# Personal Infrastructure

Docker를 이용한 개인 클라우드 인프라. Traefik + Nextcloud + PostgreSQL + Redis로 구성.

## 🏗️ 구조

```
personal-infra/
├── README.md
├── .env                    # 환경변수 설정
├── docker-compose.yml      # 전체 서비스 정의
├── docker/
│   └── traefik/
│       └── acme.json       # SSL 인증서 저장
├── data/                   # 데이터 저장소
│   ├── postgres/           # PostgreSQL 데이터
│   ├── redis/              # Redis 데이터
│   └── nextcloud/          # Nextcloud 파일
└── nas/
    └── media/              # NAS 스토리지
```

## 🚀 빠른 시작

### 1. 환경변수 설정
```bash
# .env 파일 수정
nano .env
```

**필수 변경사항:**
- `POSTGRES_PASSWORD`: 데이터베이스 패스워드
- `NEXTCLOUD_ADMIN_PASSWORD`: Nextcloud 관리자 패스워드
- `NEXTCLOUD_DOMAIN`: 도메인 (예: cloud.yourdomain.com)
- `ACME_EMAIL`: SSL 인증서용 이메일

### 2. Docker 네트워크 생성
```bash
docker network create web
```

### 3. SSL 인증서 파일 권한 설정
```bash
chmod 600 docker/traefik/acme.json
```

### 4. 서비스 시작
```bash
docker compose up -d
```

## 📊 서비스 접근

- **Nextcloud**: http://localhost (또는 설정한 도메인)
- **Traefik Dashboard**: http://localhost:8080
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## 🔐 기본 접속 정보

### Nextcloud
- **URL**: http://localhost
- **관리자**: `.env`의 `NEXTCLOUD_ADMIN_USER` / `NEXTCLOUD_ADMIN_PASSWORD`

### Database
- **PostgreSQL**: `nextcloud` / `.env`의 `POSTGRES_PASSWORD`
- **Redis**: 패스워드 없음

## 🛠️ 관리 명령어

### 서비스 관리
```bash
# 전체 시작
docker compose up -d

# 전체 중지
docker compose down

# 로그 확인
docker compose logs -f

# 특정 서비스 로그
docker compose logs -f nextcloud
```

### 상태 확인
```bash
# 컨테이너 상태
docker compose ps

# 시스템 리소스
docker stats
```

### 데이터 백업
```bash
# PostgreSQL 백업
docker exec postgres pg_dump -U nextcloud nextcloud > backup_$(date +%Y%m%d).sql

# Nextcloud 파일 백업
tar -czf nextcloud_files_$(date +%Y%m%d).tar.gz data/nextcloud/
```

## 🌐 도메인 연결 (프로덕션)

1. **DNS 설정**: A 레코드로 `yourdomain.com` → `서버IP`
2. **환경변수 수정**: `.env`에서 `NEXTCLOUD_DOMAIN=yourdomain.com`
3. **서비스 재시작**: `docker compose restart`

## 🔒 보안 강화

### 기본 패스워드 변경
- `.env` 파일의 모든 패스워드를 강력한 것으로 변경
- 특히 `POSTGRES_PASSWORD`와 `NEXTCLOUD_ADMIN_PASSWORD`

### 방화벽 설정
```bash
# 필요한 포트만 열기
ufw allow 80,443,22/tcp
```

### SSL 자동 갱신
Traefik이 Let's Encrypt로 자동 SSL 갱신을 처리합니다.

## 🐛 문제 해결

### 컨테이너가 시작되지 않을 때
```bash
# 상세 로그 확인
docker compose logs -f [service_name]

# 컨테이너 재시작
docker compose restart [service_name]
```

### 데이터 초기화 (주의!)
```bash
# 모든 데이터 삭제 후 재시작
docker compose down -v
sudo rm -rf data/*
docker compose up -d
```

### 권한 문제
```bash
# 데이터 폴더 권한 수정
sudo chown -R 33:33 data/nextcloud  # www-data 사용자
```

## 📝 참고사항

- **PostgreSQL**: Nextcloud 전용 데이터베이스
- **Redis**: 캐시 및 파일 잠금용
- **Traefik**: 자동 SSL + 리버스 프록시
- **Volume**: 모든 데이터는 `./data/` 폴더에 저장

---

**💡 Tip**: 첫 설정 후 http://localhost 접속해서 Nextcloud 초기 설정을 완료하세요!
