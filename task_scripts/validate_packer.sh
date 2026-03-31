#!/bin/bash
# Validate Packer templates
set -e

if ! command -v packer >/dev/null 2>&1; then
    echo "packer not installed - skipping validation"
    exit 0
fi

echo "Packer version: $(packer version)"

echo "Validating Packer templates..."

validation_failed=0
repo_root="$(pwd)"

# Validate Windows Server 2025 Packer templates

cd "$repo_root/packer/windows_server_2025" || {
    echo "❌ Failed to change directory to packer/windows_server_2025"
    exit 1
}

echo "Initializing Packer..."
if ! packer init .; then
    echo "❌ Packer initialization failed"
    exit 1
fi

echo "Validating Windows Server 2025 templates..."

if ! (packer validate -var ws2025_clone_vm_id=12345 -var proxmox_api_token=validateOnly -var proxmox_username=validateOnly -var winrm_password=validateOnly .); then
    echo "❌ Validation failed for Windows Server 2025 templates"
    validation_failed=1
fi

# Validate Windows 11 Packer templates

cd "$repo_root/packer/windows_11" || {
    echo "❌ Failed to change directory to packer/windows_11"
    exit 1
}

echo "Initializing Packer..."
if ! packer init .; then
    echo "❌ Packer initialization failed"
    exit 1
fi

echo "Validating Windows 11 templates..."

if ! (packer validate -var win11_clone_vm_id=12345 -var proxmox_api_token=validateOnly -var proxmox_username=validateOnly -var winrm_password=validateOnly .); then
    echo "❌ Validation failed for Windows 11 templates"
    validation_failed=1
fi

if [ "$validation_failed" -eq 1 ]; then
    echo "Some Packer templates failed validation."
    exit 1
fi

echo "✅ All Packer templates validated successfully"
