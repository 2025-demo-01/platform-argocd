# 기본 
*                                   @2025-demo-01/devops-core

# Platform(mesh/policy/observability 등) 후이즈 대장!
/apps/base/app-mesh.yaml            @2025-demo-01/platform-owners
/apps/base/app-policy.yaml          @2025-demo-01/platform-owners
/apps/base/app-observability.yaml   @2025-demo-01/platform-owners
/apps/base/app-dr.yaml              @2025-demo-01/platform-owners

# Biz(tradng/domain) 후이즈 대장!
/apps/base/app-gateway.yaml         @2025-demo-01/trading-owners
/apps/base/app-trading-api.yaml     @2025-demo-01/trading-owners
/apps/base/app-wallet.yaml          @2025-demo-01/trading-owners
/apps/base/app-matching.yaml        @2025-demo-01/trading-owners
/apps/base/app-risk.yaml            @2025-demo-01/trading-owners
/apps/base/app-data-pipeline.yaml   @2025-demo-01/trading-owners

# env/release 이건 가위바위보로 정하자....
/overlays/**                        @2025-demo-01/release-managers

# 부트스트랩(ArgoCD 나야나~)
/bootstrap/argocd/**                @2025-demo-01/daeun-ops
