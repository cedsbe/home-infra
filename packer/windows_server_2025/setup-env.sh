#!/bin/bash

# Packer Environment Setup Script
# This script helps set up the environment for Windows Server 2025 Packer builds

set -e

echo "🚀 Packer Windows Server 2025 Environment Setup"
echo "================================================"
echo ""

# Check if we're in the right directory
if [ ! -f "Taskfile.yml" ] || [ ! -f ".env.template" ]; then
    echo "❌ Please run this script from the packer/windows_server_2025 directory"
    echo "   cd packer/windows_server_2025"
    echo "   ./setup-env.sh"
    exit 1
fi

# Check if .env already exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists"
    read -p "   Do you want to recreate it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "✅ Keeping existing .env file"
    else
        echo "🔄 Recreating .env file..."
        cp .env.template .env
        echo "✅ .env file created from template"
    fi
else
    echo "📋 Creating .env file from template..."
    cp .env.template .env
    echo "✅ .env file created"
fi

echo ""
echo "🔧 Next steps:"
echo "  1. Edit the .env file with your actual credentials:"
echo "     nano .env"
echo "     # or use your preferred editor"
echo ""
echo "  2. Set your Proxmox API token:"
echo "     - Go to Proxmox VE web interface"
echo "     - Navigate to Datacenter > Permissions > API Tokens"
echo "     - Create a new token for terraform user"
echo "     - Copy the token to PKR_VAR_proxmox_api_token in .env"
echo ""
echo "  3. Set a secure WinRM password:"
echo "     - Update PKR_VAR_winrm_password in .env"
echo "     - Use a strong password (this is temporary for build process)"
echo ""
echo "  4. Validate your setup:"
echo "     task env-check"
echo ""
echo "  5. Start building:"
echo "     task build"
echo ""
echo "🔒 Security reminders:"
echo "  - Never commit .env to version control"
echo "  - Use strong, unique passwords"
echo "  - Rotate API tokens regularly"
echo "  - The .env file is already in .gitignore"
echo ""
echo "For help: task help"
