# platform-argocd (Control Tower)

platform-argocd는 Argo CD를 기반으로 한 **Control Tower** 역할을 합니다.

모든 Application 및 Project 정의가 `apps/base/` 아래에 있고,

환경 별 root(App-of-Apps) 배포는 `bootstrap/argocd/root-*.yaml`로 처리됩니다.

즉, 인프라가 준비된 후 이 Repo 하나로 **dev/stg/prod** 환경의 

전체 Application을 관리하는걸 목표로 합니다. 

---

## 배포 흐름

1. **Bootstrap 단계에서**  Argocd namespace에 초기 설정(ConfigMaps, Plugins, Secret 등) 
2. **Root App 배포**: 환경(env)별(root-dev.yaml 등) Application 정의 적용
3. **Project 정의**: 각 Team/Service별 Project 설정(ex. `trading.yaml`)
4. **Application 배포**: `apps/base/app-*.yaml`에서 각 Service repo를 지정
5. **자동화 & 유지보수**: `prune=true`, `selfHeal=true`으로 Git 선언 상태와 Cluster 상태 자동 일치
    
    ### Quick Start
    
    1. `bootstrap/argocd/root-dev.yaml` 적용 → Argocd UI에 dev 환경 App 자동 등록
    2. `apps/base/app-*.yaml`에 새로운 서비스 추가 → Git push → 자동 생성/업데이트
    3. `projects/*.yaml`에 팀/서비스 정의 추가 → 권한/ResourceQuota 등 설정
    4. `.github/workflows/validate.yaml`을 통해 **YAML 스키마 + 정책** 자동화 검증

---

## 주요 기능

- **GitOps**: 선언형 Infrastructure + Application 모두 Git에서 관리
- **Argo CD Application**: Application 리소스를 통해 서비스 배포
- **Self-Healing**: 클러스터 상태가 Git 상태와 다르면 자동 복구
- **sync-wave**: 배포 순서를 눈으로 바로 인지 가능하게 구성
- **Multi-env Strategy**: dev → stg → prod 순서 체계
- **Modular Structure**: services, infrastructure, policies가 모듈화되어 유지보수 용이

---

## Why this matters

platform-argocd는 단순한 Helm/Manifest Repo가 아니라, 조작 가능한 전체 CLuster의 운영 Control Tower입니다.

- 모든 서비스는 이 중앙 Repo를 통해 **일관된 방식으로 배포**됩니다.
- **정책/보안/DR/관찰성**이 일관된 순서로 적용돼, 복잡한 환경에서도 **예측 가능하고 반복 가능한 배포 모델**을 실현을 목표로 했습니다.
- 팀이 커지고 서비스가 많아져도, 이 구조 하나만 이해하면 **누구든지 서비스 추가/제거/롤백**을 쉽게 할 수 있게 설계됐습니다.

---

## Next Steps

- Service Repo`svc-gateway`, `svc-trading-api` 등)를 **이 구조에 연결**
- `policy-as-code` 레포와 **정책 검사 연동**
- `tests-and-dr` 레포로 **DR 시나리오** 자동화
