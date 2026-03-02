#!/usr/bin/env bash
# Post-edit validation hook for Claude Code
# Runs after Edit/Write tool use to provide quick feedback on file quality.
# Always exits 0 — warnings only, never blocks Claude.
set -eu -o pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')
[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  *.tf | *.tfvars)
    DIR=$(dirname "$FILE_PATH")
    terraform fmt -check "$DIR" 2>/dev/null \
      || echo "⚠ terraform fmt check flagged $FILE_PATH — run 'terraform fmt $DIR'"
    ;;
  *.pkr.hcl | *.pkrvars.hcl)
    echo "ℹ Packer file edited — run 'task packer:validate' to validate"
    ;;
  k8s/**/*.yaml | k8s/**/*.yml)
    kubeconform -ignore-missing-schemas -summary "$FILE_PATH" 2>/dev/null || true
    ;;
  *.yaml | *.yml)
    if [ -f ".yamllint.yml" ]; then
      yamllint -c .yamllint.yml "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

exit 0
