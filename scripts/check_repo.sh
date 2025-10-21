#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

red()   { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }

fail() { red "✗ $*"; exit 1; }
ok()   { green "✓ $*"; }

# 0) 필수 디렉토리
[[ -d "$ROOT/apps/base" ]] || fail "apps/base 가 없습니다."
[[ -d "$ROOT/overlays"   ]] || fail "overlays 가 없습니다."
[[ -d "$ROOT/bootstrap/argocd" ]] || yellow "bootstrap/argocd 없음(부트스트랩을 수동 적용한다면 OK)."

# 1) apps/base/kustomization.yaml에 모든 app/*.yaml 포함 여부
KUS="$ROOT/apps/base/kustomization.yaml"
[[ -f "$KUS" ]] || fail "apps/base/kustomization.yaml 이 없습니다."

mapfile -t APP_FILES < <(find "$ROOT/apps/base" -maxdepth 1 -type f -name '*.yaml' ! -name 'kustomization.yaml' | sort)
missing=0
for f in "${APP_FILES[@]}"; do
  rel="apps/base/$(basename "$f")"
  if ! grep -qE "[- ]\s*$(basename "$f")\s*$" "$KUS"; then
    red "  - 누락: $rel (kustomization.yaml resources에 없음)"
    missing=1
  fi
done
[[ $missing -eq 0 ]] && ok "apps/base/kustomization.yaml → 모든 파일 포함 OK" || fail "kustomization.yaml 에 누락 파일이 있습니다."

# 2) Application/Project 중복 이름 점검
dup_app=$(
  grep -R --include='*.yaml' -n 'kind: Application' "$ROOT/apps/base" 2>/dev/null \
  | cut -d: -f1 \
  | xargs -r -I{} yq -r '.metadata.name' {} \
  | sort | uniq -c | awk '$1>1{print}'
)
[[ -z "$dup_app" ]] && ok "Application 이름 중복 없음" || { red "$dup_app"; fail "Application 이름 중복 발견"; }

dup_proj=$(
  grep -R --include='*.yaml' -n 'kind: AppProject' "$ROOT/apps/base" 2>/dev/null \
  | cut -d: -f1 \
  | xargs -r -I{} yq -r '.metadata.name' {} \
  | sort | uniq -c | awk '$1>1{print}'
)
[[ -z "$dup_proj" ]] && ok "AppProject 이름 중복 없음" || { red "$dup_proj"; fail "AppProject 이름 중복 발견"; }

# 3) sync-wave 주석 점검
# 기대 규칙: mesh=10, policy=20, dr=80, observability=90, 나머지 앱은 30~60 범위
bad_sync=0
while IFS= read -r f; do
  kind=$(yq -r '.kind' "$f")
  [[ "$kind" != "Application" ]] && continue
  name=$(yq -r '.metadata.name' "$f")
  wave=$(yq -r '.metadata.annotations."argocd.argoproj.io/sync-wave" // "MISSING"' "$f")

  want=""
  case "$name" in
    mesh) want="10" ;;
    policy) want="20" ;;
    dr-tools|dr) want="80" ;;
    observability) want="90" ;;
    *) want="RANGE" ;;
  esac

  if [[ "$wave" == "MISSING" ]]; then
    red "  - $name: sync-wave 주석 없음"
    bad_sync=1
  else
    if [[ "$want" == "RANGE" ]]; then
      # 일반 앱: 30 ~ 60 허용
      if ! [[ "$wave" =~ ^[0-9]+$ ]] || (( wave < 30 || wave > 60 )); then
        red "  - $name: sync-wave=$wave (권장: 30~60)"
        bad_sync=1
      fi
    else
      if [[ "$wave" != "$want" ]]; then
        red "  - $name: sync-wave=$wave (권장: $want)"
        bad_sync=1
      fi
    fi
  fi
done < <(find "$ROOT/apps/base" -maxdepth 1 -type f -name '*.yaml' | sort)

[[ $bad_sync -eq 0 ]] && ok "sync-wave 주석 규칙 OK" || fail "sync-wave 불일치가 있습니다."

# 4) overlays/dev|stg|prod 존재 & 루트 App 사용 여부(혹은 bootstrap 존재)
have_dev=$(test -d "$ROOT/overlays/dev" && echo 1 || echo 0)
have_stg=$(test -d "$ROOT/overlays/stg" && echo 1 || echo 0)
have_prod=$(test -d "$ROOT/overlays/prod" && echo 1 || echo 0)

if (( have_dev + have_stg + have_prod == 0 )); then
  yellow "overlays/dev|stg|prod 없음 → bootstrap만 쓰는 구조로 보임(허용)"
else
  ok "overlays/dev|stg|prod 폴더 존재"
fi

# 5) 과거 argocd-overlay.yaml 잔존 여부
if [[ -f "$ROOT/argocd-overlay.yaml" ]]; then
  fail "루트에 argocd-overlay.yaml 이 남아 있습니다. (bootstrap으로 대체했으면 삭제 권장)"
else
  ok "이전 argocd-overlay.yaml 없음"
fi

# 6) bootstrap/argocd 필수 파일 점검(존재만 확인)
if [[ -d "$ROOT/bootstrap/argocd" ]]; then
  [[ -f "$ROOT/bootstrap/argocd/root-dev.yaml" ]] && ok "bootstrap: root-dev.yaml OK" || yellow "bootstrap: root-dev.yaml 없음(필수 아님)"
  [[ -f "$ROOT/bootstrap/argocd/root-stg.yaml" ]] && ok "bootstrap: root-stg.yaml OK" || yellow "bootstrap: root-stg.yaml 없음(필수 아님)"
  [[ -f "$ROOT/bootstrap/argocd/root-prod.yaml" ]] && ok "bootstrap: root-prod.yaml OK" || yellow "bootstrap: root-prod.yaml 없음(필수 아님)"

  # ksops 구성 체크(있으면 암호화 파일도 점검)
  if [[ -f "$ROOT/bootstrap/argocd/cm-cmp-plugins.yaml" || -f "$ROOT/bootstrap/argocd/patch-repo-server.yaml" ]]; then
    ok "ksops 구성 파일 감지"
    if [[ -f "$ROOT/bootstrap/argocd/secret-age-key.enc.yaml" ]]; then
      if grep -q '^sops:' "$ROOT/bootstrap/argocd/secret-age-key.enc.yaml"; then
        ok "secret-age-key.enc.yaml → sops 암호화 OK"
      else
        fail "secret-age-key.enc.yaml 가 암호화되지 않았습니다(평문 금지)."
      fi
    else
      yellow "ksops 사용 감지 → secret-age-key.enc.yaml 이 보이지 않습니다."
    fi
  fi
fi

# 7) secrets/sops.yaml 규칙 분리 여부(간단 검증)
if [[ -f "$ROOT/secrets/sops.yaml" ]]; then
  # 두 가지 규칙(앱: AGE / bootstrap AGE key: PGP/KMS) 존재 여부 힌트 검사
  if grep -q 'bootstrap/argocd/secret-age-key\.enc\.yaml' "$ROOT/secrets/sops.yaml"; then
    ok "sops 규칙에 bootstrap AGE key 전용 항목 존재"
  else
    yellow "sops 규칙에 bootstrap AGE key 전용 항목이 보이지 않습니다(권장)."
  fi

  if grep -q 'secrets/(dev|stg|prod)/' "$ROOT/secrets/sops.yaml"; then
    ok "sops 규칙에 환경별 앱 시크릿 항목 존재"
  else
    yellow "sops 규칙에 환경별 앱 시크릿 항목이 보이지 않습니다(권장)."
  fi
else
  yellow "secrets/sops.yaml 이 없습니다."
fi

# 8) 이미지 latest 금지 / 차트 버전 핀(간단 스캔)
if grep -R --include='*.yaml' -nE 'image:.*:latest\b' "$ROOT" >/dev/null 2>&1; then
  fail "이미지 태그에 :latest 사용이 감지되었습니다."
else
  ok "이미지 latest 태그 없음"
fi

# (선택) helm chart 버전 고정 여부는 저장 방식에 따라 달라 간단 스캔만:
if grep -R --include='*.yaml' -nE 'chart:|version:' "$ROOT/apps/base" >/dev/null 2>&1; then
  ok "차트/버전 필드 존재(수동 확인 권장)"
else
  yellow "Application 내 차트/버전 고정 정보가 보이지 않습니다(Helm 소스 구조에 따라 정상일 수 있음)."
fi

ok "구조 점검 완료 🎯"
