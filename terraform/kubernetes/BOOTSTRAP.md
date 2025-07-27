helm template \
cilium \
cilium/cilium \
--version=v1.16.5 \
--namespace kube-system \
--set kubeProxyReplacement=true \
--values k8s/infra/network/cilium/values_bootstrap.yaml > terraform/kubernetes/modules/talos/talos_inline_manifests/sensitive_cilium_helm_template.yaml
