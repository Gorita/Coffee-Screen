# 릴리스 가이드 (Sparkle 자동 업데이트)

> 이 문서는 Sparkle을 통한 자동 업데이트 배포 절차를 다룹니다.
> 기본 빌드/DMG 생성은 [DEPLOYMENT.md](DEPLOYMENT.md)를 참고하세요.

## 개요

Coffee-Screen은 **Sparkle 프레임워크 + GitHub Releases**로 업데이트를 배포합니다.

- **appcast.xml**: 사용 가능한 버전 메타데이터 (URL, 버전, 서명)
- **.dmg**: 실제 업데이트 바이너리
- **EdDSA 서명**: 다운로드한 .dmg의 무결성을 사용자 앱이 검증

피드 URL: `https://github.com/Gorita/coffee-screen/releases/latest/download/appcast.xml`

이 URL은 항상 가장 최근 GitHub Release의 `appcast.xml` asset으로 redirect됩니다. 즉 매번 같은 URL을 쓰고, 새 릴리스에 `appcast.xml`을 asset으로 첨부하기만 하면 사용자는 자동으로 최신 정보를 받습니다.

## 사전 준비 (최초 한 번)

### 1. EdDSA 키 확인

```bash
~/Library/Developer/Xcode/DerivedData/CoffeeScreen-*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys -p
```

`-p` 옵션은 키체인에 저장된 public key를 출력합니다. 출력값이 `Info.plist`의 `SUPublicEDKey`와 일치해야 합니다.

키가 없거나 잃어버렸다면 [docs/DEPLOYMENT.md의 키 관리 섹션](DEPLOYMENT.md)을 참고하세요.

### 2. 두 번째 컴퓨터에서 빌드한다면

같은 private key를 두 컴퓨터에 공유해야 합니다.

**키 보유 컴퓨터에서 export:**

```bash
~/Library/Developer/Xcode/DerivedData/CoffeeScreen-*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys -x ~/Desktop/sparkle-key.txt
```

AirDrop / 1Password 등 **안전한 채널**로 전송 후 두 번째 컴퓨터에서 import:

```bash
~/Library/Developer/Xcode/DerivedData/CoffeeScreen-*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys -f ~/Desktop/sparkle-key.txt
```

양쪽 모두 전송 후 export 파일 안전 삭제:

```bash
rm -P ~/Desktop/sparkle-key.txt
```

## 릴리스 절차

### Step 1. 버전 업데이트

`project.yml`에서 버전 변경:

```yaml
settings:
  base:
    MARKETING_VERSION: "1.2.0"
    CURRENT_PROJECT_VERSION: "3"
```

XcodeGen 재생성:

```bash
xcodegen generate
```

### Step 2. 빌드 + DMG 생성

기존 스크립트 그대로 사용:

```bash
./scripts/release.sh
```

산출물: `build/Coffee-Screen-1.2.0.dmg`

### Step 3. appcast.xml 생성 (자동 서명 포함)

```bash
./scripts/generate-appcast.sh
```

- `build/` 안의 모든 `.dmg`/`.zip`을 스캔
- 키체인의 private key로 각 파일에 EdDSA 서명
- `build/appcast.xml` 생성/갱신

생성된 `appcast.xml`을 한 번 열어서 새 버전 항목이 들어갔는지 눈으로 확인하세요.

### Step 4. 릴리스 노트 작성

`appcast.xml`의 새 `<item>` 안 `<description>` 또는 `<sparkle:releaseNotesLink>`를 통해 사용자에게 표시할 내용을 작성합니다. `generate_appcast`는 기본적으로 빈 description을 만드니, 필요하면 수동 편집하거나 `build/release_notes/1.2.0.html` 파일을 두면 자동 포함됩니다.

### Step 5. GitHub Release 생성

```bash
git tag v1.2.0
git push origin v1.2.0

gh release create v1.2.0 \
  build/Coffee-Screen-1.2.0.dmg \
  build/appcast.xml \
  --title "Coffee-Screen v1.2.0" \
  --notes-file release-notes.md
```

**중요**: `.dmg`와 `appcast.xml` **둘 다** asset으로 업로드해야 합니다. `appcast.xml`이 빠지면 사용자 앱이 새 버전을 발견하지 못합니다.

### Step 6. 검증

이전 버전이 설치된 다른 컴퓨터(또는 일부러 다운그레이드한 환경)에서:

1. 메뉴바 아이콘 → **Check for Updates…**
2. "새 버전 1.2.0이 있습니다" 다이얼로그 확인
3. **Install Update** 클릭 → 자동 다운로드 / 검증 / 재시작 동작 확인

검증 실패 시:
- Console.app에서 `Sparkle` 키워드로 로그 검색
- `appcast.xml`의 `sparkle:edSignature` 값이 비어있는지 확인 (서명 누락 시 검증 실패)
- public key 불일치 — `Info.plist`의 `SUPublicEDKey`가 현재 키와 같은지 확인

## 주의사항

- **태그와 .dmg 버전을 일치시키세요**: `git tag v1.2.0`이라면 `MARKETING_VERSION`도 `1.2.0`이어야 합니다. 불일치 시 사용자가 혼란.
- **사전 릴리스/내부 테스트**: `gh release create --prerelease` 옵션을 쓰면 latest로 노출되지 않습니다. 다만 `releases/latest/download/appcast.xml`은 prerelease를 무시하므로 일반 사용자에게 영향 없음.
- **롤백**: 잘못된 릴리스를 배포했을 경우 GitHub Release를 삭제하면 latest가 그 이전 릴리스로 자동 복귀합니다. 다만 이미 업데이트를 받아 설치한 사용자에게는 영향 없음 (다운그레이드 안 됨).

## 자동화 아이디어 (선택)

- `scripts/release.sh`에 Step 3 통합 (`generate-appcast.sh` 자동 호출)
- GitHub Actions로 태그 push 시 빌드 → 서명 → release까지 자동화 (단, EdDSA private key를 Actions secret으로 관리해야 함 — 보안 검토 필요)
