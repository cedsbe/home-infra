# Troubleshooting Tips

## ArgoCD

To restart ArgoCD:

```bash
kubectl rollout restart statefulset -n argocd argocd-application-controller
```

## Gateway

When the HTTPRoutes and gateways failed to answer I restarted the cilium-envoy daemonset.

```bash
kubectl -n kube-system rollout restart daemonset/cilium-envoy
```

Note: the daemonset allows at most two pods to restart per rollout. It could be needed to delete the pods in the set.
