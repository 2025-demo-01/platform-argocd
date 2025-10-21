# platform-argocd — Control Tower (App-of-Apps)

Argo CD 기반 **Control Tower** Repository 입니다.

모든 Application/Project 정의는 `apps/base/`에 모여 있고, env root는 `bootstrap/argocd/root-*.yaml`로 bootstrap 합니다.

## Bootstrap 

```bash
# (선택) ksops 사용 시
kubectl apply -n argocd -f bootstrap/argocd/cm-cmp-plugins.yaml
kubectl apply -n argocd -f bootstrap/argocd/patch-repo-server.yaml
kubectl apply -n argocd -f bootstrap/argocd/secret-age-key.enc.yaml   # ← sops 암호화본

# Root App 적용 (eg. dev 환경)
kubectl apply -n argocd -f bootstrap/argocd/root-dev.yaml
# stg/prod도 동일
```



---
##  배포 순서-sync-wave 규칙

Argo CD는 여러 Application을 순서대로 배포하기 위해

`argocd.argoproj.io/sync-wave` 주석(annotation)을 사용합니다.

숫자가 낮을수록 먼저 배포되며, 같은 숫자는 병렬로 배포됩니다.

| 순서 | 대상 | 설명 |
| --- | --- | --- |
| **10** | mesh | Istio / Envoy 등 네트워크 계층 |
| **20** | policy | Kyverno / OPA 등 정책 계층 |
| **30–60** | services | trading-api, wallet 등 주요 업무 서비스 |
| **80** | dr | 장애 복구 / Chaos / Failover 구성 |
| **90** | observability | Prometheus / Loki / Tempo / Grafana 등 모니터링 스택 |


