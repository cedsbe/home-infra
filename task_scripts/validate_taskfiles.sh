#!/bin/bash
# Validate all Taskfiles in the project
set -e

if ! command -v task >/dev/null 2>&1; then
    echo "task not installed - skipping validation"
    exit 0
fi

echo "Validating Taskfiles..."

# Validate main Taskfile
echo "Validating main Taskfile..."
if task --list >/dev/null 2>&1; then
    echo "✓ Main Taskfile is valid"
else
    echo "✗ Main Taskfile validation failed"
    exit 1
fi

# Validate packer Taskfile
echo "Validating packer Taskfile..."
if (cd packer/windows_server_2025 && task --list >/dev/null 2>&1); then
    echo "✓ Packer Taskfile is valid"
else
    echo "✗ Packer Taskfile validation failed"
    exit 1
fi

# Validate azure Taskfile
echo "Validating azure Taskfile..."
if (cd terraform/azure && task --list >/dev/null 2>&1); then
    echo "✓ Azure Taskfile is valid"
else
    echo "✗ Azure Taskfile validation failed"
    exit 1
fi

echo "✓ All Taskfiles are valid"
