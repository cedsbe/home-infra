Run a read-only health check of the Kubernetes cluster and summarize results.

## Steps

Run each command in sequence and collect output:

1. **Node status**:
   ```bash
   kubectl get nodes -o wide
   ```

2. **Talos cluster health**:
   ```bash
   talosctl health
   ```

3. **ArgoCD application list**:
   ```bash
   argocd app list
   ```

4. **Non-Running pods** (potential issues):
   ```bash
   kubectl get pods --all-namespaces --field-selector='status.phase!=Running,status.phase!=Succeeded' -o wide
   ```

## Output Format

Present a structured report:

### Nodes
| Node | Status | Roles | Age | Version | Internal-IP |
|------|--------|-------|-----|---------|-------------|
(table from kubectl output)

### Talos Health
- Summary: healthy / degraded / unhealthy
- Any service failures noted

### ArgoCD Applications
| App | Sync Status | Health | Repo |
|-----|-------------|--------|------|
(table from argocd output, highlighting any OutOfSync or Degraded apps)

### Problem Pods
(List any pods not in Running/Succeeded state with namespace, name, status, reason)

### Summary
- Cluster status: ✅ Healthy / ⚠ Degraded / ❌ Unhealthy
- Node count: N/N ready
- ArgoCD: N apps synced, N out of sync
- Problem pods: N (or "none")

## Notes

- All commands are read-only — no changes are made.
- Talos nodes have no SSH; `talosctl` uses the `TALOSCONFIG` environment variable (auto-set in devcontainer).
- `kubectl` uses `KUBECONFIG` (auto-set in devcontainer).
- If `talosctl health` fails with a connection error, the user may need to check VPN or network connectivity to `192.168.65.110-112`.
