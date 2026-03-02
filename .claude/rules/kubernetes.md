---
paths:
  - "k8s/**/*.yaml"
  - "k8s/**/*.yml"
---

# Kubernetes Manifest Context

## GitOps Model — No Direct kubectl apply

This cluster uses ArgoCD for all application deployments. **Never suggest `kubectl apply` for app manifests.** The correct workflow is:

1. Edit manifests in `k8s/`
2. Commit and push to `main`
3. ArgoCD detects the change and syncs automatically

Use `kubectl apply` only for one-off debugging or for resources explicitly outside ArgoCD management.

## Directory Structure

```
k8s/
├── infra/          # Infrastructure components (networking, storage, controllers)
│   ├── cilium/     # CNI network plugin
│   ├── argocd/     # ArgoCD itself (bootstrapped separately)
│   └── ...
├── apps/           # Application deployments
└── sets/           # ArgoCD ApplicationSets for bulk management
```

## Kustomize + helmCharts Pattern

Manifests use Kustomize for templating. ArgoCD ApplicationSets use the `helmCharts` source type. When adding a new app:

- Add a `kustomization.yaml` referencing the app's resources
- For Helm-based apps, configure via ArgoCD Application or ApplicationSet in `sets/`

## Sealed Secrets Workflow

Sensitive values use Sealed Secrets. The workflow for updating a secret:

1. Edit the plaintext secret in `sensitive/` (gitignored)
2. Re-seal: `task k8s:seal:secret FILE=sensitive/my-secret.yaml`
3. Copy the sealed output to the appropriate path in `k8s/`
4. Commit the sealed secret file

**Never read or expose files in `sensitive/`.**

## Namespace Conventions

| Namespace | Purpose |
|-----------|---------|
| `kube-system` | Core Kubernetes + CNI (Cilium) |
| `argocd` | GitOps controller |
| `monitoring` | Prometheus, Grafana, alerting |
| `cert-manager` | TLS certificate management |

## Image Tag Requirements

- **Always pin image tags** — never use `latest` or `stable`
- Use digest pinning (`image@sha256:...`) for critical infrastructure components
- Renovate bot manages tag updates via PRs

## Cluster Network

- **Cluster CIDR**: `192.168.65.0/24`
- **Control Plane**: `192.168.65.110-112`
- **Workers**: `192.168.65.120-122`
- **Gateway**: `192.168.65.1`
- **DNS**: `192.168.65.30`, `192.168.65.40`
- **Internal Domain**: `ad.ghiot.be`, `ghiot.be`

## Talos — No SSH

Talos Linux nodes have no SSH access. All node management is via `talosctl`. Never suggest SSH-based node access.
