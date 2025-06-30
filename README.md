# 🏠 Personal Infrastructure

완전한 Docker 기반 개인 인프라 솔루션 - 성공적으로 구축 및 운영 중! 🎉

## ✅ 구축 완료 상태

### 🔒 **보안 등급: A+**
- 모든 Nextcloud 보안 검사 통과
- HSTS, CSP, XSS 보호 등 완벽한 보안 헤더 적용
- Traefik 리버스 프록시를 통한 SSL/TLS 자동 관리

### 🚀 **운영 중인 서비스**
| 서비스 | 포트 | 상태 | 설명 |
|--------|------|------|------|
| **Traefik** | 80, 443, 8080 | ✅ 실행중 | 리버스 프록시 & SSL 관리 |
| **Nextcloud** | - | ✅ 실행중 | 클라우드 스토리지 & 파일 공유 |
| **PostgreSQL** | 5432 | ✅ 실행중 | 메인 데이터베이스 |
| **Redis** | 6379 | ✅ 실행중 | 캐시 & 세션 관리 |
| **SMB/CIFS** | 139, 445 | 🚧 추가중 | 파일 공유 (Mac/Windows) |

## 📁 디렉토리 구조

```
personal-infra/
├── 📦 docker-compose.yml          # 메인 서비스 구성
├── 🚀 deploy.sh                   # 자동 배포 스크립트
├── 📖 README.md                   # 이 파일
├── 🐳 docker/                     # Docker 설정들
│   └── traefik/                   # Traefik 설정 & SSL 인증서
│       ├── acme.json              # SSL 인증서 저장소
│       └── dynamic/               # 동적 설정 (보안 헤더)
├── 💾 data/                       # 서비스 데이터 (자동 생성)
│   ├── nextcloud/                 # Nextcloud 앱 & 설정
│   ├── postgres/                  # PostgreSQL 데이터
│   └── redis/                     # Redis 데이터
└── 🗄️ nas/                        # NAS 스토리지 마운트
    ├── photos/                    # 사진 (Nextcloud 스트리밍)
    ├── videos/                    # 동영상 (Nextcloud 스트리밍)
    ├── media-samples/             # 미디어 샘플 (SMB 공유)
    └── projects/                  # 프로젝트 파일 (SMB + Nextcloud)
```

## 🗄️ 스토리지 구성

### 💿 **10.9TB NAS 스토리지**
- **포맷**: ext4 (Linux 최적화)
- **마운트**: `/mnt/nas-storage`
- **용도별 디렉토리**:
  ```
  /mnt/nas-storage/
  ├── 📸 photos/           # Nextcloud WebDAV 스트리밍
  ├── 🎬 videos/           # Nextcloud WebDAV 스트리밍  
  ├── 🎵 media-samples/    # SMB 공유 (Mac/Windows 접근)
  └── 📁 projects/         # SMB + Nextcloud 중첩 공유
  ```

### 🔄 **이중 접근 방식**
- **Nextcloud (WebDAV)**: 웹 브라우저, 모바일 앱을 통한 스트리밍
- **SMB/CIFS**: Mac Finder, Windows 탐색기에서 직접 접근
- **중첩 공유**: 프로젝트 파일은 Nextcloud 링크 공유도 가능

## 🚀 빠른 시작

### 1. 서비스 시작
```bash
# 모든 서비스 시작
./deploy.sh

# 또는 직접 실행
docker compose up -d
```

### 2. 접속 정보
- **Nextcloud**: `https://your-domain` 또는 `http://localhost`
- **Traefik Dashboard**: `http://localhost:8080`
- **기본 계정**: `admin / changeme`

### 3. SMB 공유 접근
```bash
# Mac에서
smb://your-server-ip/media-samples
smb://your-server-ip/projects

# Windows에서  
\\your-server-ip\media-samples
\\your-server-ip\projects
```

## 🔧 관리 명령어

### 📊 상태 확인
```bash
# 모든 컨테이너 상태
docker ps

# 특정 서비스 로그
docker logs nextcloud
docker logs traefik
```

### 🔄 서비스 관리
```bash
# 재시작
docker compose restart

# 정지
docker compose down

# 업데이트 후 재빌드
docker compose up -d --build
```

### 🛠️ Nextcloud 관리
```bash
# OCC 명령어 실행
docker exec -it nextcloud su -s /bin/bash www-data -c "php /var/www/html/occ status"

# 데이터베이스 최적화
docker exec -it nextcloud su -s /bin/bash www-data -c "php /var/www/html/occ db:add-missing-indices"
```

## 📈 모니터링 & 로그

### 📊 **성능 지표**
- Traefik Dashboard에서 실시간 트래픽 모니터링
- Nextcloud 관리자 페이지에서 시스템 상태 확인

### 📝 **로그 위치**
```bash
# Docker 로그
docker logs [container-name]

# Nextcloud 로그
docker exec nextcloud tail -f /var/www/html/data/nextcloud.log

# Traefik 로그  
docker logs traefik
```

## 🔮 향후 확장 계획

### 🐍 **FastAPI 백엔드 추가**
- API 서버 컨테이너 추가 예정
- 자동화 스크립트 및 웹훅 지원

### 📊 **모니터링 스택**
- Prometheus + Grafana 대시보드
- 알림 시스템 (Discord/Slack)

### 🔒 **보안 강화**
- Fail2ban 컨테이너 추가
- VPN 서버 통합 (WireGuard)

## 🆘 트러블슈팅

### 🚨 **일반적인 문제들**

#### 서비스가 시작되지 않을 때
```bash
# 네트워크 확인
docker network ls
docker network create web 2>/dev/null

# 포트 충돌 확인
ss -tulpn | grep -E ':(80|443|8080)'
```

#### Nextcloud 접속 오류
```bash
# config.php 문법 검사
docker exec nextcloud php -l /var/www/html/config/config.php

# 권한 수정
docker exec nextcloud chown -R www-data:www-data /var/www/html
```

#### SSL 인증서 문제
```bash
# 인증서 상태 확인
docker exec traefik ls -la /letsencrypt/

# Traefik 재시작
docker compose restart traefik
```

## 📞 지원 & 문의

- **이슈 리포팅**: GitHub Issues
- **문서**: 이 README 파일
- **커뮤니티**: Docker, Nextcloud 공식 문서

---

**✨ 완벽하게 구축된 개인 인프라에서 안전하고 편리한 클라우드 생활을 즐기세요! ✨**
