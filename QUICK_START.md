# 🚀 Personal Infrastructure - 빠른 시작

## ⚡ 즉시 배포 (기본 설정)

```bash
# Git pull
git pull

# 바로 배포! (.env 파일 없이도 동작)
./scripts/deploy.sh prod
```

## 🔐 기본 접속 정보

### Nextcloud (개인 클라우드)
- **URL**: http://localhost
- **관리자 계정**: `admin` / `changeme`

### 데이터베이스들
- **PostgreSQL**: localhost:5432 (`postgres` / `changeme`)
- **Redis**: localhost:6379 (패스워드 없음)
- **Qdrant**: localhost:6333 (패스워드 없음)

### 기타 서비스
- **Traefik 대시보드**: http://localhost:8080
- **Samba 파일공유**: `\\localhost` (`admin` / `changeme`)

## 🛡️ 보안 강화 (선택사항)

### 1. 커스텀 패스워드 설정
```bash
# .env 파일 생성
cp .env.example .env

# 원하는 패스워드로 변경
nano .env
```

### 2. 서비스 재시작
```bash
docker-compose down
./scripts/deploy.sh prod
```

## 📊 상태 확인

```bash
# 모든 컨테이너 확인
docker ps

# 로그 확인
docker-compose logs -f

# 특정 서비스 로그
docker-compose logs -f nextcloud
```

## 🔄 서비스 관리

```bash
# 전체 중지
docker-compose down

# 전체 재시작  
./scripts/deploy.sh prod

# 개별 서비스만
./scripts/deploy.sh nextcloud
./scripts/deploy.sh samba
```

## 💾 데이터 위치

- **데이터베이스**: `./data/` 폴더
- **Nextcloud 파일**: Docker 볼륨 + `./nas/` 폴더
- **설정 파일**: `./docker/` 폴더

---

**💡 팁**: 첫 배포 후 http://localhost 접속해서 Nextcloud 초기 설정을 완료하세요! 