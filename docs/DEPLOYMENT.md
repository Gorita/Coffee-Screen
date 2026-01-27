# 배포 가이드

## 개요

Coffee-Screen은 **Direct Distribution** 방식으로 배포됩니다.
현재는 서명 없이 배포하며, 사용자가 처음 실행 시 Gatekeeper 허용이 필요합니다.

## 릴리스 방법

### 빠른 릴리스

```bash
./scripts/release.sh
```

이 스크립트는 다음을 수행합니다:
1. Xcode 프로젝트 생성 (XcodeGen)
2. Release 빌드
3. DMG 파일 생성

### 단계별 실행

```bash
# 1. 빌드만
./scripts/build.sh

# 2. DMG 생성
./scripts/create-dmg.sh
```

## 출력물

빌드 완료 후 `build/` 디렉토리:

```
build/
├── DerivedData/               # Xcode 빌드 캐시
├── export/
│   └── Coffee-Screen.app      # 빌드된 앱
└── Coffee-Screen-1.0.0.dmg    # 배포용 DMG
```

## GitHub Release 생성

```bash
# 버전 태그 생성
git tag v1.0.0
git push origin v1.0.0

# GitHub Release 생성 및 DMG 업로드
gh release create v1.0.0 ./build/Coffee-Screen-1.0.0.dmg \
  --title "Coffee-Screen v1.0.0" \
  --notes "릴리스 노트 내용"
```

## 사용자 설치 안내

서명되지 않은 앱이므로 사용자에게 다음 안내가 필요합니다:

### 설치 방법
1. DMG 파일 열기
2. Coffee-Screen.app을 Applications 폴더로 드래그

### 첫 실행 시
앱을 처음 열면 다음 경고가 표시됩니다:
> "Coffee-Screen"은(는) Apple에서 확인할 수 없는 개발자가 만든 앱이기 때문에 열 수 없습니다.

**해결 방법**:
1. 앱을 **우클릭** → **열기** 선택
2. "열기" 버튼 클릭

또는:
1. **시스템 설정** → **개인정보 보호 및 보안**
2. 하단의 "확인 없이 열기" 클릭

## 버전 관리

버전 변경 시 `project.yml` 수정:

```yaml
settings:
  base:
    MARKETING_VERSION: "1.1.0"    # 사용자 표시 버전
    CURRENT_PROJECT_VERSION: "2"   # 빌드 번호
```

변경 후 프로젝트 재생성:
```bash
xcodegen generate
```

## 향후 서명 배포

Apple Developer Program 가입 후 서명된 배포를 원하면:
1. Developer ID Application 인증서 생성
2. `scripts/build.sh`에서 서명 옵션 활성화
3. 공증(Notarization) 스크립트 추가

서명된 앱은 Gatekeeper 경고 없이 실행됩니다.
