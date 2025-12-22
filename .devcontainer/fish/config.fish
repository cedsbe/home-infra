# Fish shell configuration for devcontainer

# Set greeting
set -g fish_greeting

# Add local bin to PATH
fish_add_path ~/.local/bin

# Shell completions are generated at container build time
# See Dockerfile for completion setup
