# Manual Bootstrap

## CRDs

Gateway API

```shell
kubectl apply -k infra/crds
```

## Cilium

```shell
kubectl kustomize --enable-helm infra/network/cilium | kubectl apply -f -
```

## Whoami

```shell
kubectl kustomize apps/dev/whoami
```

## Gateway

```shell
kubectl kustomize infra/network/gateway | kubectl apply -f -
```

## Whoami with gateway

```shell
kubectl kustomize apps/dev/whoamigw | kubectl apply -f -
```

## Sealed Secrets

```shell
kubectl kustomize --enable-helm infra/controllers/sealed-secrets | kubectl apply -f -
```

## ArgoCD

### ArgoCD itself

```shell
kubectl kustomize --enable-helm infra/controllers/argocd | kubectl apply -f -
```


Get the initial password.

```shell
argocd admin initial-password -n argocd
```

### The applications

```shell
kubectl apply -k infra

kubectl apply -k sets
```
## Proxmox CSI Plugin

```shell
kustomize build --enable-helm infra/storage/proxmox-csi | kubectl apply -f -
```
