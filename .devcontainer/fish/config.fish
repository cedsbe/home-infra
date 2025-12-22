# Fish shell configuration for devcontainer

# Enable VI mode (optional, comment out if you prefer emacs mode)
# fish_vi_key_bindings

# Set greeting
set -g fish_greeting

# Add local bin to PATH
fish_add_path ~/.local/bin

# kubectl completion
kubectl completion fish | source

# terraform completion - only attempt if terraform command exists
if command -v terraform > /dev/null
  terraform -install-autocomplete
end

# task completion
task --completion fish | source
