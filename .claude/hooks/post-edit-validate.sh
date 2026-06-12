#!/usr/bin/env bash
# Post-edit validation hook for Claude Code
# Runs after Edit/Write tool use to provide quick feedback on file quality.
# Always exits 0 — warnings only, never blocks Claude.
set -eu -o pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null) || exit 0
[ -z "$FILE_PATH" ] && exit 0

if [[ "$FILE_PATH" == *.tf || "$FILE_PATH" == *.tfvars ]]; then
  DIR=$(dirname "$FILE_PATH")
  terraform fmt -check "$DIR" 2>/dev/null \
    || echo "⚠ terraform fmt check flagged $FILE_PATH — run 'terraform fmt $DIR'"

elif [[ "$FILE_PATH" == *.pkr.hcl || "$FILE_PATH" == *.pkrvars.hcl ]]; then
  echo "ℹ Packer file edited — run 'task packer:validate' to validate"

elif [[ "$FILE_PATH" =~ ^k8s/.*\.(yaml|yml)$ ]]; then
  kubeconform -ignore-missing-schemas -summary "$FILE_PATH" 2>/dev/null || true
elif [[ "$FILE_PATH" == *.yaml || "$FILE_PATH" == *.yml ]]; then
  if [ -f ".yamllint.yml" ]; then
    yamllint -c .yamllint.yml "$FILE_PATH" 2>/dev/null || true
  fi
fi

exit 0
