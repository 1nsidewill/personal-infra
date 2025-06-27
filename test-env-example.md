# Docker Compose 환경변수 동작 예시

## 📝 현재 설정 분석

### docker-compose.yml 파일에서:
```yaml
environment:
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-changeme}
```

### 동작 방식:

#### 🔸 Case 1: .env 파일이 없는 경우
```yaml
# 결과적으로 이렇게 됨
environment:
  POSTGRES_PASSWORD: changeme
```

#### 🔸 Case 2: .env 파일에 값이 있는 경우
```bash
# .env 파일 내용
POSTGRES_PASSWORD=my_super_secret_password
```yaml
# 결과적으로 이렇게 됨  
environment:
  POSTGRES_PASSWORD: my_super_secret_password
```

## 🎯 실제 프로젝트 예시들

### 1. PostgreSQL
```yaml
POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-changeme}
```
- .env 없음 → `changeme`
- .env 있음 → 내가 설정한 값

### 2. Nextcloud  
```yaml
NEXTCLOUD_ADMIN_USER: ${NEXTCLOUD_ADMIN_USER:-admin}
NEXTCLOUD_ADMIN_PASSWORD: ${NEXTCLOUD_ADMIN_PASSWORD:-changeme}
NEXTCLOUD_DOMAIN: ${NEXTCLOUD_DOMAIN:-localhost}
```

### 3. Samba
```yaml
USER: ${SAMBA_USER:-admin};${SAMBA_PASSWORD:-changeme}
```

## 🔄 우선순위

1. **환경변수** (export로 설정)
2. **.env 파일**  
3. **기본값** (:-뒤의 값)

```bash
# 1순위: 시스템 환경변수
export POSTGRES_PASSWORD=system_password

# 2순위: .env 파일
echo "POSTGRES_PASSWORD=env_file_password" > .env

# 3순위: docker-compose.yml의 기본값
${POSTGRES_PASSWORD:-changeme}
``` 