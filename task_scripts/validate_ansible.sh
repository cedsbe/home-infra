#!/usr/bin/env bash
# Script to validate Ansible configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$SCRIPT_DIR/../ansible"

echo "Validating Ansible configuration..."

# Check if Ansible is installed
if ! command -v ansible &>/dev/null; then
  echo "❌ Ansible is not installed"
  exit 1
fi

echo "✓ Ansible is installed: $(ansible --version | head -n1)"

# Check ansible.cfg
if [ ! -f "$ANSIBLE_DIR/ansible.cfg" ]; then
  echo "❌ ansible.cfg not found"
  exit 1
fi
echo "✓ ansible.cfg exists"

# Check requirements.yml
if [ ! -f "$ANSIBLE_DIR/requirements.yml" ]; then
  echo "❌ requirements.yml not found"
  exit 1
fi
echo "✓ requirements.yml exists"

# Check if inventory template exists
if [ ! -f "$ANSIBLE_DIR/inventory/hosts.yml.template" ]; then
  echo "❌ inventory/hosts.yml.template not found"
  exit 1
fi
echo "✓ inventory/hosts.yml.template exists"

# Check if inventory file exists
if [ ! -f "$ANSIBLE_DIR/inventory/hosts.yml" ]; then
  echo "⚠ inventory/hosts.yml not found (copy from template and customize)"
else
  echo "✓ inventory/hosts.yml exists"

  # Validate inventory syntax
  if ansible-inventory --list -i "$ANSIBLE_DIR/inventory/hosts.yml" >/dev/null 2>&1; then
    echo "✓ Inventory syntax is valid"
  else
    echo "❌ Inventory syntax is invalid"
    exit 1
  fi
fi

# Check if site.yml exists
if [ ! -f "$ANSIBLE_DIR/site.yml" ]; then
  echo "❌ site.yml not found"
  exit 1
fi
echo "✓ site.yml exists"

# Validate site.yml syntax if inventory exists
if [ -f "$ANSIBLE_DIR/inventory/hosts.yml" ]; then
  if ansible-playbook "$ANSIBLE_DIR/site.yml" --syntax-check >/dev/null 2>&1; then
    echo "✓ site.yml syntax is valid"
  else
    echo "❌ site.yml syntax is invalid"
    exit 1
  fi
fi

# Check roles structure
if [ -d "$ANSIBLE_DIR/roles/common/base-linux" ]; then
  echo "✓ base-linux role exists"
else
  echo "⚠ base-linux role not found"
fi

if [ -d "$ANSIBLE_DIR/roles/common/base-windows" ]; then
  echo "✓ base-windows role exists"
else
  echo "⚠ base-windows role not found"
fi

echo ""
echo "✅ Ansible validation completed successfully"
