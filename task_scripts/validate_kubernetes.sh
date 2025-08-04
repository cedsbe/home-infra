#!/bin/bash
# Validate Kubernetes manifests with kubeconform
set -e

if ! command -v kubeconform >/dev/null 2>&1; then
    echo "kubeconform not installed - skipping validation"
    exit 0
fi

if ! command -v kustomize >/dev/null 2>&1; then
    echo "kustomize not installed - skipping validation"
    exit 0
fi

echo "Validating Kubernetes manifests..."

validation_failed=0
while read -r kustomization; do
    dir=$(dirname "$kustomization")
    echo "Validating $dir"
    if ! kustomize build "$dir" | kubeconform -ignore-missing-schemas -summary; then
        echo "❌ Validation failed for $dir"
        validation_failed=1
    fi
done < <(find k8s -name "kustomization.yaml" -o -name "kustomization.yml")

if [ "$validation_failed" -eq 1 ]; then
    echo "Some Kubernetes manifests failed validation."
    exit 1
fi
echo "✓ Kubernetes manifest validation completed"
