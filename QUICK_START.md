# 🚀 빠른 시작 가이드

완전한 Docker 기반 개인 인프라를 **5분 안에** 구축하세요!

## 📋 사전 준비사항

✅ Ubuntu 20.04+ 서버  
✅ Docker & Docker Compose 설치  
✅ 10.9TB 외장 디스크 연결 (`/dev/sda`)  
✅ 루트 권한 또는 sudo 권한  

## ⚡ 초고속 설치 (서버에서 실행)

### 1️⃣ 프로젝트 다운로드
```bash
# 프로젝트 클론
git clone <your-repo-url> /srv/personal-infra
cd /srv/personal-infra

# 또는 파일 업로드 후
cd /srv/personal-infra
```

### 2️⃣ 스토리지 설정 (⚠️ 데이터 삭제됨)
```bash
# NAS 디스크 포맷 및 마운트 (10.9TB)
sudo ./scripts/setup-storage.sh --format

# 상태 확인
sudo ./scripts/setup-storage.sh --status
```

### 3️⃣ 환경변수 설정
```bash
# .env 파일 수정 (선택사항, 기본값 사용 가능)
nano .env

# 주요 변경사항:
# - NEXTCLOUD_DOMAIN: 실제 도메인 (예: cloud.yourdomain.com)
# - 각종 패스워드들 (보안을 위해 변경 권장)
```

### 4️⃣ 전체 서비스 배포
```bash
# 🚀 원클릭 배포!
./deploy.sh

# 배포 완료 후 상태 확인
./deploy.sh --status
```

## 🎉 완료! 접속 정보

### 🌐 웹 서비스
- **Nextcloud**: `http://your-server-ip` 
- **Traefik Dashboard**: `http://your-server-ip:8080`
- **기본 계정**: `admin` / `changeme`

### 📁 SMB 파일 공유
- **Mac**: `⌘+K` → `smb://your-server-ip/media-samples`
- **Windows**: `Win+R` → `\\your-server-ip\media-samples`
- **계정**: `smbuser` / `changeme`

## 📊 상태 확인 & 관리

```bash
# 서비스 상태 확인
./deploy.sh --status

# 로그 확인
./deploy.sh --logs nextcloud

# 헬스체크
./deploy.sh --health-check

# 백업
./deploy.sh --backup

# 업데이트
./deploy.sh --update
```

## 🗄️ 스토리지 구조

```
/mnt/nas-storage/          # 10.9TB NAS 디스크
├── 📸 photos/             # 사진 (Nextcloud 스트리밍)
├── 🎬 videos/             # 동영상 (Nextcloud 스트리밍)
├── 🎵 media-samples/      # 미디어 샘플 (SMB 공유)
└── 📁 projects/           # 프로젝트 파일 (SMB + Nextcloud)
```

### 🔄 이중 접근 방식
- **Nextcloud**: 웹 브라우저, 모바일 앱, 링크 공유
- **SMB**: Mac Finder, Windows 탐색기에서 직접 접근

## 🔧 개별 서비스 관리

### 코어 서비스만 배포
```bash
./deploy.sh --core
```

### SMB만 배포
```bash
./deploy.sh --smb
```

### 서비스 중지
```bash
./deploy.sh --down
```

## 🆘 문제 해결

### 서비스가 시작되지 않을 때
```bash
# Docker 상태 확인
docker ps -a

# 네트워크 확인
docker network ls
docker network create web  # 필요시

# 로그 확인
./deploy.sh --logs
```

### 디스크 마운트 문제
```bash
# 마운트 상태 확인
df -h
lsblk

# 수동 마운트
sudo mount /dev/sda1 /mnt/nas-storage

# 스토리지 재설정
sudo ./scripts/setup-storage.sh --mount-only
```

### Nextcloud 접속 오류
```bash
# 컨테이너 재시작
docker compose restart nextcloud

# config.php 문법 확인
docker exec nextcloud php -l /var/www/html/config/config.php

# 권한 수정
docker exec nextcloud chown -R www-data:www-data /var/www/html
```

## 🔒 보안 강화 (운영 환경)

### 1. 패스워드 변경
```bash
# .env 파일의 모든 패스워드 변경
nano .env

# 서비스 재시작으로 적용
./deploy.sh --update
```

### 2. 방화벽 설정
```bash
# 필요한 포트만 개방
sudo ufw allow 22,80,443,139,445/tcp
sudo ufw enable
```

### 3. 도메인 연결
```bash
# DNS A 레코드: yourdomain.com → 서버IP
# .env에서 NEXTCLOUD_DOMAIN 변경
nano .env

# 서비스 재시작
./deploy.sh --update
```

## 📈 향후 확장

### FastAPI 백엔드 추가 (예정)
```bash
# API 서버 배포 (향후 지원)
./deploy.sh --api
```

### 모니터링 대시보드 (예정)
```bash
# Grafana + Prometheus 배포 (향후 지원)
./deploy.sh --monitoring
```

---

## 🎊 축하합니다!

**완전한 개인 클라우드 인프라가 구축되었습니다!**

- ✅ **보안**: A+ 등급 보안 설정
- ✅ **성능**: 최적화된 데이터베이스 & 캐시
- ✅ **편의성**: 웹 + SMB 이중 접근
- ✅ **확장성**: 모듈식 구조로 쉬운 확장

**🏠 이제 당신만의 프라이빗 클라우드를 마음껏 활용하세요! ✨** 