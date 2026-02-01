# Kubernetes Manifests

This directory contains all Kubernetes manifests managed via GitOps with ArgoCD.

## Directory Structure

```
k8s/
├── sets/           # Top-level ArgoCD Applications (App of Apps pattern)
├── infra/          # Infrastructure components (CNI, ingress, monitoring, etc.)
└── apps/           # User applications
    ├── dev/        # Development/test applications
    ├── media/      # Media stack (arr suite)
    └── utils/      # Utility applications
```

### How It Works

The deployment follows the **App of Apps** pattern:

1. **`sets/`** - Contains root ArgoCD Applications that watch `infra/` and `apps/`
2. **`infra/` & `apps/`** - Each contains an `ApplicationSet` that auto-generates ArgoCD Applications for subdirectories
3. **Subdirectories** - Individual components with their own `kustomization.yaml`

## Helm vs Plain Manifests

This repository uses a **hybrid approach** combining Helm charts and plain Kubernetes manifests through Kustomize.

### When Helm is Used

Helm charts are used for **complex, upstream components** where maintaining custom manifests would be impractical:

- **CNI**: Cilium
- **Controllers**: ArgoCD, cert-manager, sealed-secrets
- **Storage**: Proxmox CSI plugin
- **Databases**: CloudNativePG operator

Helm charts are integrated via Kustomize's `helmCharts` feature:

```yaml
# Example: infra/controllers/argocd/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ns.yaml
  - http-route.yaml
  # ... other custom resources

helmCharts:
  - name: argo-cd
    repo: https://argoproj.github.io/argo-helm
    version: 9.3.7
    releaseName: argocd
    namespace: argocd
    valuesFile: values.yaml
```

### When Plain Manifests are Used

Plain manifests are used for **custom applications** where we have full control:

- Application deployments (whoami, pocket-id, arr suite, etc.)
- Gateway API routes
- ConfigMaps and Secrets
- PersistentVolumeClaims

## Security Standards

All deployments **must** follow these security best practices:

### 1. Run as Non-Root User

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: <uid> # Use a non-zero UID
    runAsGroup: <gid>
    fsGroup: <gid>
    fsGroupChangePolicy: OnRootMismatch
    seccompProfile:
      type: RuntimeDefault
```

### 2. Container-Level Security Context

```yaml
containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
```

### 3. Prefer Rootless/Distroless Images

Choose images in this order of preference:

1. **Distroless images** (e.g., `gcr.io/distroless/*`, `*-distroless` variants)
2. **Rootless images** from trusted sources (e.g., `ghcr.io/home-operations/*`)
3. **Minimal base images** (Alpine-based)

### 4. Resource Limits

Always specify resource requests and limits:

```yaml
resources:
  requests:
    cpu: 50m
    memory: 128Mi
  limits:
    cpu: 1000m
    memory: 256Mi
```

### 5. Image Pinning

Pin images using SHA256 digests for reproducibility:

```yaml
image: ghcr.io/app/name:v1.0.0@sha256:abc123...
```

Renovate will automatically update both the tag and digest.

## Adding a New Application

### 1. Create the Directory Structure

```
k8s/apps/<category>/<app-name>/
├── kustomization.yaml
├── ns.yaml              # Namespace definition
├── deployment.yaml      # Main workload
├── svc.yaml             # Service
├── http-route.yaml      # Optional: Gateway API route
└── pvc.yaml             # Optional: Persistent storage
```

### 2. Create the Kustomization

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ns.yaml
  - deployment.yaml
  - svc.yaml
```

### 3. Define the Namespace

```yaml
# ns.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: <app-name>
```

### 4. Create a Secure Deployment

Use the deployment template below as a starting point:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <app-name>
  namespace: <app-name>
  labels:
    app: <app-name>
spec:
  replicas: 1
  selector:
    matchLabels:
      app: <app-name>
  template:
    metadata:
      labels:
        app: <app-name>
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: <uid>
        runAsGroup: <gid>
        fsGroup: <gid>
        fsGroupChangePolicy: OnRootMismatch
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: <app-name>
          image: <image>:<tag>@sha256:<digest>
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          ports:
            - name: http
              containerPort: <port>
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 500m
              memory: 128Mi
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir: {}
```

### 5. Register with ArgoCD

New applications in existing categories (`dev/`, `media/`, `utils/`) are **auto-discovered** by the `ApplicationSet`.

For a new category, add it to `apps/kustomization.yaml` and create the corresponding `ApplicationSet`.

## Useful Commands

```bash
# Validate manifests locally
kubectl kustomize k8s/apps/dev/whoami

# Validate with Helm charts
kubectl kustomize --enable-helm k8s/infra/controllers/argocd

# Apply manually (for bootstrap or testing)
kubectl apply -k k8s/apps/dev/whoami

# Check ArgoCD sync status
argocd app list
argocd app get <app-name>
```

## References

- [Kustomize Documentation](https://kustomize.io/)
- [ArgoCD ApplicationSet](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Gateway API](https://gateway-api.sigs.k8s.io/)
