#!/bin/bash

# Windows Server 2025 Packer Template Builder
# This script demonstrates how to build templates using the Task commands

set -e

echo "🚀 Windows Server 2025 Packer Template Builder"
echo "==============================================="
echo ""

# Check if Task is installed
if ! command -v task &> /dev/null; then
    echo "❌ Task is not installed. Please install Task first:"
    echo "   https://taskfile.dev/installation/"
    echo ""
    echo "   # macOS"
    echo "   brew install go-task/tap/go-task"
    echo ""
    echo "   # Linux"
    echo "   curl -sL https://taskfile.dev/install.sh | sh"
    exit 1
fi

# Function to show available commands
show_commands() {
    echo "📋 Available commands:"
    echo "  1. Setup environment and check prerequisites"
    echo "  2. Validate Packer configuration"
    echo "  3. Build Datacenter Desktop template (recommended)"
    echo "  4. Build Datacenter Core template"
    echo "  5. Build Standard Desktop template"
    echo "  6. Build Standard Core template"
    echo "  7. Build ALL templates (takes several hours)"
    echo "  8. Debug build with breakpoints"
    echo "  9. Clean up cache and logs"
    echo "  0. Exit"
    echo ""
}

# Main menu
while true; do
    show_commands
    read -p "Choose an option (0-9): " choice
    echo ""

    case $choice in
        1)
            echo "🔍 Checking environment setup..."
            task packer:setup
            ;;
        2)
            echo "✅ Validating Packer configuration..."
            task packer:validate
            ;;
        3)
            echo "🏗️  Building Datacenter Desktop template..."
            task packer:build-dcdesktop
            ;;
        4)
            echo "🏗️  Building Datacenter Core template..."
            task packer:build-dccore
            ;;
        5)
            echo "🏗️  Building Standard Desktop template..."
            task packer:build-stddesktop
            ;;
        6)
            echo "🏗️  Building Standard Core template..."
            task packer:build-stdcore
            ;;
        7)
            echo "⚠️  This will build ALL templates and take several hours!"
            read -p "Are you sure? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                task packer:build-all
            else
                echo "❌ Build cancelled"
            fi
            ;;
        8)
            echo "🐛 Building with debug breakpoints..."
            task packer:debug
            ;;
        9)
            echo "🧹 Cleaning up..."
            task packer:clean
            ;;
        0)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please choose 0-9."
            ;;
    esac

    echo ""
    echo "Press Enter to continue..."
    read
    echo ""
done
