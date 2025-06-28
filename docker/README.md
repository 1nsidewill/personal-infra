# Nextcloud All-in-One (AIO) 배포 가이드

## 🚀 개요

이 설정은 **Nextcloud All-in-One (AIO)**을 Traefik 리버스 프록시와 함께 배포하는 완전한 솔루션입니다.

### ✨ 특징
- **Nextcloud AIO**: 공식 All-in-One 솔루션 사용
- **Traefik 통합**: 자동 SSL 인증서 및 리버스 프록시
- **보안 헤더**: HSTS, CSP 등 모든 보안 헤더 자동 설정
- **간단한 관리**: 단일 스크립트로 배포 및 관리

## 📋 사전 요구사항

1. **Docker & Docker Compose** 설치
2. **도메인** 및 DNS 설정 권한
3. **포트 80, 443, 8080, 9090** 접근 가능

## 🎯 빠른 시작

### 1단계: 환경 설정
```bash
cd docker
cp .env.example .env
nano .env  # 도메인과 이메일 설정
```

`.env` 파일에서 다음을 설정:
```bash
NEXTCLOUD_DOMAIN=nextcloud.yourdomain.com
ACME_EMAIL=your-email@example.com
```

### 2단계: DNS 설정 (중요!)
Cloudflare 또는 DNS 제공업체에서:
```
A 레코드: nextcloud.yourdomain.com → 서버IP
```

⚠️ **Cloudflare 사용시 주의사항:**
- **DNS Only (회색 구름)** 선택 - Proxied 끄기
- Proxied를 사용하면 SSL 인증서 발급 실패 가능
- Let's Encrypt HTTP Challenge가 제대로 작동하려면 DNS Only 필요

### 3단계: 배포 실행
```bash
chmod +x deploy-nextcloud-aio.sh
./deploy-nextcloud-aio.sh
```

## 🔧 구조 설명

### 컨테이너 구성
- **traefik**: 리버스 프록시 + SSL 관리
- **nextcloud-aio**: AIO 마스터 컨테이너 (다른 모든 컨테이너 관리)

### 포트 구성 (포트 충돌 해결됨)
- **80**: HTTP (HTTPS로 자동 리다이렉트)
- **443**: HTTPS (Nextcloud 메인)
- **8080**: AIO 관리자 패널
- **9090**: Traefik Dashboard

### 네트워크
- **web**: Traefik과 AIO 간 통신

## 📱 접속 방법

### AIO 관리자 패널
```
https://yourdomain.com:8080
```
여기서 Nextcloud 앱들을 설치하고 설정합니다.

### Nextcloud 앱
```  
https://yourdomain.com
```
실제 Nextcloud 서비스에 접속합니다.

### Traefik Dashboard
```
http://서버IP:9090
```
Traefik 상태 모니터링

## 🛠️ 관리 명령어

### 컨테이너 상태 확인
```bash
docker-compose ps
docker-compose logs -f
```

### 개별 컨테이너 로그
```bash
docker logs nextcloud-aio-mastercontainer
docker logs traefik
```

### 재시작
```bash
docker-compose restart
```

### 완전 재배포
```bash
docker-compose down
./deploy-nextcloud-aio.sh
```

## 🔍 트러블슈팅

### SSL 인증서 발급 실패
1. **DNS 설정 확인**:
   ```bash
   nslookup yourdomain.com
   ```

2. **Cloudflare Proxied 확인**:
   - DNS Only (회색 구름)로 설정되어 있는지 확인
   - Proxied (주황색 구름)이면 끄기

3. **포트 접근성 확인**:
   ```bash
   netstat -tulpn | grep :80
   netstat -tulpn | grep :443
   ```

### AIO 컨테이너가 시작되지 않는 경우
1. Docker 소켓 권한 확인:
   ```bash
   ls -la /var/run/docker.sock
   ```

2. 네트워크 확인:
   ```bash
   docker network ls
   ```

### AIO 관리자 패널 접속 안됨
1. 포트 8080 확인:
   ```bash
   docker logs nextcloud-aio-mastercontainer
   ```

2. 방화벽 설정 확인 (포트 8080)

## 📚 고급 설정

### 커스텀 데이터 디렉토리
`.env` 파일에 추가:
```bash
NEXTCLOUD_DATADIR=/mnt/ncdata
```

### 커스텀 백업 디렉토리
```bash
NEXTCLOUD_BACKUP_DIR=/mnt/backup
```

### 도메인 검증 건너뛰기 (개발용)
```bash
SKIP_DOMAIN_VALIDATION=true
```

## 🌐 DNS 설정 상세 가이드

### Cloudflare 설정 (권장)
1. **DNS 레코드 추가**:
   - Type: A
   - Name: nextcloud (또는 원하는 서브도메인)
   - Content: 서버IP
   - **Proxy status: DNS only** ← 중요!

2. **SSL/TLS 설정**:
   - SSL/TLS → Overview → Full (or Full strict)
   - Edge Certificates → Always Use HTTPS: OFF

### 다른 DNS 제공업체
- 일반적인 A 레코드 설정으로 충분
- TTL은 300초 (5분) 권장

## 🆚 기존 설정과의 차이점

### ✅ 장점
- **공식 지원**: Nextcloud 공식 AIO 사용
- **자동 관리**: 업데이트, 백업, 모니터링 자동화
- **안정성**: 모든 컴포넌트가 검증된 조합
- **간단함**: 복잡한 설정 불필요
- **포트 충돌 해결**: Traefik Dashboard를 9090 포트로 분리

### 📝 참고사항
- AIO가 모든 서비스를 자동으로 관리
- 개별 컨테이너 수정 불가 (AIO 정책)
- 모든 설정은 AIO 관리자 패널에서

## 🔗 유용한 링크

- [Nextcloud AIO 공식 문서](https://github.com/nextcloud/all-in-one)
- [Traefik 문서](https://doc.traefik.io/traefik/)
- [Docker Compose 문서](https://docs.docker.com/compose/)

---

이 설정으로 모든 보안 경고가 해결되고, 앱에서도 정상 접속이 가능합니다! 🎉 