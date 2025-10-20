# platform-argocd

이 레포는 **모든 서비스(App-of-Apps)**를 제어하는 GitOps 진입점입니다.  
EKS 환경에서 거래소 전반의 인프라, 서비스, 보안, 데이터, 모니터링을 자동으로 배포·동기화합니다.

---

## 구성 

| 구성요소 | 설명 |
|-----------|------|
| **root-app.yaml** | ArgoCD 최상위 진입점. 하위 모든 Application(App-of-Apps)을 관리합니다. |
| **apps/** | 서비스별 Argo Application 정의 (observability, policy, data, svc-* 등). |
| **overlays/** | 환경별(dev, stg, prod) 설정 차이 관리. |
| **secrets-sops.yaml** | 공용 레지스트리 인증, Cosign 키, SOPS 키 관리. |
| **CODEOWNERS** | 팀별 관리 책임자 지정. 변경은 승인 절차를 따릅니다. |

---

## 방식

1. ArgoCD가 `root-app.yaml`을 기준으로 모든 하위 앱을 동기화합니다.  
2. 각 앱은 **`targetRevision`(tag)** 으로 고정되어 있어, 재현성과 롤백이 보장됩니다.  
3. 환경별(`overlays/dev|stg|prod`) 배포는 Git Merge(Pull Request)로 승급합니다.  
4. 배포 정책은 **자동 복구(selfHeal)** + **자동 정리(prune)** 로 운영됩니다.

---

##  보안 / 정책 연계

- `policy-as-code` 레포의 Kyverno, Gatekeeper 정책을 자동 적용합니다.  
- `secrets-sops.yaml`은 모든 민감정보를 **SOPS 암호화** 후 주입합니다.  
- Cosign 공개키를 `global-secrets` 네임스페이스에서 참조하여 이미지 서명 검증을 수행합니다.

---

## 주요 링크

| 구분 | Repository | Tag / Branch |
|------|-------------|---------------|
| Observability | [observability-stack](https://github.com/2025-demo-01/observability-stack) | v0.9.0 |
| Policy-as-Code | [policy-as-code](https://github.com/2025-demo-01/policy-as-code) | v1.2.0 |
| Data Pipeline | [data-pipeline](https://github.com/2025-demo-01/data-pipeline) | v0.4.2 |
| Trading API | [svc-trading-api](https://github.com/2025-demo-01/svc-trading-api) | v1.5.0 |
| Matching Engine | [svc-matching-engine](https://github.com/2025-demo-01/svc-matching-engine) | v0.8.3 |
| Wallet Service | [svc-wallet](https://github.com/2025-demo-01/svc-wallet) | v0.7.1 |
| Risk Control | [svc-risk-control](https://github.com/2025-demo-01/svc-risk-control) | v0.3.0 |
| DR / SRE Test | [tests-and-dr](https://github.com/2025-demo-01/tests-and-dr) | v0.2.0 |

---

##  운영 표준

- 모든 배포는 **GitOps 원칙**에 따라 수행됩니다.  
- ArgoCD Sync 정책:  
  - `automated.prune: true`  
  - `automated.selfHeal: true`  
  - `CreateNamespace=true`  
- PR 승인 시 **ArgoCD가 자동 반영**합니다.  
- Rollback 시 `targetRevision` 이전 태그로 변경 후 Sync.

---

##  주의 사항

- 모든 비밀정보는 `sops`로 암호화되어 있어야 합니다.  
- 테스트 환경에서 암호는 `sophielog` 로 통일됩니다.  
- `main` 브랜치는 보호되어 있으며, 직접 푸시는 금지됩니다.  
- 신규 서비스 추가 시 `apps/` 디렉터리에 Argo Application 정의를 추가한 후 PR을 생성합니다.
